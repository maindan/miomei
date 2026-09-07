// Envia push via APNs (provider token / chave .p8) para os device tokens de
// um usuário (docs/miomei-supabase.md §7). Chamada a partir de outra função,
// de um trigger, ou diretamente pelo app em casos que exigem alerta
// gerado no servidor (ex.: recalculo de atraso em segundo plano).
//
// Secrets necessários (nunca versionados — configure com `supabase secrets set`):
//   APNS_KEY_P8    conteúdo do arquivo .p8 gerado no Apple Developer
//   APNS_KEY_ID    Key ID da chave APNs
//   APNS_TEAM_ID   Team ID da conta Apple Developer
//   APNS_BUNDLE_ID com.projexsystem.miomei (o "topic" do APNs)
//   APNS_ENV       "sandbox" ou "production"
//
// Deploy manual (não executado neste ambiente):
//   supabase secrets set APNS_KEY_P8="$(cat AuthKey_XXXX.p8)" APNS_KEY_ID=... APNS_TEAM_ID=... APNS_BUNDLE_ID=... APNS_ENV=sandbox
//   supabase functions deploy send-push
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { supabaseAdmin } from "../_shared/supabaseAdmin.ts";

interface SendPushBody {
  userId: string;
  title: string;
  body: string;
}

serve(async (req) => {
  const { userId, title, body } = (await req.json()) as SendPushBody;
  if (!userId || !title) {
    return new Response(JSON.stringify({ ok: false, error: "userId e title são obrigatórios" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = supabaseAdmin();
  const { data: tokens, error } = await supabase
    .from("device_token")
    .select("token")
    .eq("user_id", userId);

  if (error) {
    return new Response(JSON.stringify({ ok: false, error }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const authorizationHeader = `bearer ${await makeApnsProviderToken()}`;
  const host = Deno.env.get("APNS_ENV") === "production"
    ? "https://api.push.apple.com"
    : "https://api.sandbox.push.apple.com";
  const topic = Deno.env.get("APNS_BUNDLE_ID")!;

  const results = await Promise.all(
    (tokens ?? []).map(async ({ token }) => {
      const response = await fetch(`${host}/3/device/${token}`, {
        method: "POST",
        headers: {
          "authorization": authorizationHeader,
          "apns-topic": topic,
          "apns-push-type": "alert",
          "content-type": "application/json",
        },
        body: JSON.stringify({ aps: { alert: { title, body }, sound: "default" } }),
      });
      return { token, status: response.status };
    }),
  );

  return new Response(JSON.stringify({ ok: true, results }), {
    headers: { "Content-Type": "application/json" },
  });
});

/// JWT ES256 assinado com a chave .p8 (autenticação por provider token do APNs).
async function makeApnsProviderToken(): Promise<string> {
  const keyId = Deno.env.get("APNS_KEY_ID")!;
  const teamId = Deno.env.get("APNS_TEAM_ID")!;
  const p8 = Deno.env.get("APNS_KEY_P8")!;

  const header = base64url(JSON.stringify({ alg: "ES256", kid: keyId }));
  const payload = base64url(JSON.stringify({ iss: teamId, iat: Math.floor(Date.now() / 1000) }));
  const signingInput = `${header}.${payload}`;

  const key = await importP8PrivateKey(p8);
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(signingInput),
  );

  return `${signingInput}.${base64urlFromBuffer(signature)}`;
}

async function importP8PrivateKey(p8: string): Promise<CryptoKey> {
  const pem = p8
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
}

function base64url(input: string): string {
  return base64urlFromBuffer(new TextEncoder().encode(input));
}

function base64urlFromBuffer(buffer: ArrayBuffer | Uint8Array): string {
  const bytes = buffer instanceof Uint8Array ? buffer : new Uint8Array(buffer);
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

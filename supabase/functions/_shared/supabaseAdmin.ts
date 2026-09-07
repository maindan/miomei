// Cliente Supabase com service_role — só para uso dentro de Edge Functions
// (nunca no app iOS). Ignora RLS, então cada função deve filtrar
// explicitamente pelas condições de negócio corretas.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export function supabaseAdmin() {
  const url = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  return createClient(url, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

// Gera o DAS-MEI pendente do mês corrente para cada perfil com regime MEI
// (docs/miomei-supabase.md §7, mio-escopo.md §4.3, §9). Agende via Database
// > Cron para rodar todo dia 1º. Idempotente: não duplica se já existir um
// payable DAS_MEI para o mês.
//
// Deploy manual (não executado neste ambiente):
//   supabase functions deploy generate-das-mei
//   select cron.schedule('generate-das-mei-monthly', '0 6 1 * *',
//     $$ select net.http_post(
//          url := '<PROJECT_URL>/functions/v1/generate-das-mei',
//          headers := jsonb_build_object('Authorization', 'Bearer <SERVICE_ROLE_OR_ANON_KEY>')
//        ); $$
//   );
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { supabaseAdmin } from "../_shared/supabaseAdmin.ts";

serve(async () => {
  const supabase = supabaseAdmin();
  const now = new Date();
  const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
  const monthEnd = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1));

  const { data: profiles, error: profileError } = await supabase
    .from("profile")
    .select("id, das_due_day")
    .eq("tax_regime", "MEI");

  if (profileError) {
    return new Response(JSON.stringify({ ok: false, error: profileError }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  let created = 0;
  for (const profile of profiles ?? []) {
    const { data: existing, error: existingError } = await supabase
      .from("payable")
      .select("id")
      .eq("user_id", profile.id)
      .eq("type", "DAS_MEI")
      .gte("due_date", monthStart.toISOString().slice(0, 10))
      .lt("due_date", monthEnd.toISOString().slice(0, 10))
      .is("deleted_at", null);

    if (existingError || (existing && existing.length > 0)) continue;

    const dueDay = profile.das_due_day ?? 20;
    const dueDate = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), dueDay));

    const { error: insertError } = await supabase.from("payable").insert({
      user_id: profile.id,
      type: "DAS_MEI",
      description: "DAS-MEI",
      amount: 0,
      due_date: dueDate.toISOString().slice(0, 10),
      status: "PENDING",
    });

    if (!insertError) created += 1;
  }

  return new Response(JSON.stringify({ ok: true, created }), {
    headers: { "Content-Type": "application/json" },
  });
});

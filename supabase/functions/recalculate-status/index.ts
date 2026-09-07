// Recalcula status atrasado/vencido em segundo plano, mesmo com o app
// fechado (docs/miomei-supabase.md §7, mio-escopo.md §9). Agende via
// Database > Cron (pg_cron) chamando esta função uma vez por dia.
//
// Deploy manual (não executado neste ambiente):
//   supabase functions deploy recalculate-status
//   select cron.schedule('recalculate-status-daily', '0 3 * * *',
//     $$ select net.http_post(
//          url := '<PROJECT_URL>/functions/v1/recalculate-status',
//          headers := jsonb_build_object('Authorization', 'Bearer <SERVICE_ROLE_OR_ANON_KEY>')
//        ); $$
//   );
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { supabaseAdmin } from "../_shared/supabaseAdmin.ts";

serve(async () => {
  const supabase = supabaseAdmin();
  const today = new Date().toISOString().slice(0, 10);

  const { data: overdueReceivables, error: receivableError } = await supabase
    .from("receivable")
    .update({ status: "OVERDUE" })
    .eq("status", "EXPECTED")
    .lt("due_date", today)
    .is("deleted_at", null)
    .select("id");

  const { data: overduePayables, error: payableError } = await supabase
    .from("payable")
    .update({ status: "OVERDUE" })
    .eq("status", "PENDING")
    .lt("due_date", today)
    .is("deleted_at", null)
    .select("id");

  if (receivableError || payableError) {
    return new Response(
      JSON.stringify({ ok: false, receivableError, payableError }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  return new Response(
    JSON.stringify({
      ok: true,
      receivablesMarkedOverdue: overdueReceivables?.length ?? 0,
      payablesMarkedOverdue: overduePayables?.length ?? 0,
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});

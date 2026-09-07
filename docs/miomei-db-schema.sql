-- =============================================================================
-- MioMei — Schema do banco (Supabase / PostgreSQL)
-- App iOS nativo, offline-first. Todas as tabelas de usuário usam RLS
-- (user_id = auth.uid()), UUIDs gerados no cliente e colunas de sync
-- (updated_at, deleted_at). Aplique no SQL Editor do Supabase.
-- =============================================================================
 
-- Extensões -------------------------------------------------------------------
create extension if not exists "pgcrypto";      -- gen_random_uuid()
 
-- =============================================================================
-- Função utilitária: manter updated_at atualizado
-- =============================================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
 
-- =============================================================================
-- Enums
-- =============================================================================
do $$ begin
  create type tax_regime      as enum ('MEI','SIMPLES','OTHER');
exception when duplicate_object then null; end $$;
 
do $$ begin
  create type budget_status   as enum ('DRAFT','SENT','APPROVED','REJECTED','EXPIRED');
exception when duplicate_object then null; end $$;
 
do $$ begin
  create type contract_type   as enum ('PJ','FREELANCE');
exception when duplicate_object then null; end $$;
 
do $$ begin
  create type contract_status as enum ('ACTIVE','CLOSED','SUSPENDED');
exception when duplicate_object then null; end $$;
 
do $$ begin
  create type receivable_status as enum ('EXPECTED','RECEIVED','OVERDUE');
exception when duplicate_object then null; end $$;
 
do $$ begin
  create type payable_type    as enum ('DAS_MEI','INVOICE_TAX','OTHER');
exception when duplicate_object then null; end $$;
 
do $$ begin
  create type payable_status  as enum ('PENDING','PAID','OVERDUE');
exception when duplicate_object then null; end $$;
 
do $$ begin
  create type invoice_status  as enum ('TO_ISSUE','ISSUED');
exception when duplicate_object then null; end $$;
 
do $$ begin
  create type demand_priority as enum ('LOW','MEDIUM','HIGH');
exception when duplicate_object then null; end $$;
 
do $$ begin
  create type demand_status   as enum ('TODO','IN_PROGRESS','DONE');
exception when duplicate_object then null; end $$;
 
-- =============================================================================
-- PROFILE  (1:1 com auth.users; id = auth uid)
-- =============================================================================
create table if not exists public.profile (
  id               uuid primary key references auth.users(id) on delete cascade,
  company_name     text,
  trade_name       text,
  cnpj             text,
  email            text,
  tax_regime       tax_regime  not null default 'MEI',
  default_tax_rate numeric(5,2) not null default 0,   -- % (ex.: 6.00)
  das_due_day      int          not null default 20,   -- dia de vencimento do DAS-MEI
  mei_annual_ceiling numeric(14,2),                    -- teto anual (config.)
  pix_key          text,
  bank_info        text,
  avatar_url       text,                               -- inicial = avatar da conta OAuth
  onboarding_done  boolean      not null default false,
  created_at       timestamptz  not null default now(),
  updated_at       timestamptz  not null default now()
);
 
-- Cria automaticamente o profile no primeiro login, herdando avatar/e-mail da conta OAuth
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profile (id, email, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(
      new.raw_user_meta_data->>'avatar_url',
      new.raw_user_meta_data->>'picture'
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
 
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
 
create trigger set_profile_updated_at
  before update on public.profile
  for each row execute function public.set_updated_at();
 
-- =============================================================================
-- CLIENT
-- =============================================================================
create table if not exists public.client (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  name       text not null,
  document   text,
  email      text,
  phone      text,
  notes      text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists idx_client_user on public.client(user_id);
create trigger set_client_updated_at before update on public.client
  for each row execute function public.set_updated_at();
 
-- =============================================================================
-- BUDGET (orçamento)
-- =============================================================================
create table if not exists public.budget (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  client_id     uuid references public.client(id) on delete set null,
  title         text not null,
  items         jsonb not null default '[]'::jsonb,   -- [{description, qty, unit_price}]
  total_value   numeric(14,2) not null default 0,
  valid_until   date,
  payment_terms text,
  status        budget_status not null default 'DRAFT',
  pdf_url       text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);
create index if not exists idx_budget_user   on public.budget(user_id);
create index if not exists idx_budget_client on public.budget(client_id);
create trigger set_budget_updated_at before update on public.budget
  for each row execute function public.set_updated_at();
 
-- =============================================================================
-- CONTRACT
-- =============================================================================
create table if not exists public.contract (
  id                       uuid primary key default gen_random_uuid(),
  user_id                  uuid not null references auth.users(id) on delete cascade,
  client_id                uuid references public.client(id) on delete set null,
  type                     contract_type not null,
  title                    text not null,
  description              text,
  start_date               date,
  end_date                 date,
  estimated_value          numeric(14,2),
  weekly_hours_requirement numeric(5,2),              -- horas/semana exigidas (opcional)
  recurrence               text,                      -- ex.: 'MONTHLY', 'PER_DELIVERY'
  status                   contract_status not null default 'ACTIVE',
  payment_method           text,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now(),
  deleted_at               timestamptz
);
create index if not exists idx_contract_user   on public.contract(user_id);
create index if not exists idx_contract_client on public.contract(client_id);
create trigger set_contract_updated_at before update on public.contract
  for each row execute function public.set_updated_at();
 
-- =============================================================================
-- CONTRACT_RENEWAL (histórico de renovações)
-- =============================================================================
create table if not exists public.contract_renewal (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  contract_id  uuid not null references public.contract(id) on delete cascade,
  new_end_date date not null,
  added_value  numeric(14,2),
  note         text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz
);
create index if not exists idx_renewal_contract on public.contract_renewal(contract_id);
create index if not exists idx_renewal_user     on public.contract_renewal(user_id);
create trigger set_renewal_updated_at before update on public.contract_renewal
  for each row execute function public.set_updated_at();
 
-- =============================================================================
-- RECEIVABLE (a receber)
-- =============================================================================
create table if not exists public.receivable (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  contract_id uuid references public.contract(id) on delete set null,
  client_id   uuid references public.client(id) on delete set null,
  description text,
  amount      numeric(14,2) not null default 0,
  due_date    date not null,
  status      receivable_status not null default 'EXPECTED',
  received_at date,
  method      text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);
create index if not exists idx_receivable_user     on public.receivable(user_id);
create index if not exists idx_receivable_contract on public.receivable(contract_id);
create index if not exists idx_receivable_due      on public.receivable(due_date);
create trigger set_receivable_updated_at before update on public.receivable
  for each row execute function public.set_updated_at();
 
-- =============================================================================
-- PAYABLE (a pagar / impostos)
-- =============================================================================
create table if not exists public.payable (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  type        payable_type not null default 'OTHER',
  description text,
  amount      numeric(14,2) not null default 0,
  due_date    date not null,
  status      payable_status not null default 'PENDING',
  paid_at     date,
  receipt_url text,
  invoice_id  uuid,                                   -- FK opcional (imposto de nota)
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);
create index if not exists idx_payable_user on public.payable(user_id);
create index if not exists idx_payable_due  on public.payable(due_date);
create trigger set_payable_updated_at before update on public.payable
  for each row execute function public.set_updated_at();
 
-- =============================================================================
-- INVOICE (nota fiscal)
-- =============================================================================
create table if not exists public.invoice (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  contract_id  uuid references public.contract(id) on delete set null,
  client_id    uuid references public.client(id) on delete set null,
  number       text,
  amount       numeric(14,2) not null default 0,
  issue_date   date,
  planned_date date,
  status       invoice_status not null default 'TO_ISSUE',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz
);
create index if not exists idx_invoice_user     on public.invoice(user_id);
create index if not exists idx_invoice_contract on public.invoice(contract_id);
create trigger set_invoice_updated_at before update on public.invoice
  for each row execute function public.set_updated_at();
 
-- FK opcional payable.invoice_id -> invoice.id (depois que invoice existe)
do $$ begin
  alter table public.payable
    add constraint fk_payable_invoice
    foreign key (invoice_id) references public.invoice(id) on delete set null;
exception when duplicate_object then null; end $$;
 
-- =============================================================================
-- DEMAND (demanda)  — Módulo Atividades
-- =============================================================================
create table if not exists public.demand (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  contract_id uuid references public.contract(id) on delete set null,
  title       text not null,
  description text,
  priority    demand_priority not null default 'MEDIUM',
  deadline    timestamptz,
  status      demand_status not null default 'TODO',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);
create index if not exists idx_demand_user     on public.demand(user_id);
create index if not exists idx_demand_contract on public.demand(contract_id);
create trigger set_demand_updated_at before update on public.demand
  for each row execute function public.set_updated_at();
 
-- =============================================================================
-- TASK (tarefa / subitem da demanda)
-- =============================================================================
create table if not exists public.task (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  demand_id  uuid not null references public.demand(id) on delete cascade,
  title      text not null,
  done       boolean not null default false,
  position   int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists idx_task_demand on public.task(demand_id);
create index if not exists idx_task_user   on public.task(user_id);
create trigger set_task_updated_at before update on public.task
  for each row execute function public.set_updated_at();
 
-- =============================================================================
-- TIME_ENTRY (sessão de cronômetro)
-- =============================================================================
create table if not exists public.time_entry (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users(id) on delete cascade,
  demand_id        uuid not null references public.demand(id) on delete cascade,
  started_at       timestamptz not null,
  ended_at         timestamptz,
  duration_seconds int,                               -- calculado ao fechar
  is_manual        boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  deleted_at       timestamptz
);
create index if not exists idx_time_entry_user   on public.time_entry(user_id);
create index if not exists idx_time_entry_demand on public.time_entry(demand_id);
create index if not exists idx_time_entry_started on public.time_entry(started_at);
create trigger set_time_entry_updated_at before update on public.time_entry
  for each row execute function public.set_updated_at();
 
-- =============================================================================
-- REMINDER (lembrete manual da Agenda)
-- =============================================================================
create table if not exists public.reminder (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  title       text not null,
  date        timestamptz not null,
  recurrence  text,                                   -- ex.: 'MONTHLY:5'
  note        text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);
create index if not exists idx_reminder_user on public.reminder(user_id);
create index if not exists idx_reminder_date on public.reminder(date);
create trigger set_reminder_updated_at before update on public.reminder
  for each row execute function public.set_updated_at();
 
-- =============================================================================
-- NOTIFICATION (central de notificações in-app)
-- =============================================================================
create table if not exists public.notification (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  type       text not null,                           -- ex.: 'RECEIVABLE_OVERDUE'
  title      text not null,
  body       text,
  entity_ref text,                                    -- ex.: 'receivable:<uuid>'
  read_at    timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index if not exists idx_notification_user on public.notification(user_id);
create index if not exists idx_notification_read on public.notification(read_at);
create trigger set_notification_updated_at before update on public.notification
  for each row execute function public.set_updated_at();
 
-- =============================================================================
-- (Opcional / fase de push) DEVICE_TOKEN para APNs
-- =============================================================================
create table if not exists public.device_token (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  token      text not null,
  platform   text not null default 'ios',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);
create index if not exists idx_device_token_user on public.device_token(user_id);
create trigger set_device_token_updated_at before update on public.device_token
  for each row execute function public.set_updated_at();
 
-- =============================================================================
-- ROW LEVEL SECURITY
-- Habilita RLS e cria políticas "own rows" (user_id = auth.uid()).
-- profile usa id = auth.uid().
-- =============================================================================
 
-- profile ---------------------------------------------------------------------
alter table public.profile enable row level security;
create policy profile_select on public.profile for select using (id = auth.uid());
create policy profile_insert on public.profile for insert with check (id = auth.uid());
create policy profile_update on public.profile for update using (id = auth.uid());
create policy profile_delete on public.profile for delete using (id = auth.uid());
 
-- Macro helper: aplica as 4 políticas padrão em uma tabela com coluna user_id
do $$
declare t text;
declare tables text[] := array[
  'client','budget','contract','contract_renewal','receivable','payable',
  'invoice','demand','task','time_entry','reminder','notification','device_token'
];
begin
  foreach t in array tables loop
    execute format('alter table public.%I enable row level security;', t);
 
    execute format(
      'create policy %I on public.%I for select using (user_id = auth.uid());',
      t||'_select', t);
    execute format(
      'create policy %I on public.%I for insert with check (user_id = auth.uid());',
      t||'_insert', t);
    execute format(
      'create policy %I on public.%I for update using (user_id = auth.uid()) with check (user_id = auth.uid());',
      t||'_update', t);
    execute format(
      'create policy %I on public.%I for delete using (user_id = auth.uid());',
      t||'_delete', t);
  end loop;
end $$;
 
-- =============================================================================
-- VIEW: calendar_event  (projeção temporal de tudo que tem data)
-- Somente leitura; herda RLS das tabelas base via security_invoker.
-- =============================================================================
create or replace view public.calendar_event
with (security_invoker = true) as
  select 'receivable'::text as source, r.id as source_id, r.user_id,
         coalesce(r.description,'Recebimento') as title,
         r.due_date::timestamptz as date, r.amount
    from public.receivable r where r.deleted_at is null
  union all
  select 'payable', p.id, p.user_id,
         coalesce(p.description, p.type::text), p.due_date::timestamptz, p.amount
    from public.payable p where p.deleted_at is null
  union all
  select 'invoice', i.id, i.user_id,
         coalesce('Nota '||i.number, 'Nota fiscal'),
         coalesce(i.planned_date, i.issue_date)::timestamptz, i.amount
    from public.invoice i where i.deleted_at is null
  union all
  select 'demand', d.id, d.user_id, d.title, d.deadline, null::numeric
    from public.demand d where d.deleted_at is null and d.deadline is not null
  union all
  select 'contract', c.id, c.user_id, c.title, c.end_date::timestamptz, c.estimated_value
    from public.contract c where c.deleted_at is null and c.end_date is not null
  union all
  select 'reminder', rm.id, rm.user_id, rm.title, rm.date, null::numeric
    from public.reminder rm where rm.deleted_at is null;
 
-- =============================================================================
-- FIM
-- =============================================================================
 
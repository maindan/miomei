# MioMei

App iOS nativo (Swift/SwiftUI) de gestão da vida PJ/MEI — contratos, finanças,
impostos, atividades e agenda em um só lugar, offline-first com sincronização
em segundo plano via Supabase. O escopo funcional completo está em
[`docs/mio-escopo.md`](docs/mio-escopo.md), o guia visual em
[`docs/guia-estilo.html`](docs/guia-estilo.html), e o schema do banco em
[`docs/miomei-db-schema.sql`](docs/miomei-db-schema.sql) (já aplicado ao
projeto Supabase real).

## Pré-requisitos

- macOS + **Xcode 15+**.
- [**XcodeGen**](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.

## Gerando o projeto Xcode

Este repositório não versiona o `.xcodeproj` — ele é gerado a partir de
`project.yml` (XcodeGen) para evitar conflitos de merge no formato binário do
Xcode.

```sh
xcodegen generate
open MioMei.xcodeproj
```

## Configurando os segredos do Supabase

1. Copie o template: `cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig`
   (esse arquivo já está no `.gitignore` — nunca será commitado).
2. Preencha `SUPABASE_HOST` (apenas o host, sem `https://`) e
   `SUPABASE_ANON_KEY`. Os valores reais do projeto MioMei estão em
   `docs/miomei-secrets.env` (também gitignorado).
3. Rode `xcodegen generate` de novo se ainda não tiver gerado o projeto.

> Por que só o host e não a URL completa? Valores de `.xcconfig` tratam `//`
> como início de comentário, então uma linha como `SUPABASE_URL = https://...`
> seria truncada. O app monta a URL completa em runtime
> (`Core/Config/AppConfig.swift`).

## OAuth (Google/GitHub) — pendente de configuração manual

O schema e o app já esperam login via Supabase Auth, mas os provedores Google
e GitHub ainda **não estão ativados** no projeto Supabase (isso exige criar um
OAuth client no Google Cloud Console e um OAuth App no GitHub — passos
detalhados em `docs/miomei-supabase.md` §3). Sem isso, a tela de Login não
completa o fluxo.

## Estrutura

```
Sources/MioMei/
  App/            entry point, ModelContainer, RootView (Login/Onboarding/Tabs)
  Core/
    Activity/     Live Activity do cronômetro (ActivityKit) + estado da navbar
    Auth/         AuthManager (Supabase OAuth + estado de onboarding)
    Config/       leitura dos segredos do Info.plist
    Models/       @Model SwiftData espelhando docs/miomei-db-schema.sql
    Repositories/ CRUD de domínio (Client, Contract, Receivable, Payable, Demand, TimeEntry...)
    Supabase/     cliente supabase-swift singleton
    Sync/         LocalRepository genérico + fila de mutações offline-first + BGTaskScheduler
    Utils/        CNPJValidator, formatação de moeda/duração etc.
  DesignSystem/   gradientes por módulo, Liquid Glass, tipografia, componentes
  Features/       telas por módulo (Auth, Onboarding, Dashboard, Finance, Activities, ...)
Sources/MioMeiShared/   TimerActivityAttributes — compartilhado entre app e widget extension
Sources/MioMeiWidgets/  extensão de Live Activity (Dynamic Island + tela de bloqueio)
Tests/MioMeiTests/
supabase/functions/     Edge Functions (Deno/TypeScript) — deploy manual, ver seção própria
```

## Sincronização real (SyncEngine)

`Core/Sync/SyncEngine.swift` faz push (upsert por tabela, um `PendingMutation`
por vez, usando o payload snake_case já montado em `SyncRows.swift` via
`AnyJSON`) e pull (`updated_at > última sincronização` por tabela, merge por
`id` no SwiftData, `deleted_at` do servidor vira soft delete local). O botão
"Sincronizar agora" está em Configurações, com os 4 estados do indicador
(Sincronizado/Pendente/Sincronizando/Offline/Erro), contagem de pendentes e
carimbo de última sincronização (persistido em `UserDefaults`, não só em
memória). `Core/Sync/RealtimeSyncMonitor.swift` assina mudanças via Supabase
Realtime e dispara um novo `syncNow()` quando outro dispositivo grava algo —
**para funcionar, habilite Realtime por tabela em Database → Replication no
painel do Supabase** (passo manual, fora do controle do app).

## Relatórios exportáveis

Em Atividades → Horas, o ícone de documento no topo gera um CSV das sessões
da semana selecionada (data, demanda, contrato, duração, se foi manual) via
`Core/Utils/HoursReportGenerator.swift`, compartilhável por `ShareLink`
(mesmo padrão do PDF de orçamento).

## Edge Functions (deploy manual)

`supabase/functions/` tem o código-fonte (Deno/TypeScript) das automações
descritas em `docs/miomei-supabase.md` §7 — **não foi feito deploy real**
(exigiria `supabase login` interativo e a chave `.p8` de APNs, que não temos
neste ambiente):

- `recalculate-status/` — `EXPECTED→OVERDUE` / `PENDING→OVERDUE` diariamente.
- `generate-das-mei/` — garante o DAS-MEI do mês para cada perfil MEI.
- `send-push/` — envia push via APNs (provider token ES256 assinado a partir
  da chave `.p8`) para os `device_token` de um usuário.

Passos para deploy (rodar localmente, fora deste ambiente):

```sh
supabase login
supabase link --project-ref tnuubrffjlhlahqxlzuj
supabase functions deploy recalculate-status
supabase functions deploy generate-das-mei
supabase functions deploy send-push
supabase secrets set APNS_KEY_P8="$(cat AuthKey_XXXX.p8)" APNS_KEY_ID=... APNS_TEAM_ID=... APNS_BUNDLE_ID=com.projexsystem.miomei APNS_ENV=sandbox
```

Depois, agende `recalculate-status` e `generate-das-mei` via **Database →
Cron** (pg_cron + `net.http_post`, exemplo comentado no topo de cada
`index.ts`).

## Roadmap de fases (mio-escopo.md §16)

- [x] **Fase 1 — Fundação**: login Google/GitHub via Supabase, onboarding MEI,
      camada offline-first (SwiftData + fila de sync), RLS, navegação e
      Liquid Glass base.
- [x] **Fase 2 — Financeiro core**: clientes, contratos, renovações,
      recebimentos, pagamentos.
- [x] **Fase 3 — Atividades**: demandas, tarefas, cronômetro, Live Activity
      (Dynamic Island + tela de bloqueio), controle de horas + cruzamento com
      contratos.
- [x] **Fase 4 — Orçamentos e Notas**: orçamentos com aprovação/conversão,
      notas, automações de imposto, PDF.
- [x] **Fase 5 — Agenda, Dashboard e Notificações**: calendário unificado,
      lembretes, resumos/alertas, central de notificações + notificações do SO.
- [x] **Fase 6 — Refino**: push via Edge Functions/APNs, relatórios
      exportáveis, sync multi-dispositivo (Realtime), testes e polish.

## Notas de implementação

- A fonte **DotGothic16** (dígitos do cronômetro em curso, Guia de Estilo §5)
  ainda não está empacotada no target — `MioMeiFont.timerRunning()` e
  `TimerSessionView` referenciam o nome da fonte e caem no fallback do sistema
  até o arquivo `.ttf` ser adicionado aos recursos do app.
- **MioMeiWidgets** (extensão de Live Activity) é um target novo no
  `project.yml` — depois de `xcodegen generate`, configure um **Team** de
  assinatura para os dois targets (app e extensão) no Xcode antes de rodar em
  dispositivo físico (Live Activity não funciona no simulador para todas as
  versões de iOS — teste em device real quando possível).
- O controle de "lap" do cronômetro descrito no Guia de Estilo não existe no
  modelo de dados (`time_entry` só tem `started_at`/`ended_at`) e não foi
  implementado — a tela de sessão tem apenas iniciar/parar.
- Contrato PJ com `recurrence` preenchida ganha, na criação, um `Reminder`
  mensal automático de emissão de nota (dia 5) — `ContractRepository.
  scheduleInvoiceReminderIfNeeded`. Só roda ao criar; editar um contrato
  depois para adicionar recorrência não gera o lembrete retroativamente.
- `AlertsEngine` materializa os alertas proativos (§5, §9) como
  `NotificationItem` locais, evitando duplicar o mesmo alerta enquanto ele
  não é lido (`NotificationRepository.hasUnread(entityRef:)`); o teto MEI só
  dispara depois que o usuário preenche "Teto anual MEI" em Configurações.
- `LocalNotificationScheduler` (UserNotifications) dispara de verdade: ao
  criar um lembrete (agendado para a data escolhida) e a cada novo alerta do
  `AlertsEngine` (disparo quase imediato, já que representam algo já
  vencido/urgente). **Lacuna conhecida:** recebimentos, pagamentos e notas
  não têm notificação agendada individualmente na própria data de
  vencimento (com cancelamento ao editar/excluir) — decisão deliberada desta
  fase, para não arriscar notificações órfãs após edição/exclusão sem um
  mecanismo de cancelamento testado; eles continuam aparecendo na Agenda e,
  quando vencidos/urgentes, entram no `AlertsEngine`.
- `CalendarEventProvider` agrega eventos no cliente a partir dos
  repositórios (não lê a view `calendar_event` do Supabase) — os dois devem
  ficar equivalentes; como o `pullChanges` agora traz dados reais do
  servidor, vale revisitar se algum dia fizer sentido ler a view diretamente.
- `RealtimeSyncMonitor` e as Edge Functions não puderam ser testados de
  ponta a ponta neste ambiente (sem macOS/Xcode e sem `supabase login`
  interativo) — a assinatura exata de `postgresChange`/`AnyAction` no
  supabase-swift instalado deve ser conferida ao compilar; o resto do app
  não depende do Realtime para funcionar (push/pull manual e BGTaskScheduler
  continuam a fonte de verdade).
- Testes automatizados continuam limitados a funções puras
  (`CNPJValidatorTests`, `DurationFormatterTests`) — os repositórios
  dependem de `ModelContext`/rede e não têm suíte própria ainda.

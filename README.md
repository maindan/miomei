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
```

## Roadmap de fases (mio-escopo.md §16)

- [x] **Fase 1 — Fundação**: login Google/GitHub via Supabase, onboarding MEI,
      camada offline-first (SwiftData + fila de sync), RLS, navegação e
      Liquid Glass base.
- [x] **Fase 2 — Financeiro core**: clientes, contratos, renovações,
      recebimentos, pagamentos.
- [x] **Fase 3 — Atividades**: demandas, tarefas, cronômetro, Live Activity
      (Dynamic Island + tela de bloqueio), controle de horas + cruzamento com
      contratos.
- [ ] **Fase 4 — Orçamentos e Notas**: orçamentos com aprovação/conversão,
      notas, lembretes de emissão, automações de imposto, PDF.
- [ ] **Fase 5 — Agenda, Dashboard e Notificações**: calendário unificado,
      lembretes, resumos/alertas, central de notificações + notificações do SO.
- [ ] **Fase 6 — Refino**: push via Edge Functions/APNs, relatórios
      exportáveis, sync multi-dispositivo (Realtime), testes e polish.

## Notas de implementação

- A fonte **DotGothic16** (dígitos do cronômetro em curso, Guia de Estilo §5)
  ainda não está empacotada no target — `MioMeiFont.timerRunning()` e
  `TimerSessionView` referenciam o nome da fonte e caem no fallback do sistema
  até o arquivo `.ttf` ser adicionado aos recursos do app.
- `SyncEngine.pushPending()`/`pullChanges()` continuam esqueletos: os
  repositórios já enfileiram cada mutação (`PendingMutation`, payload
  snake_case em `Core/Sync/SyncRows.swift`), mas o upsert real por tabela
  contra o Supabase chega na Fase 6 (sync multi-dispositivo).
- **MioMeiWidgets** (extensão de Live Activity) é um target novo no
  `project.yml` — depois de `xcodegen generate`, configure um **Team** de
  assinatura para os dois targets (app e extensão) no Xcode antes de rodar em
  dispositivo físico (Live Activity não funciona no simulador para todas as
  versões de iOS — teste em device real quando possível).
- O controle de "lap" do cronômetro descrito no Guia de Estilo não existe no
  modelo de dados (`time_entry` só tem `started_at`/`ended_at`) e não foi
  implementado — a tela de sessão tem apenas iniciar/parar.

# MioMei — Guia de continuação no macOS

Este documento é para o agente (Claude Code ou outro) que continuar o desenvolvimento
**no Mac, com Xcode**. Tudo o que existe hoje no repositório (Fases 1 a 6 do
`mio-escopo.md` §16) foi escrito num ambiente **Windows, sem Xcode/macOS** —
ou seja, **nenhuma linha deste projeto foi compilada ainda**. Trate a primeira
compilação como uma etapa de trabalho real, não uma formalidade.

Leia primeiro, nesta ordem: `docs/mio-escopo.md` (escopo funcional, fonte da
verdade de regras de negócio), `docs/guia-estilo.html` (design tokens),
`docs/miomei-db-schema.sql` (schema, já aplicado no Supabase real) e o
`README.md` da raiz (estrutura do projeto + seção **Notas de implementação**,
que lista lacunas conhecidas — não repita esse levantamento aqui, só consulte).

---

## Passo 0 — Segurança urgente (fazer antes de qualquer outra coisa)

O arquivo `docs/miomei-secrets.env` (senha do banco Postgres + connection
string) ficou commitado no histórico do git **antes** de qualquer trabalho
desta sessão, e o repositório é **público** no GitHub. As credenciais atuais
devem ser tratadas como comprometidas.

Isso só pode ser feito por um humano com login no painel do Supabase (não é
possível via SQL direto — a role `postgres` é protegida pelo Supabase e
recusa `ALTER USER` mesmo autenticado como ela mesma):

1. **Project Settings → Database → Reset database password.** Gere uma senha
   nova e forte.
2. **Project Settings → API → JWT Settings → Rotate JWT secret.** Isso invalida
   a `anon key` vazada e gera uma nova automaticamente.
3. Atualize os dois arquivos locais (nenhum dos dois é commitado, ambos já
   estão no `.gitignore`):
   - `docs/miomei-secrets.env`
   - `Config/Secrets.xcconfig` (campos `SUPABASE_HOST` — só o host, sem
     `https://` — e `SUPABASE_ANON_KEY`; veja comentário no
     `Config/Secrets.example.xcconfig`)
4. Confirme que `git status` não mostra nenhum dos dois arquivos como
   modificado/staged antes de commitar qualquer coisa depois disso.

Se quiser rodar via API em vez do painel, é preciso um **personal access
token** do Supabase (`sbp_...`, gerado em Account → Access Tokens) — sem ele
não dá para automatizar essa etapa.

---

## Passo 1 — Gerar o projeto Xcode

```sh
brew install xcodegen   # se ainda não tiver
xcodegen generate
open MioMei.xcodeproj
```

O `.xcodeproj` não é versionado de propósito (formato binário, gerado a
partir de `project.yml`). Se editar targets/dependências, edite `project.yml`
e rode `xcodegen generate` de novo — não edite o `.xcodeproj` à mão.

---

## Passo 2 — Primeira compilação (esperar erros)

Compile os três targets (`MioMei`, `MioMeiWidgets`, `MioMeiTests`) e trate
erros de compilação como prioridade máxima antes de qualquer feature nova.
Pontos de maior risco, por terem sido escritos sem verificação de API real:

- **supabase-swift**: assinaturas de `auth.signInWithOAuth`,
  `auth.authStateChanges`, `postgrest` (`.from(...).upsert(...)`,
  `.select().gt("updated_at", ...)`) e `realtime`
  (`channel.postgresChange`/`AnyAction`) podem ter mudado entre versões —
  o `project.yml` fixa `from: "2.5.1"`, mas confira contra a versão que o
  SPM realmente resolver. `Core/Sync/SyncEngine.swift` e
  `Core/Sync/RealtimeSyncMonitor.swift` são os arquivos mais expostos a isso.
- **SwiftData**: `@Model`, `#Predicate` e `ModelContainer` com múltiplos
  schemas — confira se todos os `@Model` estão registrados no
  `ModelContainer` em `Sources/MioMei/App/MioMeiApp.swift`.
- **ActivityKit**: `Sources/MioMeiWidgets/TimerLiveActivity.swift` e
  `Sources/MioMeiShared/TimerActivityAttributes.swift` — confira compatibilidade
  com a versão de iOS/Xcode instalada (APIs de Live Activity mudaram entre
  iOS 16.1/16.2/17).
- **Swift Charts** em `HoursView.swift` (Fase 3).

Corrija incrementalmente por camada (Models → Core/Sync → Core/Repositories →
Features) em vez de tentar rodar o app inteiro de uma vez.

---

## Passo 3 — Configuração manual no Xcode (fora do `project.yml`)

- **Signing & Capabilities**: defina um **Team** de desenvolvedor Apple nos
  dois targets (`MioMei` e `MioMeiWidgets`) — sem isso não builda para
  device nem simulador em alguns casos de Live Activity.
- Confirme o **URL Type** `miomei` (redirect `miomei://login-callback`) está
  presente no target `MioMei` (deve vir do `Info.plist` gerado, mas confira).
- Confirme `NSSupportsLiveActivities = YES` e o **Background Modes**
  (`fetch`, `processing`) no `Info.plist` do target `MioMei`.
- Adicione a fonte **DotGothic16** (`.ttf`, Google Fonts) ao target `MioMei`
  e ao `Info.plist` (`UIAppFonts`) — hoje o app cai no fallback do sistema
  porque o arquivo não existe neste repositório.

---

## Passo 4 — Ativar OAuth no Supabase

Sem isso a tela de Login não completa o fluxo. Siga `docs/miomei-supabase.md`
§3 (Google Cloud Console + GitHub OAuth App, colar Client ID/Secret em
Authentication → Providers no painel do Supabase). Teste os dois provedores
antes de seguir para os passos abaixo.

---

## Passo 5 — Testar por fase (checklist funcional)

Rode o app e valide contra `docs/mio-escopo.md`, fase por fase, nesta ordem
(cada uma depende da anterior estar funcionando):

1. Login (Google e GitHub) → Onboarding MEI → Dashboard vazio.
2. Financeiro: cliente → contrato → recebimento → marcar recebido → sugestão
   de nota + imposto.
3. Atividades: demanda → cronômetro (iniciar/parar, Live Activity na Dynamic
   Island e tela bloqueada, só 1 ativo por vez) → Horas cruzando com
   `weekly_hours_requirement` do contrato.
4. Orçamentos: criar → enviar → aprovar → converter em contrato (gera
   cronograma de recebimentos) → PDF via share sheet. Notas fiscais.
5. Agenda (eventos agregados + lembretes manuais + filtros), central de
   notificações pelo sino, alertas do `AlertsEngine`.
6. Configurações → Sincronização: "Sincronizar agora" com os 4 estados,
   depois testar offline (modo avião) confirmando que tudo continua editável
   e sincroniza ao voltar a conexão.

Qualquer divergência de comportamento em relação ao `mio-escopo.md` é bug;
qualquer divergência de cor/gradiente/glass em relação ao `guia-estilo.html`
é bug visual.

---

## Passo 6 — Deploy das Edge Functions (opcional, fase de refino)

Código-fonte já está em `supabase/functions/`. Deploy real (não foi feito):

```sh
supabase login
supabase link --project-ref <novo-ou-mesmo-project-ref>
supabase functions deploy recalculate-status
supabase functions deploy generate-das-mei
supabase functions deploy send-push
supabase secrets set APNS_KEY_P8="$(cat AuthKey_XXXX.p8)" APNS_KEY_ID=... APNS_TEAM_ID=... APNS_BUNDLE_ID=com.projexsystem.miomei APNS_ENV=sandbox
```

Depois, agende `recalculate-status` e `generate-das-mei` via Database → Cron
(exemplo comentado no topo de cada `index.ts`). Precisa de uma chave APNs
`.p8` do Apple Developer, que não existe neste repositório.

---

## Passo 7 — Lacunas conhecidas a fechar

Ver seção **Notas de implementação** do `README.md` — não estão repetidas
aqui para não divergir de lugar. Prioridade sugerida, da mais para a menos
importante:

1. Notificação local individual por recebimento/pagamento/nota, com
   cancelamento ao editar/excluir (deixado de fora deliberadamente na Fase 6).
2. Verificar `RealtimeSyncMonitor` e `SyncEngine` compilando e funcionando de
   ponta a ponta contra o supabase-swift real (maior risco do Passo 2).
3. Testes automatizados para repositórios (hoje só há testes de funções
   puras).
4. Lembrete de emissão retroativo ao editar um contrato PJ (hoje só é gerado
   na criação).

## Regras de processo

- Um commit + push por entrega funcional coerente (mesmo padrão das Fases
  1-6 já no histórico) — não deixe trabalho grande sem commitar.
- Nunca commite `docs/miomei-secrets.env` nem `Config/Secrets.xcconfig`
  (ambos já no `.gitignore` — confira antes de `git add`).
- Nunca faça `force-push` em `main` sem confirmação explícita do usuário.

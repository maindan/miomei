# MioMei — Configuração do Supabase (OAuth + Banco + Storage + RLS)
 
Guia passo a passo para preparar o backend Supabase do MioMei antes de iniciar o desenvolvimento do app iOS nativo. Ao final você terá: projeto criado, login Google e GitHub funcionando, banco com todas as tabelas e políticas RLS, Storage para avatar/comprovantes/PDFs, e as chaves para colocar no app.
 
> Ordem recomendada: 1) criar projeto → 2) aplicar o schema SQL → 3) configurar OAuth (Google e GitHub) → 4) Storage → 5) integrar no app iOS → 6) (opcional) Edge Functions e push.
 
---
 
## 0. Pré-requisitos
- Conta no [Supabase](https://supabase.com).
- Conta Google Cloud (para OAuth Google) e conta GitHub (para OAuth GitHub).
- Xcode (iOS 17+ target) e o pacote **supabase-swift** (Swift Package Manager).
- O arquivo `miomei-db-schema.sql` deste projeto.
---
 
## 1. Criar o projeto Supabase
1. Painel Supabase → **New project**.
2. Defina nome (ex.: `miomei`), senha do banco (guarde em local seguro) e região mais próxima do público (ex.: São Paulo).
3. Aguarde o provisionamento.
4. Em **Project Settings → API**, anote:
   - **Project URL** (ex.: `https://xxxx.supabase.co`)
   - **anon public key** (essa é a chave que vai no app iOS — nunca use a `service_role` no cliente).
5. Em **Project Settings → API → JWT**, mantenha as configurações padrão (o RLS usa `auth.uid()`).
---
 
## 2. Aplicar o schema do banco
1. Painel → **SQL Editor → New query**.
2. Cole o conteúdo de `miomei-db-schema.sql` e execute (**Run**).
3. Confira em **Table Editor** que as tabelas foram criadas (`profile`, `client`, `budget`, `contract`, `contract_renewal`, `receivable`, `payable`, `invoice`, `demand`, `task`, `time_entry`, `reminder`, `notification`) e que **RLS está habilitado** (cadeado) em cada uma.
4. Confira em **Database → Policies** que existem políticas de SELECT/INSERT/UPDATE/DELETE por tabela.
> O schema já inclui: extensão de UUID, tabela `profile` ligada a `auth.users`, trigger que cria o `profile` automaticamente no primeiro login, colunas `updated_at`/`deleted_at` para sync offline, e todas as políticas RLS.
 
---
 
## 3. Configurar OAuth
 
### 3.1 URL de callback do Supabase
Todos os provedores usam a mesma URL de callback do Supabase:
```
https://<SEU-PROJECT-REF>.supabase.co/auth/v1/callback
```
Guarde-a — você vai colá-la no Google e no GitHub.
 
### 3.2 Redirect para o app iOS (deep link)
Para o app nativo receber o retorno do login, defina um **URL scheme** próprio e cadastre-o como Redirect URL permitido:
1. No app iOS (Xcode → target → **Info → URL Types**), crie um scheme, ex.: `miomei`.
   - Redirect final do app: `miomei://login-callback`
2. No Supabase → **Authentication → URL Configuration → Redirect URLs**, adicione:
   ```
   miomei://login-callback
   ```
3. (Opcional) Defina o **Site URL** para o mesmo deep link ou para uma landing, se houver.
### 3.3 Google OAuth
1. [Google Cloud Console](https://console.cloud.google.com) → crie/selecione um projeto.
2. **APIs & Services → OAuth consent screen**: configure (External), preencha nome do app, e-mail de suporte, e publique (ou mantenha em teste com usuários de teste).
3. **APIs & Services → Credentials → Create Credentials → OAuth client ID**:
   - Tipo: **Web application** (o Supabase intermedeia o fluxo; use Web mesmo para app nativo via Supabase).
   - **Authorized redirect URIs**: cole a URL de callback do Supabase (§3.1).
   - Crie e copie **Client ID** e **Client Secret**.
4. Supabase → **Authentication → Providers → Google**: ative, cole **Client ID** e **Client Secret**, salve.
> Observação: se futuramente quiser login Google mais nativo (ex.: Google Sign-In SDK com nonce), é possível usar `signInWithIdToken` no supabase-swift. Para começar, o fluxo via `signInWithOAuth` + deep link já resolve.
 
### 3.4 GitHub OAuth
1. GitHub → **Settings → Developer settings → OAuth Apps → New OAuth App**.
2. Preencha:
   - **Application name**: MioMei
   - **Homepage URL**: sua landing ou `https://<project-ref>.supabase.co`
   - **Authorization callback URL**: cole a URL de callback do Supabase (§3.1).
3. Crie o app, gere um **Client Secret** e copie **Client ID** + **Client Secret**.
4. Supabase → **Authentication → Providers → GitHub**: ative, cole as credenciais, salve.
### 3.5 Testar
No app (ou temporariamente num playground), inicie `signInWithOAuth(provider: .google)` e `.github` e confirme que o retorno cai em `miomei://login-callback` e cria a sessão. Verifique em **Authentication → Users** que o usuário aparece e que um `profile` foi criado (pelo trigger).
 
---
 
## 4. Storage (avatar, comprovantes, PDFs)
1. Painel → **Storage → Create bucket**. Crie:
   - `avatars` (público OU privado com URL assinada — recomendado privado).
   - `receipts` (privado) — comprovantes de pagamento.
   - `budgets` (privado) — PDFs de orçamento.
2. Políticas de acesso por usuário (exemplo para `avatars`, aplique análogo aos demais). No **SQL Editor**:
   ```sql
   -- Ler o próprio arquivo (path começa com o uid do usuário)
   create policy "avatars_read_own"
     on storage.objects for select
     using ( bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text );
 
   create policy "avatars_write_own"
     on storage.objects for insert
     with check ( bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text );
 
   create policy "avatars_update_own"
     on storage.objects for update
     using ( bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text );
 
   create policy "avatars_delete_own"
     on storage.objects for delete
     using ( bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text );
   ```
   Convenção de caminho: salve arquivos como `<user_id>/<arquivo>` para as políticas acima funcionarem.
3. **Avatar no primeiro acesso:** o avatar inicial vem da conta OAuth (campo `avatar_url` no `raw_user_meta_data` do `auth.users`). O trigger de criação do `profile` copia esse valor para `profile.avatar_url`. Ao trocar a foto, o app faz upload em `avatars/<uid>/...` e atualiza `profile.avatar_url` com a URL (assinada, se privado).
---
 
## 5. Integração no app iOS (supabase-swift)
1. Xcode → **Add Packages** → `https://github.com/supabase/supabase-swift`.
2. Inicialize o cliente com **Project URL** e **anon key**:
   ```swift
   import Supabase
 
   let supabase = SupabaseClient(
       supabaseURL: URL(string: "https://<project-ref>.supabase.co")!,
       supabaseKey: "<ANON_PUBLIC_KEY>"
   )
   ```
   > Guarde as chaves fora do código versionado (ex.: xcconfig / Info.plist não commitado / build settings). A anon key pode ir no app, mas evite expor no repositório público.
3. Login:
   ```swift
   try await supabase.auth.signInWithOAuth(
       provider: .google,      // ou .github
       redirectTo: URL(string: "miomei://login-callback")
   )
   ```
   Trate o retorno do deep link no `onOpenURL`/`ASWebAuthenticationSession` conforme a versão do supabase-swift.
4. Sessão: o supabase-swift persiste e renova a sessão; leia `supabase.auth.currentUser` para saber se há login ativo e `auth.uid()` correspondente para as queries.
---
 
## 6. Sincronização offline-first (resumo de integração)
- **Local:** SwiftData (ou GRDB) é a fonte de verdade da UI. IDs são **UUID gerados no cliente**.
- **Push:** ao voltar a ter rede (ou via `BGTaskScheduler`), envie as mutações pendentes para as tabelas do Supabase (upsert por `id`, respeitando `updated_at`).
- **Pull:** busque registros com `updated_at > última_sync` e `deleted_at` para aplicar exclusões.
- **Conflitos:** last-write-wins por `updated_at` (documentar exceções por tabela).
- **RLS:** como todas as queries usam a sessão do usuário, o `user_id = auth.uid()` é garantido pelo Supabase — o app deve preencher `user_id` com o uid da sessão ao criar registros.
- **Status de sincronização (Configurações → Sincronizar):** o app mantém no local uma fila de mutações pendentes; um item só é considerado "sincronizado" após confirmação de gravação no Supabase (resposta OK do upsert). O indicador de status e o botão "Sincronizar agora" leem essa fila para exibir pendentes/última sync e confirmar a conclusão ao usuário. Guarde localmente o timestamp da última sincronização bem-sucedida (push+pull) para exibir "Sincronizado há X".
---
 
## 7. Edge Functions e Push (opcional, fase posterior)
Recomendado para automações que não dependem do app estar aberto:
- **Recalcular status** de recebimentos/pagamentos (`EXPECTED→OVERDUE`, `PENDING→OVERDUE`) via função agendada (Supabase **Cron**).
- **Gerar DAS-MEI mensal** para usuários com regime MEI (venc. dia 20).
- **Push (APNs)** para alertas: configurar uma Edge Function que envia notificações via APNs; guardar o **device token** do iOS numa tabela `device_token` (adicionar ao schema quando for implementar).
Passos gerais:
1. Instale a Supabase CLI e rode `supabase functions new <nome>`.
2. Implemente em TypeScript/Deno, faça deploy com `supabase functions deploy <nome>`.
3. Agende com **Database → Cron** (pg_cron) chamando a função ou uma SQL.
4. Para APNs, gere a chave `.p8` no Apple Developer e configure como secret da função (`supabase secrets set`).
---
 
## 8. Checklist final
- [ ] Projeto criado; Project URL e anon key anotados.
- [ ] `miomei-db-schema.sql` aplicado; RLS habilitado em todas as tabelas.
- [ ] Trigger de criação de `profile` funcionando (usuário novo gera profile com avatar da conta).
- [ ] Redirect URL `miomei://login-callback` cadastrado no Supabase.
- [ ] Google OAuth ativo e testado.
- [ ] GitHub OAuth ativo e testado.
- [ ] Buckets `avatars`, `receipts`, `budgets` criados com políticas por usuário.
- [ ] supabase-swift integrado; login e leitura de `auth.uid()` funcionando.
- [ ] (Opcional) Edge Functions + Cron + APNs planejados para a fase de refino.
 
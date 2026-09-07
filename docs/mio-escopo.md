# MioMei — Escopo Funcional Detalhado
 
> App iOS nativo de gestão da vida PJ/MEI: contratos, finanças, impostos, atividades, controle de tempo e produtividade em um só lugar. Offline-first, com sincronização em segundo plano via Supabase.
 
---
 
## 1. Visão Geral
 
**MioMei** é um **aplicativo iOS nativo** (Swift/SwiftUI) voltado ao profissional PJ/MEI que trabalha com múltiplos contratos e freelances. O produto é pensado para uso diário no iPhone, com forte apoio em recursos nativos do sistema (notificações do sistema operacional, Live Activity / Dynamic Island para o cronômetro, foto de perfil da conta de login). Ele centraliza três dores principais desse perfil:
 
1. **Financeiro fragmentado** — saber quanto vai receber, de quem, quando, e quanto precisa pagar de imposto.
2. **Obrigações fiscais esquecidas** — emissão de nota fiscal e pagamento de DAS/impostos que passam despercebidos e geram multa.
3. **Falta de controle de produtividade** — não saber quantas horas foram trabalhadas por contrato, especialmente quando há exigência de carga horária semanal.
O sistema resolve isso com quatro módulos integrados (**Início, Atividades, Financeiro, Agenda**) que compartilham os mesmos dados: um recebimento cadastrado no Financeiro aparece na Agenda; horas registradas em Atividades alimentam o Dashboard; um contrato com exigência de horas cruza os dois mundos.
 
### Princípio central de integração
Cada entidade financeira ou de trabalho com uma **data** (recebimento, pagamento de imposto, emissão de nota, prazo de atividade, renovação) gera automaticamente um **evento na Agenda**. A Agenda não é um módulo isolado: é a projeção temporal de tudo que acontece no sistema.
 
### Princípio de disponibilidade: offline-first
O app deve funcionar **integralmente offline**. Todos os dados são gravados primeiro no armazenamento local do dispositivo; a sincronização com o Supabase acontece **em segundo plano** assim que houver conexão. O usuário nunca fica bloqueado por falta de internet — cria, edita e consulta tudo offline, e o app reconcilia depois.
 
---
 
## 2. Diretriz de Plataforma e Design
 
### 2.1 Plataforma
- **iOS nativo** desenvolvido em **Swift + SwiftUI** (target mínimo sugerido: iOS 17, para viabilizar Live Activity, Dynamic Island e as APIs modernas de concorrência/SwiftData).
- **Backend:** **Supabase** (PostgreSQL gerenciado, Auth, Storage, Realtime, Edge Functions).
- **Autenticação:** **OAuth Google** e **OAuth GitHub** via Supabase Auth. Sem senha própria.
- **Persistência local:** camada offline-first (ver §12) com fila de sincronização e resolução de conflitos.
### 2.2 Design — Liquid Glass nativo
O app é **escuro por padrão**. Cada módulo tem um gradiente próprio que ocupa a tela inteira; o conteúdo vive em cartões translúcidos sobre esse gradiente.
 
- Todo componente com fundo "glass" (cartões, navbar, sheets, modais) deve usar o **estilo nativo Liquid Glass do iOS** — materiais do sistema (`.ultraThinMaterial`, `.regularMaterial`, `glassEffect`/`Glass` conforme disponível na versão de iOS alvo) em vez de simulações manuais de blur. Isso garante fidelidade ao comportamento nativo (refração, realce dinâmico, adaptação a claro/escuro e movimento).
- As cores de acento, gradientes por módulo e tokens tipográficos seguem o **Guia de Estilo MioMei** (arquivo `claude_Guia_de_Estilo_MioMei_dc.html`), que é a fonte da verdade visual. O Liquid Glass é a *técnica de renderização* das camadas; os tokens de cor/tipografia do guia continuam valendo.
### 2.3 Princípios de layout
- **Uma coluna, polegar primeiro.** Empilhamento vertical, navbar flutuante fixa, alvos de toque ≥ 44px.
- **Ação principal ao alcance do polegar.** Botões primários e o cronômetro na zona inferior.
- **Conteúdo essencial acima da dobra.** Cada tela responde à sua pergunta central sem rolagem.
- **Progressive disclosure.** Informação secundária em acordeões, abas, sheets ou "ver mais".
- **Safe areas:** respeitar notch, Dynamic Island e a barra inferior de gestos (padding seguro).
### 2.4 Navegação
- **Bottom navigation bar flutuante** (pílula em Liquid Glass) com os 4 módulos: **Início · Atividades · Financeiro · Agenda**. O item de Atividades pode dar destaque ao cronômetro quando houver sessão em curso.
- **Configurações não fica na navbar** — fica no topo da tela Início, ao lado do sino de notificações.
- **Ações de criar** via **FAB** (botão flutuante), acima da navbar, um por tela no máximo.
- **Formulários, detalhes e confirmações de ações de risco** abrem em **modais/bottom sheets** que sobem de baixo (ver §2.5).
### 2.5 Padrão de modais (criação, edição e confirmação de risco)
Modais de criação, edição e confirmação de ações de risco (ex.: excluir contrato, encerrar contrato com recebimentos pendentes, apagar registro de tempo) seguem o padrão visual já estabelecido:
- **Sobem a partir da parte de baixo da tela**, cobrindo/ocultando a navbar.
- **Escurecem o fundo** com scrim opaco sobre a tela de origem.
- O corpo do modal usa **Liquid Glass** (material do sistema), com alça no topo, título e CTA primário no rodapé.
- Confirmações de ações de risco destacam a ação destrutiva com cor semântica (vermelho) e exigem toque explícito, nunca por gesto acidental.
---
 
## 3. Fluxo Geral do Sistema
 
```
Login (Google ou GitHub OAuth via Supabase)
   → Primeiro acesso: Configuração do MEI/empresa (CNPJ e dados relacionados)
   → Foto de perfil herdada da conta selecionada (ajustável depois)
   → Dashboard (Início)
                                                    │
        ┌───────────────────┬─────────────────────┼──────────────────┐
   Atividades           Financeiro              Agenda            Início
        │                    │                     │                 │
   Demandas + Timer     Orçamento → aprovado    (projeção de todas   (resumo +
        │                → Contrato              as datas do sistema)  atalhos)
   Controle de tempo         │
   (horas por contrato) Recebimentos → Impostos/Notas
```
 
**Ciclo de vida típico de um trabalho:**
Orçamento criado → enviado ao cliente → aprovado → gera Contrato (ou Freelance) → gera cronograma de Recebimentos → trabalho executado via Atividades (com registro de horas / cronômetro) → Nota Fiscal emitida no recebimento → Imposto sobre a nota gerado a pagar → tudo refletido na Agenda.
 
---
 
## 4. Autenticação, Primeiro Acesso e Perfil
 
### 4.1 Login
- Via **Google OAuth** ou **GitHub OAuth**, ambos através do **Supabase Auth**. Sem senha própria.
- A tela de login oferece os dois botões de provedor.
- A sessão é persistida com segurança (Keychain) e renovada automaticamente; o app abre já autenticado enquanto a sessão for válida.
### 4.2 Primeiro acesso — Configuração do MEI/empresa
No **primeiro acesso** (perfil ainda incompleto), o usuário é levado a um fluxo de **configuração do MEI/empresa** antes de usar o sistema. Coleta:
- **CNPJ** (validado: formato + dígitos verificadores).
- **Nome empresarial** e **nome fantasia**.
- **Regime tributário:** MEI / Simples Nacional / outro.
- **Dados relacionados ao MEI:** ocupação/CNAE principal (opcional), data de abertura (opcional), e-mail comercial.
- **Dados bancários / chave PIX** (exibidos nos orçamentos).
- **Alíquota de imposto padrão** (%) — para estimar imposto sobre recebimentos (quando aplicável ao regime).
A **foto de perfil** é inicialmente **herdada da conta selecionada** no login (avatar do Google ou GitHub). O usuário pode **ajustá-la depois** em Configurações (enviar nova imagem para o Supabase Storage ou voltar ao avatar da conta).
 
### 4.3 Regras de negócio do perfil
- O regime tributário determina quais automações de imposto ficam ativas.
  - **MEI:** habilita lembrete mensal de DAS-MEI (vencimento dia 20) e monitora o **teto de faturamento anual** (limite do MEI); quando o acumulado do ano se aproxima do teto, o Dashboard exibe alerta.
  - **Simples/outro:** habilita cálculo de imposto por alíquota configurável sobre notas emitidas.
- O CNPJ é validado no cadastro.
---
 
## 5. Módulo Início (Dashboard)
 
Tela de entrada. Responde de imediato: *"Como está minha operação hoje?"* Topo da tela traz o **sino de notificações** (central de notificações, §11) e a **engrenagem de Configurações** (§10).
 
### Blocos de informação
1. **Resumo financeiro do mês** — a receber, já recebido, a pagar, saldo projetado.
2. **Saúde dos contratos** — ativos; vencendo em ≤ 30 dias; progresso semanal de horas nos contratos com exigência ("18h / 20h").
3. **Produtividade da semana** — total de horas na semana; atividade com cronômetro em curso; demandas em andamento.
4. **Próximas obrigações (7 dias)** — notas a emitir, impostos/boletos a vencer, recebimentos previstos.
5. **Alertas** (lógica proativa) — recebimento atrasado, imposto vencendo em ≤ 3 dias, nota pendente, contrato vencendo sem renovação, faturamento perto do teto MEI.
### Atalhos rápidos
Novo orçamento, novo contrato, nova demanda, registrar recebimento, registrar pagamento de imposto, iniciar cronômetro.
 
---
 
## 6. Módulo Financeiro
 
Núcleo do sistema. Subdividido em: Clientes, Orçamentos, Contratos, Recebimentos, Pagamentos (Impostos) e Notas Fiscais. Navegação interna por **segmented control** (Receber / Pagar / Notas / Contratos) mais telas de Clientes e Orçamentos.
 
### 6.1 Clientes
- Cadastro: nome, documento (CPF/CNPJ), e-mail, telefone, observações.
- Um cliente pode estar vinculado a vários contratos, orçamentos e notas.
- Tela do cliente mostra histórico: contratos, valor total já faturado, recebimentos pendentes.
### 6.2 Orçamentos
**Objetivo:** formalizar uma proposta antes de virar contrato.
- **Composição:** cliente, título, itens (descrição, quantidade, valor unitário), valor total, validade, condições de pagamento, observações.
- **Status:** `Rascunho → Enviado → Aprovado → Recusado` (ou `Expirado`).
**Lógica de negócios:**
- Ao **aprovar**, o sistema oferece **converter em Contrato ou Freelance**, herdando cliente, valor e itens.
- Orçamento aprovado pode gerar automaticamente o **cronograma de recebimentos** conforme as condições de pagamento (ex.: 50% na aprovação + 50% na entrega; ou 3x mensais).
- Orçamento `Enviado` cuja validade expira vira `Expirado` e gera alerta.
- Exportação do orçamento em **PDF** com dados da empresa e cliente (compartilhável via share sheet do iOS).
### 6.3 Contratos
Dois tipos: **PJ (recorrente/longo prazo)** e **Freelance (pontual)**.
 
**Campos comuns:** cliente, título, descrição, tipo, data de início, data de término, valor estimado, status (`Ativo`, `Encerrado`, `Suspenso`), forma de recebimento.
 
**Contrato PJ — específicos:**
- **Recorrência:** valor mensal fixo ou por entrega.
- **Exigência de horas semanais** (opcional): alimenta o controle de produtividade.
- **Renovações:** cada renovação estende a `data de término` e mantém histórico (data, novo prazo, valor adicionado, observação); o prazo vigente é o da última renovação; gera evento na Agenda e pode estender o cronograma de recebimentos.
- **Alerta de vencimento** no Dashboard quando próximo do fim sem renovação.
**Freelance — específicos:**
- Escopo fechado, valor único ou por entregas.
- Status simplificado: `Em andamento → Entregue → Pago`.
**Lógica de negócios (contratos):**
- `a receber = estimado − recebido` (soma dos recebimentos vinculados).
- Encerrar contrato não apaga recebimentos pendentes.
- Contrato é origem de recebimentos, demandas e notas — todos filtráveis por contrato.
### 6.4 Recebimentos
- **Campos:** descrição, contrato/cliente de origem, valor, data prevista, status (`Previsto → Recebido → Atrasado`), data efetiva, forma.
- Avulso ou vinculado; suporta parcelamento (gera N parcelas a partir de total + nº de parcelas).
**Lógica:**
- Data prevista passou e status `Previsto` → `Atrasado` + alerta.
- Ao marcar `Recebido`, sugere **registrar nota fiscal** e **gerar imposto a pagar** (alíquota do perfil).
- Cada previsto vira evento na Agenda; alimenta o faturamento anual (teto MEI).
### 6.5 Pagamentos / Impostos
- **Tipos:** DAS-MEI, imposto sobre nota, outros boletos/despesas.
- **Campos:** tipo, descrição, valor, vencimento, status (`Pendente → Pago → Vencido`), data de pagamento, comprovante (opcional, no Supabase Storage).
**Lógica:**
- **DAS-MEI recorrente:** se regime MEI, gera pagamento pendente todo mês (venc. dia 20) com lembrete antecipado.
- **Imposto sobre nota:** ao registrar nota (ou marcar recebimento como recebido), cria imposto a pagar pela alíquota.
- Vencimento passou sem pagamento → `Vencido` + alerta.
- Cada pagamento vira evento na Agenda; lembrete N dias antes (configurável).
### 6.6 Notas Fiscais
- **Campos:** número, cliente, contrato de origem, valor, data de emissão, status (`A emitir → Emitida`), data prevista de emissão.
- **Lembrete de emissão** agendável (ex.: "todo dia 5 emitir nota do contrato X").
**Lógica:**
- Nota `A emitir` cuja data chegou vira pendência no Dashboard.
- Nota `Emitida` alimenta faturamento anual e gera imposto sobre a nota.
- Contratos PJ recorrentes podem ter lembrete de emissão mensal automático.
---
 
## 7. Módulo Atividades (Demandas + Controle de Tempo)
 
**Objetivo:** organizar o trabalho e medir o tempo dedicado, cruzando com a exigência de horas dos contratos. Reúne, num só módulo, a gestão de **demandas** e o **controle de tempo** das atividades.
 
### 7.1 Demandas
- **Campos:** título, descrição, contrato associado, prioridade, prazo (deadline), status (`A fazer → Em andamento → Concluída`).
- Vinculável a contrato (para atribuir horas ao contrato certo).
- Prazo vira evento na Agenda.
### 7.2 Tarefas
- Cada demanda tem uma lista de **tarefas** (subitens) com título e status.
- Progresso da demanda = % de tarefas concluídas.
- Registro de tempo no nível da demanda (por tarefa é fase futura).
### 7.3 Controle de Tempo (Cronômetro)
Funcionalidade central de produtividade.
- **Iniciar/parar** por demanda: iniciar cria registro aberto (`started_at`); parar fecha (`ended_at`) e calcula duração.
- **Apenas um cronômetro ativo por vez** — iniciar em outra demanda encerra o anterior (regra configurável).
- Registro manual de tempo permitido (para quando esqueceu de ligar).
- Cada sessão fica no histórico da demanda.
**Cronômetro nativo em segundo plano (Live Activity / Dynamic Island):**
- Quando um cronômetro está em curso e o app vai para **segundo plano**, o app usa recursos nativos do iOS para exibir o cronômetro na **Dynamic Island (notch)** e na **tela de bloqueio** (Live Activity via ActivityKit).
- A Live Activity mostra a demanda/contrato em andamento e o tempo correndo, e sempre que possível usa as **cores personalizadas do sistema MioMei** (gradiente/acento do módulo Atividades).
- Controles rápidos na Live Activity (pausar/parar) quando viável.
- O tempo continua sendo contabilizado de forma confiável mesmo com o app suspenso (âncora por timestamp `started_at`, não por contador em memória).
**Lógica de negócios (horas):**
- Somatório por **dia, semana e mês** e por **contrato**.
- **Cruzamento com exigência semanal:** progresso (`registradas / exigidas`) com sinalização Verde (meta atingida) · Amarelo (em andamento) · Vermelho (semana acabando, meta não atingida).
- Relatório de horas exportável por período/contrato.
### 7.4 Tela de Controle de Horas
- Diária: linha do tempo das sessões do dia.
- Semanal: total por dia + total da semana + progresso por contrato (calendário com seleção de semana).
- Mensal: consolidado por contrato.
---
 
## 8. Módulo de Agenda
 
**Objetivo:** projeção temporal única de tudo que tem data no sistema, mais lembretes próprios.
 
### 8.1 Eventos automáticos (agregados de outros módulos)
Lê e exibe (sem duplicar dado): recebimentos previstos, pagamentos/impostos a vencer, notas a emitir, prazos de demandas, renovações/vencimentos de contratos. Cada tipo tem cor/ícone próprio.
 
### 8.2 Lembretes manuais
- Lembretes livres (título, data/hora, nota, recorrência opcional).
- Recorrência para rotinas ("emitir nota dia 5", "conferir DAS dia 18").
### 8.3 Visualizações
- **Mês / Semana / Dia** (padrão mobile: faixa semanal + lista de eventos).
- Filtros por tipo de evento.
- Tocar num evento leva à entidade de origem.
### 8.4 Notificações
- Lembretes disparam notificação (ver §11) com antecedência configurável.
- Agrupamento diário: resumo do dia.
---
 
## 9. Regras de Negócio Transversais (resumo)
 
| Gatilho | Ação automática |
|--------|-----------------|
| Orçamento aprovado | Oferece converter em contrato + gerar recebimentos |
| Recebimento marcado como recebido | Sugere registrar nota + gerar imposto sobre o valor |
| Nota fiscal emitida | Atualiza faturamento anual + gera imposto a pagar |
| Regime = MEI | Gera DAS-MEI mensal (venc. dia 20) + monitora teto de faturamento |
| Data prevista de recebimento passou | Status → Atrasado + alerta |
| Vencimento de imposto passou | Status → Vencido + alerta |
| Contrato perto do fim sem renovação | Alerta de renovação no Dashboard |
| Qualquer entidade com data | Vira evento na Agenda |
| Cronômetro iniciado em nova demanda | Encerra o anterior (1 ativo por vez) |
| Cronômetro em curso + app em segundo plano | Inicia/atualiza Live Activity (Dynamic Island + tela de bloqueio) |
| Horas da semana < exigência do contrato | Sinalização de risco no Dashboard/Horas |
| Evento/obrigação chegando | Notificação local do iOS + item na central de notificações |
 
---
 
## 10. Módulo de Configurações
 
Acessível pela engrenagem no topo da tela Início. Reúne ajustes de perfil e do sistema que fazem sentido para as funcionalidades:
 
- **Perfil e empresa:** foto (herdada da conta ou personalizada), nome empresarial/fantasia, CNPJ, e-mail comercial, dados bancários/PIX.
- **Regime tributário e impostos:** regime (MEI/Simples/outro), alíquota padrão, teto MEI, dia de vencimento do DAS.
- **Notificações:** ligar/desligar por categoria (financeiro, impostos, contratos, prazos, resumo diário); antecedência dos lembretes; horário do resumo diário.
- **Cronômetro:** um-ativo-por-vez (on/off), habilitar Live Activity na Dynamic Island e tela de bloqueio, arredondamento de tempo (opcional).
- **Sincronização e dados** (ver §10.1 para o detalhamento): monitor de status de sincronização, botão de forçar sincronização com confirmação de conclusão, uso de dados móveis para sync (on/off), limpar cache local.
- **Conta:** provedor de login conectado (Google/GitHub), trocar foto, sair, excluir conta (com confirmação de ação de risco).
- **Aparência:** o app é escuro por padrão; expor apenas ajustes que façam sentido (ex.: reduzir movimento respeitando acessibilidade do iOS).
### 10.1 Monitor e Forçar Sincronização
 
Como o app é offline-first, o usuário precisa de visibilidade clara sobre **se os dados atuais já estão sincronizados online** e de uma forma de **forçar a sincronização** quando quiser garantir isso (ex.: antes de trocar de dispositivo ou depois de trabalhar muito tempo offline).
 
**Indicador de status de sincronização** (na seção Sincronização das Configurações; um resumo compacto pode aparecer também no topo da tela Início):
- **Estado atual**, com quatro situações possíveis:
  - **Sincronizado** — nada pendente; tudo que está no dispositivo já foi enviado ao Supabase.
  - **Pendente** — há N alterações locais ainda não enviadas (mostrar a contagem).
  - **Sincronizando…** — envio/recepção em andamento (com indicador de progresso).
  - **Offline** — sem conexão; as alterações serão enviadas quando a rede voltar.
  - **Erro** — a última tentativa falhou (mostrar motivo resumido e opção de tentar de novo).
- **Última sincronização bem-sucedida:** data e hora ("Sincronizado há 3 min" / "hoje 14:22").
- **Itens pendentes:** número de mutações na fila aguardando envio; opcionalmente detalhável por tipo (ex.: "2 recebimentos, 1 demanda").
- O indicador é **reativo**: reflete em tempo real a fila de sincronização e o estado de conectividade.
**Botão "Sincronizar agora" (forçar sincronização):**
- Dispara imediatamente um ciclo completo de push (envia a fila local) + pull (busca mudanças do servidor), independentemente do agendamento em segundo plano.
- Durante a execução, o botão entra em estado de carregamento e o status muda para **Sincronizando…**.
- **Confirmação de conclusão:** ao terminar com sucesso, o app dá um retorno explícito ao usuário — mensagem/toast "Tudo sincronizado" + atualização do carimbo "Última sincronização" para o horário atual + zera a contagem de pendentes. Feedback tátil (haptic) opcional.
- **Se falhar:** exibe erro claro ("Não foi possível sincronizar — sem conexão" ou motivo do servidor), mantém as alterações na fila (nada é perdido) e oferece **tentar novamente**.
- **Sem conexão:** se o usuário tocar em "Sincronizar agora" estando offline, o app informa que não há rede e que a sincronização ocorrerá automaticamente quando a conexão voltar.
**Regras de apoio:**
- A verdade sobre "pendente vs. sincronizado" vem da fila de sincronização local (mutações ainda não confirmadas pelo servidor) — um item só sai da fila após confirmação de gravação no Supabase.
- Respeitar a preferência de "usar dados móveis para sync": o sync automático em segundo plano pode ficar restrito ao Wi-Fi, mas o **"Sincronizar agora" manual sempre executa** (é uma ação explícita do usuário), avisando se estiver em rede móvel.
---
 
## 11. Central de Notificações e Alertas do Sistema
 
O app tem uma **central de notificações in-app** (acessível pelo sino no topo da tela Início) e, quando pertinente, **dispara notificações no sistema operacional** do usuário.
 
- **Central in-app:** lista cronológica de alertas e avisos (recebimento atrasado, imposto vencendo, nota a emitir, contrato a renovar, meta de horas em risco, teto MEI próximo, resumo diário). Cada item leva à entidade de origem; suporta marcar como lido e limpar.
- **Notificações do SO (iOS):** via **UserNotifications** (notificações locais agendadas para obrigações com data) e, opcionalmente, **push** via Supabase (Edge Function + APNs) para alertas gerados no servidor (ex.: recálculo de status atrasado/vencido em background).
- **Permissões:** solicitar autorização de notificações no momento certo (após o primeiro cadastro relevante), com fallback claro se negada.
- **Geração de alertas:** parte é derivada localmente (datas conhecidas), parte reconciliada na sincronização; a central mostra ambos de forma unificada.
---
 
## 12. Arquitetura Offline-First e Sincronização
 
O app é **offline-first**. Diretrizes:
 
- **Persistência local:** camada de dados no dispositivo (recomendado **SwiftData** no iOS 17+, ou GRDB/SQLite como alternativa) como fonte de verdade para a UI. A UI lê e escreve sempre localmente.
- **Fila de sincronização:** cada mutação local (create/update/delete) entra numa fila com carimbo de tempo e é enviada ao Supabase quando há rede.
- **Sync em segundo plano:** usar **BGTaskScheduler** (background app refresh / processing tasks) para sincronizar periodicamente, além de sync oportunista ao voltar para foreground ou recuperar conexão.
- **Resolução de conflitos:** estratégia last-write-wins por padrão, com `updated_at`/versão por registro; campos sensíveis (ex.: status financeiro) podem exigir merge específico. Documentar por tabela.
- **Identificadores:** usar **UUID gerado no cliente** como chave primária, para permitir criação offline sem colisão.
- **Soft delete:** marcar `deleted_at` em vez de apagar, para sincronizar exclusões com segurança.
- **Realtime (opcional):** Supabase Realtime para refletir mudanças feitas em outros dispositivos do mesmo usuário.
- **Segurança:** **Row Level Security (RLS)** no Supabase garantindo que cada usuário só acessa seus próprios dados (`user_id = auth.uid()`).
---
 
## 13. Stack Tecnológica
 
**App (iOS nativo):**
- Swift + **SwiftUI** (iOS 17+).
- Concorrência com async/await.
- **SwiftData** (persistência local offline-first) — alternativa: GRDB/SQLite.
- **ActivityKit** (Live Activity + Dynamic Island para o cronômetro).
- **UserNotifications** (notificações locais); **WidgetKit** para a apresentação da Live Activity.
- **BGTaskScheduler** (sincronização em segundo plano).
- **Liquid Glass** nativo para as superfícies translúcidas (materiais do sistema).
- **Swift Charts** para gráficos de horas/financeiro.
**Backend (Supabase):**
- **PostgreSQL** gerenciado (esquema em `miomei-db-schema.sql`).
- **Supabase Auth** com **OAuth Google e GitHub**.
- **Row Level Security** em todas as tabelas.
- **Supabase Storage** para foto de perfil, comprovantes e PDFs de orçamento.
- **Edge Functions** para lógica server-side (recálculo de status atrasado/vencido, geração de DAS-MEI mensal, push de alertas).
- **Realtime** (opcional) para sync multi-dispositivo.
- Cliente **supabase-swift** no app.
**Integração:** o passo a passo de configuração do Supabase (OAuth + banco + storage + RLS) está em `miomei-supabase-setup.md`. O esquema de tabelas está em `miomei-db-schema.sql`.
 
---
 
## 14. Telas Principais
 
| # | Tela | Módulo | Padrão de layout mobile |
|---|------|--------|--------------------------|
| 1 | Login (Google / GitHub) | — | Tela cheia, dois botões de provedor |
| 2 | Configuração MEI/empresa (1º acesso) | — | Formulário em coluna única, campos empilhados |
| 3 | Dashboard | Início | Cards de resumo em coluna; sino + engrenagem no topo |
| 4 | Clientes | Financeiro | Lista de cards; detalhe em sheet |
| 5 | Orçamentos (lista + editor + PDF) | Financeiro | Lista de cards; editor de itens empilhado |
| 6 | Contratos (lista) | Financeiro | Lista de cards; filtro em drawer |
| 7 | Detalhe do contrato | Financeiro | Cabeçalho + abas/acordeões; renovações em timeline |
| 8 | Recebimentos | Financeiro | Cards com ação swipe "recebido"; FAB |
| 9 | Pagamentos / Impostos | Financeiro | Cards com ação swipe "pago"; FAB |
| 10 | Notas fiscais | Financeiro | Lista de cards com status; FAB |
| 11 | Demandas (lista) | Atividades | Cronômetro ativo no topo; cards com play + progresso; FAB |
| 12 | Detalhe da demanda (tarefas + timer) | Atividades | Cronômetro fixo na base; tarefas como checklist |
| 13 | Controle de horas | Atividades | Calendário com seleção de semana + gráfico semanal |
| 14 | Sessão / cronômetro | Atividades | Cartão de glow + dígitos + histórico de sessões |
| 15 | Agenda / Calendário | Agenda | Faixa semanal + lista de eventos; FAB |
| 16 | Central de notificações | — | Lista cronológica; toque leva à origem |
| 17 | Configurações | — | Lista de seções em coluna única |
 
---
 
## 15. Modelo de Dados (rascunho)
 
Detalhamento completo (tipos, RLS, índices) em `miomei-db-schema.sql`. Visão geral:
 
```
profile         id (=auth uid), company_name, trade_name, cnpj, email,
                tax_regime, default_tax_rate, pix_key, avatar_url,
                onboarding_done, created_at, updated_at
 
client          id, user_id, name, document, email, phone, notes, deleted_at
 
budget          id, user_id, client_id, title, items(jsonb), total_value,
                valid_until, payment_terms, status, created_at, updated_at, deleted_at
 
contract        id, user_id, client_id, type(PJ|FREELANCE), title, description,
                start_date, end_date, estimated_value, weekly_hours_requirement?,
                recurrence?, status, created_at, updated_at, deleted_at
 
contract_renewal id, contract_id, new_end_date, added_value?, note, created_at
 
receivable      id, user_id, contract_id?, client_id?, description, amount,
                due_date, status(EXPECTED|RECEIVED|OVERDUE), received_at?, method,
                created_at, updated_at, deleted_at
 
payable         id, user_id, type(DAS_MEI|INVOICE_TAX|OTHER), description, amount,
                due_date, status(PENDING|PAID|OVERDUE), paid_at?, receipt_url?,
                created_at, updated_at, deleted_at
 
invoice         id, user_id, contract_id?, client_id, number?, amount,
                issue_date?, planned_date, status(TO_ISSUE|ISSUED),
                created_at, updated_at, deleted_at
 
demand          id, user_id, contract_id?, title, description, priority,
                deadline?, status(TODO|IN_PROGRESS|DONE),
                created_at, updated_at, deleted_at
 
task            id, demand_id, title, done
 
time_entry      id, user_id, demand_id, started_at, ended_at?, duration_seconds,
                created_at, updated_at, deleted_at
 
reminder        id, user_id, title, date, recurrence?, note, created_at, deleted_at
 
notification    id, user_id, type, title, body, entity_ref, read_at, created_at
 
calendar_event  (view derivada: agrega receivable, payable, invoice,
                 demand.deadline, contract dates, reminder)
```
 
Todas as tabelas de usuário carregam `user_id` e RLS `user_id = auth.uid()`. UUIDs gerados no cliente; `updated_at`/`deleted_at` para sync offline.
 
---
 
## 16. Fases de Desenvolvimento
 
1. **Fundação** — login Google/GitHub via Supabase, onboarding MEI, camada offline-first (SwiftData + fila de sync), RLS, navegação e Liquid Glass base.
2. **Financeiro core** — clientes, contratos, renovações, recebimentos, pagamentos.
3. **Atividades** — demandas, tarefas, cronômetro, Live Activity (Dynamic Island + tela de bloqueio), controle de horas + cruzamento com contratos.
4. **Orçamentos e Notas** — orçamentos com aprovação/conversão, notas, lembretes de emissão, automações de imposto, PDF.
5. **Agenda, Dashboard e Notificações** — calendário unificado, lembretes, resumos/alertas, central de notificações + notificações do SO.
6. **Refino** — push via Edge Functions/APNs, relatórios exportáveis, sync multi-dispositivo (Realtime), testes e polish.
 
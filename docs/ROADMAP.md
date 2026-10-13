# Roadmap de funcionalidades

Aprovado em 09/10/2026. Uma fase por build no teste fechado; cada item é testado
no emulador antes do commit. Marque `[x]` ao concluir.

## Decisões

| Tema | Decisão |
|---|---|
| Eventos que se repetem | Grátis para todos |
| Mochila de amanhã | Grátis para todos (aviso gerado no aparelho) |
| Plano anual | R$ 99,90/ano (mensal R$ 9,90) |
| Avisos da Família | Ao criar, alterar e cancelar; edições seguidas viram um aviso só |
| Ordem | Fase 1 → 2 → 3 → 4 |
| IA (foto do bilhete vira evento) | Adiada — não fazer sem pedido |

## Fase 1 — Base do dia a dia

- [x] **Eventos que se repetem** — build 38
  - Formulário: não repete / todo dia / toda semana (dias escolhidos) / todo mês;
    término: nunca, até uma data, ou N vezes.
  - Agenda, Início e calendário mostram cada ocorrência no dia certo
    (o evento é salvo uma vez, com a regra `recurrence_json`).
  - Concluir marca só a ocorrência; editar/excluir perguntam "só este" ou "todos".
  - Lembretes locais agendados para as próximas ocorrências.
  - Servidor: `get_premium_users_for_push_json` conta as ocorrências.
- [x] **Compartilhar evento no WhatsApp** (texto pronto no detalhe do evento) — build 38

## Fase 2 — Família viva

- [x] **Avisos da Família na hora** — build 39. Trigger no banco enche uma fila
  (`private.family_change_queue`); o n8n busca a cada minuto e envia pelo FCM
  (sem pg_net). Edições seguidas viram um aviso só; opção em Notificações.
- [x] **Convite pelo WhatsApp com link** `rbarbosa.tech/convite/<token>` — build 39
  (página na billing-api, smartagenda:// e App Links, install referrer do Play).
  Digitais SHA-256 (assinatura do Play + upload) em `invite.js`.

## Fase 3 — Escola

- [x] **Provas e trabalhos** — build 40. Tipos Prova/Trabalho com matéria
  (`school_subject`, sugestões da grade), "Próximas provas e trabalhos" na
  Início com contagem regressiva, lembrete 2 dias antes.
- [x] **Mochila de amanhã** — build 40. "O que levar" por matéria na grade
  (`bring_json`); aviso local às 20h das próximas 7 noites; opção em Notificações.

## Fase 4 — Assinaturas

- [ ] **7 dias grátis + plano anual** (configurar na Play; tela do Pro com
  mensal/anual e o teste grátis para quem nunca testou).
- [ ] **Pro por 24h com anúncio premiado** (bloco AdMob; verificação SSV no
  servidor; 1 vez por semana).
- [ ] **Widget Android** ("Hoje: 2 eventos · Próxima aula: Inglês 09:50").

## Precisa do dono do app

- Fase 4: criar oferta de teste grátis e plano anual na Play; bloco de
  anúncio premiado no AdMob.
- Cada fase: subir o build no teste interno e no fechado.

## Depois (fora deste roadmap)

- IA: foto do bilhete da escola vira evento (Pro, com algumas leituras grátis).
- Links das fotos expiram em 1 ano (URL assinada) — trocar por caminho + URL
  gerada na hora.

# Fluxo Premium - Google Play Billing

## Arquitetura

1. **Flutter**: `in_app_purchase` → compra → `purchaseStream` → `BillingController` envia para API Node
2. **API Node** (`smart-agenda-billing-api`): valida com Google Play API → persiste em `user_subscriptions`
3. **PlanServiceImpl**: consulta RPC `get_subscription_premium_status` → fallback `premium_allowlist`

## Configurações Necessárias

### Flutter

- **Pacote**: `in_app_purchase: ^3.2.3`
- **Product ID** (assinatura no Play Console): `smart_agenda_premium` (plano basico ex.: `premium-mensal` e so no Console; o app usa apenas o product id)
- **Package**: `com.digo.smartagenda`
- **Build**: `--dart-define=BILLING_API_BASE_URL=https://sua-api.easypanel.host`

### Supabase

- **Migration**: executar `006_user_subscriptions.sql` antes de usar o fluxo
- **JWT**: a API Node valida o token Supabase do usuário

### API Node (smart-agenda-billing-api)

Variáveis de ambiente (ver `env.example`):

- `BILLING_ALLOWED_PRODUCT_IDS`: IDs permitidos (ex: `smart_agenda_premium`)
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`: JSON da service account
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_JWT_ISSUER`, `SUPABASE_JWT_AUDIENCE`

### Google Play

1. **Play Console** → Monetização → Produtos → Assinaturas
2. Criar assinatura com ID de produto: `smart_agenda_premium` (e um plano basico ativo, ex.: `premium-mensal`)
3. **Google Cloud Console** → Service Account com permissão "Administrador da API Android"
4. Vincular service account ao projeto no Play Console
5. Baixar JSON da service account → configurar na API Node

### Teste

- **Licenças de teste**: Play Console → Configurações → Licenças de teste → adicionar emails
- **Contas de teste**: não serão cobradas em compras de teste

## Deploy da API Node

A API roda em Node (Fastify), deployável via Docker no EasyPanel ou similar. Ver `smart-agenda-billing-api/Dockerfile` e `env.example`.

## Teste Local

1. **Flutter**: `flutter run` com `--dart-define=BILLING_API_BASE_URL=http://localhost:3000`
2. **API Node**: `cd smart-agenda-billing-api && node server.js`
3. App em modo debug com Supabase configurado

## Pendências Externas

- Criar assinatura no Play Console
- Configurar service account e vincular ao app
- App em teste interno para validar compras reais

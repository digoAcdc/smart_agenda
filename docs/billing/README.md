# Fluxo Premium - Google Play Billing

## Arquitetura

1. **Flutter**: `in_app_purchase` → compra → `purchaseStream` → `BillingController` envia para Edge Function
2. **Edge Function** `validate-subscription`: valida com Google Play API → persiste em `user_subscriptions`
3. **PlanServiceImpl**: consulta RPC `get_subscription_premium_status` → fallback `premium_allowlist`

## Configurações Necessárias

### Flutter

- **Pacote**: `in_app_purchase: ^3.2.3`
- **Product ID**: `smart_agenda_premium_monthly` (criar no Play Console)
- **Package**: `com.digo.smartagenda`

### Supabase

**Secrets** (Dashboard → Project Settings → Edge Functions):

- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`: JSON completo da service account (string)
- `SUPABASE_SERVICE_ROLE_KEY`: já disponível no projeto

**Variáveis** (automáticas):

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

### Google Play

1. **Play Console** → Monetização → Produtos → Assinaturas
2. Criar assinatura com ID: `smart_agenda_premium_monthly`
3. **Google Cloud Console** → Service Account com permissão "Administrador da API Android"
4. Vincular service account ao projeto no Play Console
5. Baixar JSON da service account → colocar em `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

### Teste

- **Licenças de teste**: Play Console → Configurações → Licenças de teste → adicionar emails
- **Contas de teste**: não serão cobradas em compras de teste

## Deploy da Edge Function

```bash
supabase functions deploy validate-subscription --project-ref SEU_PROJECT_REF
```

Configurar secrets:

```bash
supabase secrets set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
```

## Migrations

Executar `006_user_subscriptions.sql` no Supabase antes de usar o fluxo.

## Teste Local

1. **Flutter**: `flutter run` em dispositivo Android com Google Play
2. **Edge Function**: `supabase functions serve validate-subscription`
3. App em modo debug com Supabase configurado

## Pendências Externas

- Criar assinatura no Play Console
- Configurar service account e vincular ao app
- Deploy da Edge Function em produção
- App em teste interno para validar compras reais

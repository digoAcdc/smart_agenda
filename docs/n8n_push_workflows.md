# Workflows n8n - Push Agenda Premium

## Payload FCM: como o app interpreta

O app usa o campo **`data`** do push para saber o que abrir. Envie sempre:

| Campo | Obrigatório | Valores | Descrição |
|-------|-------------|---------|-----------|
| `type` | Sim | `daily_summary`, `tomorrow_summary` ou `weekly_summary` | Tipo da notificação |
| `date` | Sim | `YYYY-MM-DD` | Data de referência |

**Regras:**
- **Resumo diário**: `type: "daily_summary"`, `date: "2025-03-10"` (o dia)
- **Resumo amanhã**: `type: "tomorrow_summary"`, `date: "2025-03-11"` (amanhã)
- **Resumo semanal**: `type: "weekly_summary"`, `date: "2025-03-10"` (segunda-feira da semana)

O app abre a aba Agenda e seleciona essa data.

**Exemplo completo do body FCM:**

```json
{
  "to": "SEU_FCM_TOKEN",
  "notification": {
    "title": "Sua agenda de hoje",
    "body": "3 eventos programados"
  },
  "data": {
    "type": "daily_summary",
    "date": "2025-03-10"
  }
}
```

---

## Pré-requisitos

1. **Supabase**: URL + `service_role` key (Dashboard > Settings > API)
2. **Firebase**: Server Key (Console > Project Settings > Cloud Messaging) ou OAuth 2.0 para FCM v1



## Preferências de push

Os usuários premium/allowlist configuram na tela de notificações do app quais resumos querem receber:

| Preferência | Default | Descrição |
|-------------|---------|-----------|
| `push_daily_summary` | true | Agenda do dia (manhã) |
| `push_tomorrow_summary` | false | Agenda de amanhã (fim do dia) |
| `push_weekly_summary` | true | Agenda da semana (domingo) |

As RPCs retornam apenas usuários com a preferência correspondente habilitada.

---

## Migrations

Execute no Supabase, em ordem:
- `supabase/migrations/008_user_notifications.sql`
- `supabase/migrations/009_user_push_preferences.sql`
- `supabase/migrations/010_rpc_push_json.sql`

---

## RPCs disponíveis

### RPC JSON (recomendada)

Uma única RPC parametrizada retorna JSON pronto para o n8n. Usa agregação prévia em vez de subqueries correlacionadas — escalável para bases grandes.

**Chamada:**
```
POST {{SUPABASE_URL}}/rest/v1/rpc/get_premium_users_for_push_json
Headers: apikey, Authorization (service_role)
Body: { "push_type": "daily_summary", "date": "2026-03-09" }
```

**Parâmetros:**
| Parâmetro | Obrigatório | Descrição |
|-----------|-------------|-----------|
| `push_type` | Sim | `daily_summary`, `tomorrow_summary` ou `weekly_summary` |
| `date` | Não | Data base (YYYY-MM-DD). Recomendado: `{{$now.toFormat('yyyy-MM-dd')}}` no n8n para evitar timezone (servidor em UTC). Se omitido, usa CURRENT_DATE do servidor. |

**Resposta (body direto):**
```json
[
  {
    "user_id": "uuid-do-usuario",
    "token": "fcm_token_aqui",
    "platform": "android",
    "reference_date": "2026-03-09",
    "event_count": 3
  }
]
```

O PostgREST retorna o array JSON diretamente. No n8n, filtre itens com `event_count > 0` antes de enviar o push.

---

### Sem count (requer query agenda_items por usuário)

| RPC | Retorno | Uso |
|-----|---------|-----|
| `get_premium_users_for_daily_push` | `user_id`, `token`, `platform`, `reference_date` | Workflow diário |
| `get_premium_users_for_tomorrow_push` | `user_id`, `token`, `platform`, `reference_date` | Workflow amanhã |
| `get_premium_users_for_weekly_push` | `user_id`, `token`, `platform`, `reference_date` | Workflow semanal |

### Com count (recomendado para escalabilidade)

Evita N queries de `agenda_items` no n8n.

| RPC | Retorno | Uso |
|-----|---------|-----|
| `get_premium_users_for_daily_push_with_count` | + `event_count` | Workflow diário |
| `get_premium_users_for_tomorrow_push_with_count` | + `event_count` | Workflow amanhã |
| `get_premium_users_for_weekly_push_with_count` | + `event_count` | Workflow semanal |

Se `event_count = 0`, não enviar push.

---

## Query agenda_items (quando não usar RPC com count)

Para cada usuário retornado pela RPC sem count:

**Diário / Amanhã:**
```
GET {{SUPABASE_URL}}/rest/v1/agenda_items?
  user_id=eq.{{user_id}}&
  start_at=gte.{{reference_date}}T00:00:00&
  start_at=lte.{{reference_date}}T23:59:59&
  deleted_at=is.null&
  select=id
```

**Semanal** (reference_date = segunda):
```
GET {{SUPABASE_URL}}/rest/v1/agenda_items?
  user_id=eq.{{user_id}}&
  start_at=gte.{{reference_date}}T00:00:00&
  start_at=lte.{{week_end}}T23:59:59&
  deleted_at=is.null&
  select=id
```
`week_end` = reference_date + 6 dias.

Para só obter o count: `Prefer: count=exact` + `Range: 0-0`.

---

## Workflows

### Workflow 1: Resumo Diário (manhã, 6h)

**Cron**: `0 6 * * *`

1. **Schedule Trigger** – 6:00
2. **HTTP Request** – Supabase RPC
   - URL: `{{SUPABASE_URL}}/rest/v1/rpc/get_premium_users_for_daily_push_with_count`
   - Method: POST
   - Headers: `apikey: {{SUPABASE_SERVICE_ROLE}}`, `Authorization: Bearer {{SUPABASE_SERVICE_ROLE}}`
   - Body: `{}`
3. **SplitInBatches** – batch size 50 (escalabilidade)
4. **Loop** sobre cada item do batch
5. Para cada item com `event_count > 0`:
   - Montar título: "Sua agenda de hoje"
   - Montar body: "{{event_count}} eventos programados"
   - **HTTP Request** – FCM
   - **HTTP Request** – INSERT user_notifications

---

### Workflow 2: Resumo Amanhã (fim do dia, 20h)

**Cron**: `0 20 * * *`

1. **Schedule Trigger** – 20:00
2. **HTTP Request** – Supabase RPC
   - URL: `{{SUPABASE_URL}}/rest/v1/rpc/get_premium_users_for_tomorrow_push_with_count`
   - (mesmos headers e body)
3. **SplitInBatches** – batch size 50
4. **Loop** – para cada item com `event_count > 0`:
   - Título: "Sua agenda de amanhã"
   - `data.type`: `tomorrow_summary`
   - `data.date`: `{{reference_date}}`

---

### Workflow 3: Resumo Semanal (domingo 18h)

**Cron**: `0 18 * * 0`

1. **Schedule Trigger** – domingo 18:00
2. **HTTP Request** – Supabase RPC
   - URL: `{{SUPABASE_URL}}/rest/v1/rpc/get_premium_users_for_weekly_push_with_count`
   - (mesmos headers e body)
3. **SplitInBatches** – batch size 50
4. **Loop** – para cada item com `event_count > 0`:
   - Título: "Sua semana"
   - `data.type`: `weekly_summary`
   - `data.date`: `{{reference_date}}` (segunda-feira)

---

## Exemplo de body FCM por workflow

**Diário:**
```json
{
  "to": "{{token}}",
  "notification": { "title": "Sua agenda de hoje", "body": "3 eventos programados" },
  "data": { "type": "daily_summary", "date": "2025-03-10" }
}
```

**Amanhã:**
```json
{
  "to": "{{token}}",
  "notification": { "title": "Sua agenda de amanhã", "body": "2 eventos programados" },
  "data": { "type": "tomorrow_summary", "date": "2025-03-11" }
}
```

**Semanal:**
```json
{
  "to": "{{token}}",
  "notification": { "title": "Sua semana", "body": "8 eventos programados" },
  "data": { "type": "weekly_summary", "date": "2025-03-10" }
}
```

---

## Escalabilidade

- **RPC JSON**: agregação prévia em `agenda_items` (uma varredura) em vez de subqueries correlacionadas
- **SplitInBatches**: processar em lotes de 50 usuários
- **RPCs com count**: evita N queries de agenda_items
- **Índice**: `idx_agenda_items_user_start_deleted` acelera as queries
- **Sem eventos = sem push**: reduz ruído e custo de FCM

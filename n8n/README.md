# Resumos por push (n8n)

Workflow "Smarte Agenda" no n8n da VPS (container `smart_agenda_n8n`).

| Gatilho (horário de Brasília) | Tipo | Título |
|---|---|---|
| Todo dia 07h | `daily_summary` | Sua agenda de hoje |
| Todo dia 20h | `tomorrow_summary` (desligado por padrão no app) | Sua agenda de amanhã |
| Domingo 20h | `weekly_summary` (semana seguinte) | Sua agenda da semana |

Fluxo: RPC `get_premium_users_for_push_json(push_type, date)` (migration 026,
só `service_role`) → só quem tem `event_count > 0` → FCM v1
(`projects/smart-agenda-a550b/messages:send`, credencial Google do n8n).

`smart_agenda_push_workflow.json` é o workflow exportado sem segredos: troque
`<SERVICE_ROLE_KEY>` pela chave service_role do Supabase antes de importar.

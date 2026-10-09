-- Resumos por push (n8n): a funcao ainda usava agenda_items.user_id, que nao
-- existe desde o modelo Familia (017) e quebrava toda execucao.
-- Agora:
-- - conta a agenda pessoal (owner_user_id) e a da Familia da pessoa;
-- - "Pro" e o mesmo criterio do app (private.user_has_active_pro);
-- - os limites do dia sao no horario de Brasilia (antes UTC: evento as 22h
--   caia no dia seguinte);
-- - ignora eventos cancelados.
-- Somente service_role executa (expoe tokens FCM).

DROP FUNCTION IF EXISTS public.get_premium_users_for_push_json(TEXT);
DROP FUNCTION IF EXISTS public.get_premium_users_for_daily_push();
DROP FUNCTION IF EXISTS public.get_premium_users_for_daily_push_with_count();
DROP FUNCTION IF EXISTS public.get_premium_users_for_tomorrow_push();
DROP FUNCTION IF EXISTS public.get_premium_users_for_tomorrow_push_with_count();
DROP FUNCTION IF EXISTS public.get_premium_users_for_weekly_push();
DROP FUNCTION IF EXISTS public.get_premium_users_for_weekly_push_with_count();

CREATE OR REPLACE FUNCTION public.get_premium_users_for_push_json(
  push_type TEXT,
  "date" DATE DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  tz CONSTANT TEXT := 'America/Sao_Paulo';
  base_date DATE;
  ref_date DATE;
  days INT := 1;
  range_start TIMESTAMPTZ;
  range_end TIMESTAMPTZ;
  result JSON;
BEGIN
  base_date := COALESCE("date", (now() AT TIME ZONE tz)::DATE);

  CASE push_type
    WHEN 'daily_summary' THEN
      ref_date := base_date;
    WHEN 'tomorrow_summary' THEN
      ref_date := base_date + 1;
    WHEN 'weekly_summary' THEN
      -- Domingo: semana seguinte (segunda); outros dias: semana atual.
      ref_date := CASE
        WHEN EXTRACT(DOW FROM base_date) = 0 THEN base_date + 1
        ELSE DATE_TRUNC('week', base_date)::DATE
      END;
      days := 7;
    ELSE
      RAISE EXCEPTION 'push_type invalido. Use: daily_summary, tomorrow_summary ou weekly_summary';
  END CASE;

  -- Meia-noite de Brasilia do dia de referencia ate a do dia seguinte.
  range_start := ref_date::TIMESTAMP AT TIME ZONE tz;
  range_end := (ref_date + days)::TIMESTAMP AT TIME ZONE tz;

  WITH recipients AS (
    SELECT DISTINCT t.user_id
    FROM user_fcm_tokens t
    LEFT JOIN user_push_preferences p ON p.user_id = t.user_id
    WHERE private.user_has_active_pro(t.user_id)
      AND CASE push_type
        WHEN 'daily_summary' THEN COALESCE(p.push_daily_summary, true)
        WHEN 'tomorrow_summary' THEN COALESCE(p.push_tomorrow_summary, false)
        ELSE COALESCE(p.push_weekly_summary, true)
      END
  ),
  counts AS (
    SELECT r.user_id, COUNT(ai.id)::BIGINT AS event_count
    FROM recipients r
    LEFT JOIN family_members fm ON fm.user_id = r.user_id
    LEFT JOIN agenda_items ai
      ON ai.deleted_at IS NULL
     AND ai.status IS DISTINCT FROM 'canceled'
     AND ai.start_at >= range_start
     AND ai.start_at < range_end
     AND (ai.owner_user_id = r.user_id
          OR (fm.family_id IS NOT NULL AND ai.family_id = fm.family_id))
    GROUP BY r.user_id
  )
  SELECT COALESCE(
    json_agg(json_build_object(
      'user_id', t.user_id::TEXT,
      'token', t.token,
      'platform', t.platform,
      'reference_date', ref_date::TEXT,
      'event_count', c.event_count
    )),
    '[]'::JSON
  ) INTO result
  FROM user_fcm_tokens t
  JOIN counts c ON c.user_id = t.user_id;

  RETURN result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_premium_users_for_push_json(TEXT, DATE)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_premium_users_for_push_json(TEXT, DATE)
  TO service_role;

NOTIFY pgrst, 'reload schema';

-- Resumos por push contam as ocorrencias de eventos que se repetem
-- (recurrence_json), com as mesmas regras do app (RecurrenceExpander):
-- todo dia / toda semana (dias escolhidos) / todo mes, intervalo, fim por data
-- ou quantidade, dias excluidos. Datas no horario de Brasilia.

CREATE OR REPLACE FUNCTION private.recurrence_occurs_on(
  p_start TIMESTAMPTZ,
  p_rule JSONB,
  p_day DATE,
  p_tz TEXT DEFAULT 'America/Sao_Paulo'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  first_day DATE := (p_start AT TIME ZONE p_tz)::DATE;
  kind TEXT := COALESCE(p_rule->>'type', 'none');
  step INT := GREATEST(COALESCE((p_rule->>'interval')::INT, 1), 1);
  until_day DATE := NULLIF(p_rule->>'until', '')::TIMESTAMP::DATE;
  max_count INT := (p_rule->>'count')::INT;
  days INT[];
  d DATE;
  ordinal INT := 0;
BEGIN
  IF p_day < first_day OR (until_day IS NOT NULL AND p_day > until_day) THEN
    RETURN FALSE;
  END IF;
  -- Dias excluidos ("excluir so este").
  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements_text(COALESCE(p_rule->'exceptions', '[]'))
    x WHERE x::TIMESTAMP::DATE = p_day
  ) THEN
    RETURN FALSE;
  END IF;

  IF kind = 'daily' THEN
    IF (p_day - first_day) % step <> 0 THEN RETURN FALSE; END IF;
  ELSIF kind = 'weekly' THEN
    SELECT COALESCE(array_agg(v::INT), ARRAY[EXTRACT(ISODOW FROM first_day)::INT])
      INTO days
      FROM jsonb_array_elements_text(COALESCE(p_rule->'byWeekDays', '[]')) v;
    IF days = '{}' THEN days := ARRAY[EXTRACT(ISODOW FROM first_day)::INT]; END IF;
    IF NOT (EXTRACT(ISODOW FROM p_day)::INT = ANY (days)) THEN RETURN FALSE; END IF;
    IF ((date_trunc('week', p_day)::DATE - date_trunc('week', first_day)::DATE) / 7) % step <> 0 THEN
      RETURN FALSE;
    END IF;
  ELSIF kind = 'monthly' THEN
    IF EXTRACT(DAY FROM p_day) <> EXTRACT(DAY FROM first_day) THEN RETURN FALSE; END IF;
    IF ((EXTRACT(YEAR FROM p_day) - EXTRACT(YEAR FROM first_day)) * 12
        + EXTRACT(MONTH FROM p_day) - EXTRACT(MONTH FROM first_day))::INT % step <> 0 THEN
      RETURN FALSE;
    END IF;
  ELSE
    RETURN p_day = first_day;
  END IF;

  -- Fim por quantidade: posicao do dia na serie (inclui excluidos).
  IF max_count IS NOT NULL THEN
    d := first_day;
    WHILE d <= p_day LOOP
      IF private.recurrence_occurs_on(p_start, p_rule - 'count' - 'exceptions', d, p_tz) THEN
        ordinal := ordinal + 1;
        IF ordinal > max_count THEN RETURN FALSE; END IF;
      END IF;
      d := d + 1;
    END LOOP;
  END IF;
  RETURN TRUE;
END;
$$;

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
      ref_date := CASE
        WHEN EXTRACT(DOW FROM base_date) = 0 THEN base_date + 1
        ELSE DATE_TRUNC('week', base_date)::DATE
      END;
      days := 7;
    ELSE
      RAISE EXCEPTION 'push_type invalido. Use: daily_summary, tomorrow_summary ou weekly_summary';
  END CASE;

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
  visible AS (
    -- Agenda pessoal + da Familia de cada destinatario, sem cancelados.
    SELECT r.user_id, ai.start_at, ai.recurrence_json
    FROM recipients r
    LEFT JOIN family_members fm ON fm.user_id = r.user_id
    JOIN agenda_items ai
      ON ai.deleted_at IS NULL
     AND ai.status IS DISTINCT FROM 'canceled'
     AND ai.start_at < range_end
     AND (ai.owner_user_id = r.user_id
          OR (fm.family_id IS NOT NULL AND ai.family_id = fm.family_id))
  ),
  per_item AS (
    SELECT v.user_id,
      CASE
        WHEN v.recurrence_json IS NULL
          OR COALESCE(v.recurrence_json::JSONB->>'type', 'none') = 'none'
        THEN (v.start_at >= range_start)::INT
        ELSE (
          SELECT COUNT(*) FROM generate_series(ref_date, ref_date + days - 1, '1 day') g
          WHERE private.recurrence_occurs_on(v.start_at, v.recurrence_json::JSONB, g::DATE, tz)
        )::INT
      END AS n
    FROM visible v
  ),
  counts AS (
    SELECT r.user_id, COALESCE(SUM(pi.n), 0)::BIGINT AS event_count
    FROM recipients r
    LEFT JOIN per_item pi ON pi.user_id = r.user_id
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

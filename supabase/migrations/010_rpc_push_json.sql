-- RPC que retorna JSON com usuarios premium/allowlist para push
-- Usa agregacao previa (event_counts) em vez de subqueries correlacionadas - escalavel

CREATE OR REPLACE FUNCTION public.get_premium_users_for_push_json(
  push_type TEXT,
  "date" DATE DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  ref_date DATE;
  base_date DATE;
  range_start TIMESTAMPTZ;
  range_end TIMESTAMPTZ;
  result JSON;
BEGIN
  -- date: data base (timezone do n8n). Se NULL, usa CURRENT_DATE do servidor (UTC).
  base_date := COALESCE("date", CURRENT_DATE);

  -- Define reference_date e range conforme o tipo
  CASE push_type
    WHEN 'daily_summary' THEN
      ref_date := base_date;
      range_start := ref_date::TIMESTAMPTZ;
      range_end := ref_date::TIMESTAMPTZ + INTERVAL '1 day' - INTERVAL '1 second';
    WHEN 'tomorrow_summary' THEN
      ref_date := base_date + 1;
      range_start := ref_date::TIMESTAMPTZ;
      range_end := ref_date::TIMESTAMPTZ + INTERVAL '1 day' - INTERVAL '1 second';
    WHEN 'weekly_summary' THEN
      ref_date := (
        CASE
          -- Se o envio ocorrer no domingo, aponta para a segunda da semana seguinte.
          WHEN EXTRACT(DOW FROM base_date) = 0 THEN (base_date + INTERVAL '1 day')::DATE
          ELSE (DATE_TRUNC('week', base_date))::DATE
        END
      );
      range_start := ref_date::TIMESTAMPTZ;
      range_end := (ref_date + INTERVAL '7 days' - INTERVAL '1 second')::TIMESTAMPTZ;
    ELSE
      RAISE EXCEPTION 'push_type invalido. Use: daily_summary, tomorrow_summary ou weekly_summary';
  END CASE;

  -- Agregacao previa: uma unica varredura de agenda_items (usa idx_agenda_items_user_start_deleted)
  WITH event_counts AS (
    SELECT
      ai.user_id,
      COUNT(*)::BIGINT AS event_count
    FROM agenda_items ai
    WHERE ai.deleted_at IS NULL
      AND ai.start_at >= range_start
      AND ai.start_at <= range_end
    GROUP BY ai.user_id
  ),
  premium_users AS (
    SELECT DISTINCT us.user_id
    FROM user_subscriptions us
    WHERE us.is_premium = true
      AND (us.expires_at IS NULL OR us.expires_at > now())
    UNION
    SELECT u.id
    FROM auth.users u
    INNER JOIN premium_allowlist pa ON LOWER(pa.email) = LOWER(u.email) AND pa.is_active = true
    WHERE NOT EXISTS (
      SELECT 1 FROM user_subscriptions us
      WHERE us.user_id = u.id AND us.is_premium = true
        AND (us.expires_at IS NULL OR us.expires_at > now())
    )
  ),
  users_with_pref AS (
    SELECT pu.user_id
    FROM premium_users pu
    LEFT JOIN user_push_preferences upp ON upp.user_id = pu.user_id
    WHERE
      (push_type = 'daily_summary' AND COALESCE(upp.push_daily_summary, true))
      OR (push_type = 'tomorrow_summary' AND COALESCE(upp.push_tomorrow_summary, false))
      OR (push_type = 'weekly_summary' AND COALESCE(upp.push_weekly_summary, true))
  ),
  base AS (
    SELECT uft.user_id, uft.token, uft.platform
    FROM user_fcm_tokens uft
    INNER JOIN users_with_pref uwp ON uwp.user_id = uft.user_id
  )
  SELECT COALESCE(
    json_agg(
      json_build_object(
        'user_id', b.user_id::TEXT,
        'token', b.token,
        'platform', b.platform,
        'reference_date', ref_date::TEXT,
        'event_count', COALESCE(ec.event_count, 0)
      )
    ),
    '[]'::JSON
  ) INTO result
  FROM base b
  LEFT JOIN event_counts ec ON ec.user_id = b.user_id;

  RETURN result;
END;
$$;

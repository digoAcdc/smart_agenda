-- Preferencias de push para usuarios premium (agenda do dia, amanha, semana)

CREATE TABLE user_push_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  push_daily_summary BOOLEAN NOT NULL DEFAULT true,
  push_tomorrow_summary BOOLEAN NOT NULL DEFAULT false,
  push_weekly_summary BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_user_push_preferences_daily ON user_push_preferences(user_id) WHERE push_daily_summary = true;
CREATE INDEX idx_user_push_preferences_tomorrow ON user_push_preferences(user_id) WHERE push_tomorrow_summary = true;
CREATE INDEX idx_user_push_preferences_weekly ON user_push_preferences(user_id) WHERE push_weekly_summary = true;

ALTER TABLE user_push_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own push preferences"
  ON user_push_preferences FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Indice para queries de agenda por usuario + range de data (escalabilidade)
CREATE INDEX idx_agenda_items_user_start_deleted
  ON agenda_items(user_id, start_at)
  WHERE deleted_at IS NULL;

-- RPC: usuarios premium/allowlist com push_daily_summary habilitado
CREATE OR REPLACE FUNCTION public.get_premium_users_for_daily_push()
RETURNS TABLE (user_id UUID, token TEXT, platform TEXT, reference_date DATE)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  ref_date DATE := CURRENT_DATE;
BEGIN
  RETURN QUERY
  WITH premium_users AS (
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
    WHERE COALESCE(upp.push_daily_summary, true) = true
  )
  SELECT
    uft.user_id,
    uft.token,
    uft.platform,
    ref_date
  FROM user_fcm_tokens uft
  INNER JOIN users_with_pref uwp ON uwp.user_id = uft.user_id;
END;
$$;

-- RPC: usuarios premium/allowlist com push_tomorrow_summary habilitado
CREATE OR REPLACE FUNCTION public.get_premium_users_for_tomorrow_push()
RETURNS TABLE (user_id UUID, token TEXT, platform TEXT, reference_date DATE)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  ref_date DATE := CURRENT_DATE + INTERVAL '1 day';
BEGIN
  RETURN QUERY
  WITH premium_users AS (
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
    WHERE COALESCE(upp.push_tomorrow_summary, false) = true
  )
  SELECT
    uft.user_id,
    uft.token,
    uft.platform,
    ref_date::DATE
  FROM user_fcm_tokens uft
  INNER JOIN users_with_pref uwp ON uwp.user_id = uft.user_id;
END;
$$;

-- RPC: usuarios premium/allowlist com push_weekly_summary habilitado
-- reference_date = segunda-feira da semana atual
CREATE OR REPLACE FUNCTION public.get_premium_users_for_weekly_push()
RETURNS TABLE (user_id UUID, token TEXT, platform TEXT, reference_date DATE)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  ref_date DATE := (DATE_TRUNC('week', CURRENT_DATE))::DATE;
BEGIN
  RETURN QUERY
  WITH premium_users AS (
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
    WHERE COALESCE(upp.push_weekly_summary, true) = true
  )
  SELECT
    uft.user_id,
    uft.token,
    uft.platform,
    ref_date
  FROM user_fcm_tokens uft
  INNER JOIN users_with_pref uwp ON uwp.user_id = uft.user_id;
END;
$$;

-- RPC com count de eventos (evita N queries no n8n)
CREATE OR REPLACE FUNCTION public.get_premium_users_for_daily_push_with_count()
RETURNS TABLE (user_id UUID, token TEXT, platform TEXT, reference_date DATE, event_count BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  ref_date DATE := CURRENT_DATE;
  day_start TIMESTAMPTZ := ref_date::TIMESTAMPTZ;
  day_end TIMESTAMPTZ := ref_date::TIMESTAMPTZ + INTERVAL '1 day' - INTERVAL '1 second';
BEGIN
  RETURN QUERY
  WITH premium_users AS (
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
    WHERE COALESCE(upp.push_daily_summary, true) = true
  ),
  base AS (
    SELECT uft.user_id, uft.token, uft.platform
    FROM user_fcm_tokens uft
    INNER JOIN users_with_pref uwp ON uwp.user_id = uft.user_id
  )
  SELECT
    b.user_id,
    b.token,
    b.platform,
    ref_date,
    (SELECT COUNT(*)::BIGINT FROM agenda_items ai
     WHERE ai.user_id = b.user_id
       AND ai.deleted_at IS NULL
       AND ai.start_at >= day_start
       AND ai.start_at <= day_end)
  FROM base b;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_premium_users_for_tomorrow_push_with_count()
RETURNS TABLE (user_id UUID, token TEXT, platform TEXT, reference_date DATE, event_count BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  ref_date DATE := CURRENT_DATE + INTERVAL '1 day';
  day_start TIMESTAMPTZ := ref_date::TIMESTAMPTZ;
  day_end TIMESTAMPTZ := ref_date::TIMESTAMPTZ + INTERVAL '1 day' - INTERVAL '1 second';
BEGIN
  RETURN QUERY
  WITH premium_users AS (
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
    WHERE COALESCE(upp.push_tomorrow_summary, false) = true
  ),
  base AS (
    SELECT uft.user_id, uft.token, uft.platform
    FROM user_fcm_tokens uft
    INNER JOIN users_with_pref uwp ON uwp.user_id = uft.user_id
  )
  SELECT
    b.user_id,
    b.token,
    b.platform,
    ref_date,
    (SELECT COUNT(*)::BIGINT FROM agenda_items ai
     WHERE ai.user_id = b.user_id
       AND ai.deleted_at IS NULL
       AND ai.start_at >= day_start
       AND ai.start_at <= day_end)
  FROM base b;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_premium_users_for_weekly_push_with_count()
RETURNS TABLE (user_id UUID, token TEXT, platform TEXT, reference_date DATE, event_count BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  ref_date DATE := (DATE_TRUNC('week', CURRENT_DATE))::DATE;
  week_start TIMESTAMPTZ;
  week_end TIMESTAMPTZ;
BEGIN
  week_start := ref_date::TIMESTAMPTZ;
  week_end := (ref_date + INTERVAL '7 days' - INTERVAL '1 second')::TIMESTAMPTZ;

  RETURN QUERY
  WITH premium_users AS (
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
    WHERE COALESCE(upp.push_weekly_summary, true) = true
  ),
  base AS (
    SELECT uft.user_id, uft.token, uft.platform
    FROM user_fcm_tokens uft
    INNER JOIN users_with_pref uwp ON uwp.user_id = uft.user_id
  )
  SELECT
    b.user_id,
    b.token,
    b.platform,
    ref_date,
    (SELECT COUNT(*)::BIGINT FROM agenda_items ai
     WHERE ai.user_id = b.user_id
       AND ai.deleted_at IS NULL
       AND ai.start_at >= week_start
       AND ai.start_at <= week_end)
  FROM base b;
END;
$$;

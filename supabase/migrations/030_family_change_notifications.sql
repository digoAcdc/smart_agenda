-- Avisos da Familia na hora (Fase 2 do roadmap).
-- Criar/alterar/cancelar/excluir evento da Familia entra numa fila (uma linha
-- por evento). Edicoes seguidas atualizam a mesma linha e empurram o envio
-- 90 s para frente: viram um aviso so. O n8n chama
-- take_due_family_notifications() a cada minuto e envia pelo FCM.

ALTER TABLE public.user_push_preferences
  ADD COLUMN IF NOT EXISTS push_family_changes BOOLEAN NOT NULL DEFAULT true;

CREATE TABLE IF NOT EXISTS private.family_change_queue (
  item_id TEXT PRIMARY KEY,
  family_id UUID NOT NULL,
  actor_id UUID,
  action TEXT NOT NULL CHECK (action IN ('created', 'updated', 'canceled', 'deleted')),
  title TEXT NOT NULL,
  start_at TIMESTAMPTZ NOT NULL,
  all_day BOOLEAN NOT NULL DEFAULT false,
  assignee_user_id UUID,
  due_at TIMESTAMPTZ NOT NULL
);

CREATE OR REPLACE FUNCTION private.try_jsonb(p TEXT)
RETURNS JSONB LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
  RETURN p::JSONB;
EXCEPTION WHEN others THEN
  RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION private.queue_family_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  act TEXT;
  actor UUID := COALESCE(auth.uid(), NEW.updated_by, NEW.created_by);
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.deleted_at IS NOT NULL THEN RETURN NEW; END IF;
    act := 'created';
  ELSIF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    act := 'deleted';
  ELSIF NEW.deleted_at IS NOT NULL THEN
    RETURN NEW;
  ELSIF NEW.status = 'canceled' AND OLD.status IS DISTINCT FROM 'canceled' THEN
    act := 'canceled';
  ELSIF (NEW.title, NEW.start_at, NEW.end_at, NEW.all_day, NEW.description,
         NEW.location_text, NEW.assignee_type, NEW.assignee_user_id,
         NEW.subject_type, NEW.subject_child_id, NEW.subject_user_id)
        IS DISTINCT FROM
        (OLD.title, OLD.start_at, OLD.end_at, OLD.all_day, OLD.description,
         OLD.location_text, OLD.assignee_type, OLD.assignee_user_id,
         OLD.subject_type, OLD.subject_child_id, OLD.subject_user_id)
     -- Repeticao mudou (concluir um dia da serie nao conta como alteracao).
     OR (COALESCE(private.try_jsonb(NEW.recurrence_json), '{}') - 'completedDates')
        IS DISTINCT FROM
        (COALESCE(private.try_jsonb(OLD.recurrence_json), '{}') - 'completedDates')
  THEN
    act := 'updated';
  ELSE
    RETURN NEW;  -- concluir, sincronizacao sem mudanca etc.
  END IF;

  -- Criado e apagado antes do aviso sair: ninguem precisa saber.
  IF act = 'deleted' AND EXISTS (
    SELECT 1 FROM private.family_change_queue q
    WHERE q.item_id = NEW.id AND q.action = 'created'
  ) THEN
    DELETE FROM private.family_change_queue WHERE item_id = NEW.id;
    RETURN NEW;
  END IF;

  INSERT INTO private.family_change_queue AS q
    (item_id, family_id, actor_id, action, title, start_at, all_day, assignee_user_id, due_at)
  VALUES
    (NEW.id, NEW.family_id, actor, act, NEW.title, NEW.start_at, NEW.all_day,
     NEW.assignee_user_id, now() + interval '90 seconds')
  ON CONFLICT (item_id) DO UPDATE SET
    -- Criado e editado em seguida continua sendo "adicionou".
    action = CASE WHEN q.action = 'created' AND EXCLUDED.action = 'updated'
                  THEN 'created' ELSE EXCLUDED.action END,
    actor_id = EXCLUDED.actor_id,
    title = EXCLUDED.title,
    start_at = EXCLUDED.start_at,
    all_day = EXCLUDED.all_day,
    assignee_user_id = EXCLUDED.assignee_user_id,
    due_at = EXCLUDED.due_at;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS agenda_items_family_change ON public.agenda_items;
CREATE TRIGGER agenda_items_family_change
  AFTER INSERT OR UPDATE ON public.agenda_items
  FOR EACH ROW
  WHEN (NEW.family_id IS NOT NULL)
  EXECUTE FUNCTION private.queue_family_change();

-- Retira da fila o que ja passou do tempo e devolve uma mensagem por aparelho
-- de cada outro membro da Familia (quem fez a mudanca nao recebe).
CREATE OR REPLACE FUNCTION public.take_due_family_notifications()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  tz CONSTANT TEXT := 'America/Sao_Paulo';
  result JSON;
BEGIN
  WITH due AS (
    DELETE FROM private.family_change_queue
    WHERE due_at <= now()
    RETURNING *
  ),
  msgs AS (
    SELECT
      t.token,
      d.item_id,
      d.family_id,
      COALESCE(NULLIF(am.nickname, ''), NULLIF(p.display_name, ''),
               NULLIF(split_part(u.email, '@', 1), ''), 'Alguém')
        || CASE d.action
             WHEN 'created' THEN ' adicionou: '
             WHEN 'updated' THEN ' alterou: '
             WHEN 'canceled' THEN ' cancelou: '
             ELSE ' excluiu: '
           END
        || d.title AS title,
      CASE WHEN fm.user_id = d.assignee_user_id AND d.action IN ('created', 'updated')
           THEN 'Você é o responsável · ' ELSE '' END
        || (ARRAY['dom','seg','ter','qua','qui','sex','sáb'])
             [EXTRACT(DOW FROM d.start_at AT TIME ZONE tz)::INT + 1]
        || ', ' || to_char(d.start_at AT TIME ZONE tz, 'DD/MM')
        || CASE WHEN d.all_day THEN ' (dia todo)'
                ELSE ' às ' || to_char(d.start_at AT TIME ZONE tz, 'HH24:MI') END
        AS body
    FROM due d
    JOIN family_members fm ON fm.family_id = d.family_id
    JOIN user_fcm_tokens t ON t.user_id = fm.user_id
    LEFT JOIN user_push_preferences pp ON pp.user_id = fm.user_id
    LEFT JOIN family_members am ON am.family_id = d.family_id AND am.user_id = d.actor_id
    LEFT JOIN profiles p ON p.id = d.actor_id
    LEFT JOIN auth.users u ON u.id = d.actor_id
    WHERE fm.user_id IS DISTINCT FROM d.actor_id
      AND COALESCE(pp.push_family_changes, true)
      AND private.family_is_active(d.family_id)
  )
  SELECT COALESCE(json_agg(json_build_object(
    'token', token, 'title', title, 'body', body,
    'item_id', item_id, 'family_id', family_id
  )), '[]'::JSON) INTO result
  FROM msgs;
  RETURN result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.take_due_family_notifications() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.take_due_family_notifications() TO service_role;

NOTIFY pgrst, 'reload schema';

-- Fase 3 do roadmap (escola).
-- Provas e trabalhos: novos tipos de evento, com a materia em school_subject.
-- Mochila de amanha: "o que levar" por materia, na grade (bring_json:
-- {"Ed. Fisica": "tenis e uniforme"}). O aviso das 20h e gerado no aparelho.

ALTER TYPE public.agenda_item_kind ADD VALUE IF NOT EXISTS 'exam';
ALTER TYPE public.agenda_item_kind ADD VALUE IF NOT EXISTS 'assignment';

ALTER TABLE public.agenda_items ADD COLUMN IF NOT EXISTS school_subject TEXT;
ALTER TABLE public.class_schedules ADD COLUMN IF NOT EXISTS bring_json TEXT;

-- Avisos da Familia: trocar a materia tambem conta como alteracao.
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
         NEW.subject_type, NEW.subject_child_id, NEW.subject_user_id, NEW.school_subject)
        IS DISTINCT FROM
        (OLD.title, OLD.start_at, OLD.end_at, OLD.all_day, OLD.description,
         OLD.location_text, OLD.assignee_type, OLD.assignee_user_id,
         OLD.subject_type, OLD.subject_child_id, OLD.subject_user_id, OLD.school_subject)
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

NOTIFY pgrst, 'reload schema';

-- Quem esta numa Familia compartilha tudo, inclusive grades sem filho.
-- Grade/aula da Familia: family_id obrigatorio, child_id opcional.

ALTER TABLE public.class_schedules
  DROP CONSTRAINT class_schedules_scope,
  ADD CONSTRAINT class_schedules_scope CHECK (
    (owner_user_id IS NOT NULL AND family_id IS NULL AND child_id IS NULL)
    OR (owner_user_id IS NULL AND family_id IS NOT NULL)
  );

ALTER TABLE public.class_schedule_slots
  DROP CONSTRAINT class_schedule_slots_scope,
  ADD CONSTRAINT class_schedule_slots_scope CHECK (
    (user_id IS NOT NULL AND family_id IS NULL AND child_id IS NULL)
    OR (user_id IS NULL AND family_id IS NOT NULL)
  );

CREATE OR REPLACE FUNCTION private.guard_class_schedule()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_by := COALESCE(auth.uid(), NEW.created_by);
    NEW.created_at := COALESCE(NEW.created_at, now());
    IF NEW.child_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM family_children c WHERE c.id = NEW.child_id AND c.family_id = NEW.family_id
    ) THEN
      RAISE EXCEPTION 'Filho nao pertence a esta familia' USING ERRCODE = '23514';
    END IF;
  ELSE
    NEW.family_id := OLD.family_id;
    NEW.owner_user_id := OLD.owner_user_id;
    NEW.child_id := OLD.child_id;
    NEW.created_by := OLD.created_by;
    NEW.created_at := OLD.created_at;
  END IF;
  NEW.updated_by := COALESCE(auth.uid(), NEW.updated_by);
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION private.guard_class_schedule_slot()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_by := COALESCE(auth.uid(), NEW.created_by);
    NEW.created_at := COALESCE(NEW.created_at, now());
  ELSE
    NEW.user_id := OLD.user_id;
    NEW.family_id := OLD.family_id;
    NEW.child_id := OLD.child_id;
    NEW.created_by := OLD.created_by;
    NEW.created_at := OLD.created_at;
  END IF;
  NEW.updated_by := COALESCE(auth.uid(), NEW.updated_by);
  NEW.updated_at := now();

  IF NEW.family_id IS NOT NULL AND NEW.child_id IS NOT NULL AND TG_OP = 'INSERT'
     AND NOT EXISTS (SELECT 1 FROM family_children c
                     WHERE c.id = NEW.child_id AND c.family_id = NEW.family_id) THEN
    RAISE EXCEPTION 'Filho nao pertence a esta familia' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

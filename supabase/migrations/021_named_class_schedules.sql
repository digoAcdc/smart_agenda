-- Varias grades com nome. Grade com filho e da Familia (compartilhada);
-- grade sem filho e pessoal (so o dono ve). Cada aula pertence a uma grade.

CREATE TABLE public.class_schedules (
  id TEXT PRIMARY KEY,
  family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
  owner_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  child_id UUID REFERENCES public.family_children(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (char_length(btrim(name)) BETWEEN 1 AND 60),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT class_schedules_scope CHECK (
    (owner_user_id IS NOT NULL AND family_id IS NULL AND child_id IS NULL)
    OR (owner_user_id IS NULL AND family_id IS NOT NULL AND child_id IS NOT NULL)
  )
);

CREATE INDEX class_schedules_family_updated_idx
  ON public.class_schedules(family_id, updated_at) WHERE family_id IS NOT NULL;
CREATE INDEX class_schedules_owner_idx
  ON public.class_schedules(owner_user_id) WHERE owner_user_id IS NOT NULL;

ALTER TABLE public.class_schedule_slots
  ADD COLUMN schedule_id TEXT REFERENCES public.class_schedules(id) ON DELETE CASCADE;
CREATE INDEX class_schedule_slots_schedule_idx ON public.class_schedule_slots(schedule_id);

-- Grades de filho ja existentes viram a grade "Escola" de cada filho
-- (id deterministico, o app faz o mesmo no banco local).
INSERT INTO public.class_schedules (id, family_id, child_id, name)
SELECT DISTINCT 'legacy-' || s.child_id, s.family_id, s.child_id, 'Escola'
FROM public.class_schedule_slots s
WHERE s.family_id IS NOT NULL
ON CONFLICT (id) DO NOTHING;

UPDATE public.class_schedule_slots
SET schedule_id = 'legacy-' || child_id
WHERE family_id IS NOT NULL AND schedule_id IS NULL;

-- Autoria, escopo imutavel, filho da mesma Familia, cursor no servidor.
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
    IF NEW.family_id IS NOT NULL AND NOT EXISTS (
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

CREATE TRIGGER class_schedules_guard BEFORE INSERT OR UPDATE ON public.class_schedules
  FOR EACH ROW EXECUTE FUNCTION private.guard_class_schedule();

-- A aula precisa estar no mesmo escopo da sua grade.
CREATE OR REPLACE FUNCTION private.guard_slot_schedule()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  g class_schedules%ROWTYPE;
BEGIN
  IF NEW.schedule_id IS NULL THEN RETURN NEW; END IF;
  IF TG_OP = 'UPDATE' AND NEW.schedule_id IS NOT DISTINCT FROM OLD.schedule_id THEN RETURN NEW; END IF;
  SELECT * INTO g FROM class_schedules WHERE id = NEW.schedule_id;
  IF NOT FOUND
     OR g.family_id IS DISTINCT FROM NEW.family_id
     OR g.child_id IS DISTINCT FROM NEW.child_id
     OR g.owner_user_id IS DISTINCT FROM NEW.user_id THEN
    RAISE EXCEPTION 'Aula fora do escopo da grade' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER class_schedule_slots_schedule_guard BEFORE INSERT OR UPDATE ON public.class_schedule_slots
  FOR EACH ROW EXECUTE FUNCTION private.guard_slot_schedule();

ALTER TABLE public.class_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY class_schedules_personal ON public.class_schedules FOR ALL TO authenticated
  USING (owner_user_id = auth.uid())
  WITH CHECK (owner_user_id = auth.uid());
CREATE POLICY class_schedules_family_select ON public.class_schedules FOR SELECT TO authenticated
  USING (family_id IS NOT NULL AND private.is_family_member(family_id));
CREATE POLICY class_schedules_family_insert ON public.class_schedules FOR INSERT TO authenticated
  WITH CHECK (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id));
CREATE POLICY class_schedules_family_update ON public.class_schedules FOR UPDATE TO authenticated
  USING (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id))
  WITH CHECK (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id));

ALTER PUBLICATION supabase_realtime ADD TABLE public.class_schedules;

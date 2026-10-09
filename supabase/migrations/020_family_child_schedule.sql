-- Grade horaria por filho, compartilhada com a Familia.
-- Linhas pessoais: user_id (como antes). Linhas de filho: family_id + child_id.
-- Familia: membros leem; admin/editor de Familia ativa editam; exclusao logica.

ALTER TABLE public.class_schedule_slots
  ALTER COLUMN user_id DROP NOT NULL,
  ALTER COLUMN created_at SET DEFAULT now(),
  ALTER COLUMN updated_at SET DEFAULT now(),
  ADD COLUMN family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
  ADD COLUMN child_id UUID REFERENCES public.family_children(id) ON DELETE CASCADE,
  ADD COLUMN created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN deleted_at TIMESTAMPTZ,
  ADD CONSTRAINT class_schedule_slots_scope CHECK (
    (user_id IS NOT NULL AND family_id IS NULL AND child_id IS NULL)
    OR (user_id IS NULL AND family_id IS NOT NULL AND child_id IS NOT NULL)
  );

CREATE INDEX class_schedule_slots_family_updated_idx
  ON public.class_schedule_slots(family_id, updated_at) WHERE family_id IS NOT NULL;

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
  -- Cursor de sincronizacao definido pelo servidor.
  NEW.updated_at := now();

  IF NEW.family_id IS NOT NULL AND TG_OP = 'INSERT'
     AND NOT EXISTS (SELECT 1 FROM family_children c
                     WHERE c.id = NEW.child_id AND c.family_id = NEW.family_id) THEN
    RAISE EXCEPTION 'Filho nao pertence a esta familia' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER class_schedule_slots_guard BEFORE INSERT OR UPDATE ON public.class_schedule_slots
  FOR EACH ROW EXECUTE FUNCTION private.guard_class_schedule_slot();

-- Policy antiga (FOR ALL por user_id) continua valendo para a grade pessoal.
CREATE POLICY class_schedule_slots_family_select ON public.class_schedule_slots
  FOR SELECT TO authenticated
  USING (family_id IS NOT NULL AND private.is_family_member(family_id));
CREATE POLICY class_schedule_slots_family_insert ON public.class_schedule_slots
  FOR INSERT TO authenticated
  WITH CHECK (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id));
CREATE POLICY class_schedule_slots_family_update ON public.class_schedule_slots
  FOR UPDATE TO authenticated
  USING (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id))
  WITH CHECK (family_id IS NOT NULL AND private.can_edit_family_agenda(family_id));

ALTER PUBLICATION supabase_realtime ADD TABLE public.class_schedule_slots;

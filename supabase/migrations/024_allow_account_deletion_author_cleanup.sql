-- Excluir conta falhava: ON DELETE SET NULL em created_by era desfeito pelos
-- guards (que fixam o autor em UPDATE) e o banco recusava apagar o usuario.
-- O autor continua imutavel para usuarios do app (auth.uid() presente);
-- acoes do proprio banco (cascata, sem auth.uid()) podem anula-lo.

CREATE OR REPLACE FUNCTION private.guard_agenda_group()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_by := COALESCE(auth.uid(), NEW.created_by);
  ELSE
    NEW.family_id := OLD.family_id;
    NEW.owner_user_id := OLD.owner_user_id;
    IF auth.uid() IS NOT NULL THEN NEW.created_by := OLD.created_by; END IF;
    NEW.created_at := OLD.created_at;
  END IF;
  NEW.updated_by := COALESCE(auth.uid(), NEW.updated_by);
  NEW.updated_at := now();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION private.guard_agenda_item()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_by := COALESCE(auth.uid(), NEW.created_by);
    NEW.created_at := COALESCE(NEW.created_at, now());
  ELSE
    NEW.family_id := OLD.family_id;
    NEW.owner_user_id := OLD.owner_user_id;
    IF auth.uid() IS NOT NULL THEN NEW.created_by := OLD.created_by; END IF;
    NEW.created_at := OLD.created_at;
  END IF;
  NEW.updated_by := COALESCE(auth.uid(), NEW.updated_by);
  NEW.updated_at := now();

  -- Referencias anuladas por exclusao de usuario/filho viram "nenhum".
  IF NEW.subject_type = 'child' AND NEW.subject_child_id IS NULL THEN NEW.subject_type := 'none'; END IF;
  IF NEW.subject_type = 'member' AND NEW.subject_user_id IS NULL THEN NEW.subject_type := 'none'; END IF;
  IF NEW.assignee_type = 'member' AND NEW.assignee_user_id IS NULL THEN NEW.assignee_type := 'none'; END IF;
  IF NEW.subject_type <> 'child' THEN NEW.subject_child_id := NULL; END IF;
  IF NEW.subject_type <> 'member' THEN NEW.subject_user_id := NULL; END IF;
  IF NEW.assignee_type <> 'member' THEN NEW.assignee_user_id := NULL; END IF;

  IF NEW.family_id IS NULL THEN
    -- Agenda pessoal: sem filho/membro/responsavel.
    NEW.subject_type := 'none';
    NEW.assignee_type := 'none';
  ELSE
    IF NEW.subject_child_id IS NOT NULL
       AND (TG_OP = 'INSERT' OR NEW.subject_child_id IS DISTINCT FROM OLD.subject_child_id)
       AND NOT EXISTS (SELECT 1 FROM family_children c
                       WHERE c.id = NEW.subject_child_id AND c.family_id = NEW.family_id) THEN
      RAISE EXCEPTION 'Filho nao pertence a esta familia' USING ERRCODE = '23514';
    END IF;
    IF NEW.subject_user_id IS NOT NULL
       AND (TG_OP = 'INSERT' OR NEW.subject_user_id IS DISTINCT FROM OLD.subject_user_id)
       AND NOT EXISTS (SELECT 1 FROM family_members m
                       WHERE m.user_id = NEW.subject_user_id AND m.family_id = NEW.family_id) THEN
      RAISE EXCEPTION 'Pessoa nao e membro desta familia' USING ERRCODE = '23514';
    END IF;
    IF NEW.assignee_user_id IS NOT NULL
       AND (TG_OP = 'INSERT' OR NEW.assignee_user_id IS DISTINCT FROM OLD.assignee_user_id)
       AND NOT EXISTS (SELECT 1 FROM family_members m
                       WHERE m.user_id = NEW.assignee_user_id AND m.family_id = NEW.family_id) THEN
      RAISE EXCEPTION 'Responsavel nao e membro desta familia' USING ERRCODE = '23514';
    END IF;
  END IF;

  IF NEW.group_id IS NOT NULL
     AND (TG_OP = 'INSERT' OR NEW.group_id IS DISTINCT FROM OLD.group_id)
     AND NOT EXISTS (SELECT 1 FROM agenda_groups g
                     WHERE g.id = NEW.group_id
                       AND g.family_id IS NOT DISTINCT FROM NEW.family_id
                       AND g.owner_user_id IS NOT DISTINCT FROM NEW.owner_user_id) THEN
    RAISE EXCEPTION 'Categoria de outro escopo' USING ERRCODE = '23514';
  END IF;

  IF NEW.status = 'done' AND (TG_OP = 'INSERT' OR OLD.status <> 'done') THEN
    NEW.completed_at := now();
    NEW.completed_by := auth.uid();
  ELSIF NEW.status <> 'done' THEN
    NEW.completed_at := NULL;
    NEW.completed_by := NULL;
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION private.guard_class_schedule()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    IF auth.uid() IS NOT NULL THEN NEW.created_by := OLD.created_by; END IF;
    NEW.created_at := OLD.created_at;
  END IF;
  NEW.updated_by := COALESCE(auth.uid(), NEW.updated_by);
  NEW.updated_at := now();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION private.guard_class_schedule_slot()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_by := COALESCE(auth.uid(), NEW.created_by);
    NEW.created_at := COALESCE(NEW.created_at, now());
  ELSE
    NEW.user_id := OLD.user_id;
    NEW.family_id := OLD.family_id;
    NEW.child_id := OLD.child_id;
    IF auth.uid() IS NOT NULL THEN NEW.created_by := OLD.created_by; END IF;
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
$function$
;

CREATE OR REPLACE FUNCTION private.guard_family_child()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_by := COALESCE(auth.uid(), NEW.created_by);
  ELSE
    NEW.family_id := OLD.family_id;
    IF auth.uid() IS NOT NULL THEN NEW.created_by := OLD.created_by; END IF;
    NEW.created_at := OLD.created_at;
  END IF;
  RETURN NEW;
END;
$function$
;


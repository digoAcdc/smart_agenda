-- Nuvem pessoal (anotacoes, turmas, alunos, grade pessoal) e recurso Pro.
-- O app so sincroniza com Pro, mas o banco aceitava gravacao de qualquer
-- usuario logado (bastava chamar a API). Agora:
-- - ler e apagar o que e seu: sempre (Pro vencido nao perde nada);
-- - criar/alterar na nuvem: so com Pro ativo.

DO $$
DECLARE
  spec RECORD;
BEGIN
  FOR spec IN
    SELECT * FROM (VALUES
      ('notes', 'Users can manage own notes', 'user_id'),
      ('class_groups', 'Users can manage own class_groups', 'user_id'),
      ('students', 'Users can manage own students', 'user_id'),
      ('class_schedule_slots', 'Users can manage own slots', 'user_id'),
      ('class_schedules', 'class_schedules_personal', 'owner_user_id')
    ) AS t(tbl, old_policy, owner_col)
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', spec.old_policy, spec.tbl);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', spec.tbl || '_own_select', spec.tbl);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', spec.tbl || '_own_delete', spec.tbl);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', spec.tbl || '_own_insert_pro', spec.tbl);
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', spec.tbl || '_own_update_pro', spec.tbl);

    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR SELECT USING (%I = auth.uid())',
      spec.tbl || '_own_select', spec.tbl, spec.owner_col);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR DELETE USING (%I = auth.uid())',
      spec.tbl || '_own_delete', spec.tbl, spec.owner_col);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR INSERT WITH CHECK (%I = auth.uid() AND private.user_has_active_pro(auth.uid()))',
      spec.tbl || '_own_insert_pro', spec.tbl, spec.owner_col);
    EXECUTE format(
      'CREATE POLICY %I ON public.%I FOR UPDATE USING (%I = auth.uid()) WITH CHECK (%I = auth.uid() AND private.user_has_active_pro(auth.uid()))',
      spec.tbl || '_own_update_pro', spec.tbl, spec.owner_col, spec.owner_col);
  END LOOP;
END $$;

NOTIFY pgrst, 'reload schema';

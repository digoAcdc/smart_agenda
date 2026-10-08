-- "Apagar todos os dados": o dono pode excluir definitivamente a propria agenda pessoal.
-- Itens e categorias da Familia continuam sem DELETE (exclusao logica entre membros).

CREATE POLICY agenda_items_delete_own_personal ON public.agenda_items FOR DELETE TO authenticated
  USING (owner_user_id = auth.uid());

CREATE POLICY agenda_groups_delete_own_personal ON public.agenda_groups FOR DELETE TO authenticated
  USING (owner_user_id = auth.uid());

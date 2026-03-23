-- Permite que o destinatario remova o vinculo de compartilhamento (apagamento de dados / LGPD).
-- A policy existente do dono continua valendo; policies de DELETE sao combinadas com OR.

CREATE POLICY "Recipient can delete shared link with them"
  ON public.agenda_shares
  FOR DELETE
  TO authenticated
  USING (auth.uid() = shared_with_id);

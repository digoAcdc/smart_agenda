-- Ate 5 anexos por evento (o app tambem limita). Protege o armazenamento
-- contra uso abusivo por quem chama a API direto.

CREATE OR REPLACE FUNCTION private.enforce_attachments_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF (SELECT COUNT(*) FROM public.attachments WHERE item_id = NEW.item_id) >= 5 THEN
    RAISE EXCEPTION 'Limite de 5 anexos por evento' USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS attachments_limit ON public.attachments;
CREATE TRIGGER attachments_limit
  BEFORE INSERT ON public.attachments
  FOR EACH ROW EXECUTE FUNCTION private.enforce_attachments_limit();

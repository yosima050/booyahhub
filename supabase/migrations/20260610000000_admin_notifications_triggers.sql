-- Trigger function to notify admin on successful registration
CREATE OR REPLACE FUNCTION public.fn_notify_admin_on_registration()
RETURNS TRIGGER AS $$
DECLARE
  v_admin_id BIGINT;
  v_scrim_title TEXT;
BEGIN
  -- We only notify when the registration status transitions to 'verified'
  IF NEW.status = 'verified' AND (OLD IS NULL OR OLD.status IS DISTINCT FROM 'verified') THEN
    -- Get the admin_id and title of the scrim
    SELECT admin_id, title INTO v_admin_id, v_scrim_title
    FROM public.scrims
    WHERE id = NEW.scrim_id;

    IF v_admin_id IS NOT NULL THEN
      INSERT INTO public.notifications (user_id, type, title, message, scrim_id)
      VALUES (
        v_admin_id,
        'announcement'::public.notif_type,
        'Pendaftaran Baru',
        format('Tim %s telah mendaftar di scrim %s Anda.', NEW.team_name, v_scrim_title),
        NEW.scrim_id
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_admin_on_registration ON public.registrations;

CREATE TRIGGER trg_notify_admin_on_registration
  AFTER INSERT OR UPDATE OF status
  ON public.registrations
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_notify_admin_on_registration();

-- Trigger function to notify admin when scrim is full
CREATE OR REPLACE FUNCTION public.fn_notify_admin_on_scrim_full()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.slot_filled >= NEW.slot_total AND (OLD IS NULL OR OLD.slot_filled < NEW.slot_filled) THEN
    INSERT INTO public.notifications (user_id, type, title, message, scrim_id)
    VALUES (
      NEW.admin_id,
      'announcement'::public.notif_type,
      'Scrim Penuh',
      format('Scrim %s Anda telah penuh (%s/%s slot).', NEW.title, NEW.slot_filled, NEW.slot_total),
      NEW.id
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_admin_on_scrim_full ON public.scrims;

CREATE TRIGGER trg_notify_admin_on_scrim_full
  AFTER UPDATE OF slot_filled
  ON public.scrims
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_notify_admin_on_scrim_full();

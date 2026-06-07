-- Create trigger function to automatically update public.scrims.slot_filled
-- when registrations are inserted, updated, or deleted.
CREATE OR REPLACE FUNCTION public.fn_update_scrim_slot_filled()
RETURNS TRIGGER AS $$
DECLARE
  v_scrim_id BIGINT;
  v_count INT;
BEGIN
  -- Determine the scrim_id to update
  IF TG_OP = 'DELETE' THEN
    v_scrim_id := OLD.scrim_id;
  ELSE
    v_scrim_id := NEW.scrim_id;
  END IF;

  -- Count registrations with verified, waiting_room_id, ongoing, or finished status
  SELECT COUNT(*)::INT INTO v_count
  FROM public.registrations
  WHERE scrim_id = v_scrim_id
    AND status IN ('verified', 'waiting_room_id', 'ongoing', 'finished');

  -- Update scrims table
  UPDATE public.scrims
  SET slot_filled = v_count,
      updated_at = NOW()
  WHERE id = v_scrim_id;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_registrations_slot_filled ON public.registrations;

CREATE TRIGGER trg_registrations_slot_filled
  AFTER INSERT OR UPDATE OF status OR DELETE
  ON public.registrations
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_update_scrim_slot_filled();

-- Fix existing data
UPDATE public.scrims s
SET slot_filled = (
  SELECT COUNT(*)::INT
  FROM public.registrations r
  WHERE r.scrim_id = s.id
    AND r.status IN ('verified', 'waiting_room_id', 'ongoing', 'finished')
);

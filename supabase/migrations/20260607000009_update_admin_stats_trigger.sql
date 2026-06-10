-- Create trigger function to automatically update total_scrims_created and total_participants
-- in public.admin_profiles when scrims are inserted, updated, or deleted.

CREATE OR REPLACE FUNCTION public.fn_update_admin_stats()
RETURNS TRIGGER AS $$
DECLARE
  v_admin_id BIGINT;
  v_scrim_count INT;
  v_participant_count INT;
BEGIN
  -- Determine admin_id
  IF TG_OP = 'DELETE' THEN
    v_admin_id := OLD.admin_id;
  ELSE
    v_admin_id := NEW.admin_id;
  END IF;

  -- Count scrims
  SELECT COUNT(*)::INT INTO v_scrim_count
  FROM public.scrims
  WHERE admin_id = v_admin_id
    AND deleted_at IS NULL;

  -- Sum participants (slot_filled)
  SELECT COALESCE(SUM(slot_filled), 0)::INT INTO v_participant_count
  FROM public.scrims
  WHERE admin_id = v_admin_id
    AND deleted_at IS NULL;

  -- Update admin_profiles
  UPDATE public.admin_profiles
  SET total_scrims_created = v_scrim_count,
      total_participants = v_participant_count,
      updated_at = NOW()
  WHERE user_id = v_admin_id;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_scrims_update_admin_stats ON public.scrims;

CREATE TRIGGER trg_scrims_update_admin_stats
  AFTER INSERT OR UPDATE OF slot_filled, deleted_at OR DELETE
  ON public.scrims
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_update_admin_stats();

-- Sync existing data
UPDATE public.admin_profiles ap
SET total_scrims_created = (
  SELECT COUNT(*)::INT
  FROM public.scrims s
  WHERE s.admin_id = ap.user_id
    AND s.deleted_at IS NULL
),
total_participants = (
  SELECT COALESCE(SUM(s.slot_filled), 0)::INT
  FROM public.scrims s
  WHERE s.admin_id = ap.user_id
    AND s.deleted_at IS NULL
);

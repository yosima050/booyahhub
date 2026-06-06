-- Enable pg_net extension
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Fix fn_send_announcement (resolve UUID p_admin_id to bigint users.id)
CREATE OR REPLACE FUNCTION public.fn_send_announcement(
  p_admin_id uuid,
  p_scrim_id bigint,
  p_title text,
  p_message text,
  p_target text DEFAULT 'all'::text
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE 
  v_count INT := 0;
  v_admin_bigint_id BIGINT;
BEGIN
  -- Resolve admin's bigint ID from public.users using their UUID
  SELECT id INTO v_admin_bigint_id FROM public.users WHERE uuid = p_admin_id;

  INSERT INTO notifications (user_id, type, title, message, sent_by, scrim_id)
  SELECT r.user_id, 'announcement', p_title, p_message, v_admin_bigint_id, p_scrim_id
  FROM registrations r
  WHERE (p_scrim_id IS NULL OR r.scrim_id = p_scrim_id)
    AND (p_target = 'all'
     OR (p_target = 'verified' AND r.status = 'verified')
     OR (p_target = 'pending'  AND (r.status = 'pending_payment' OR r.status = 'waiting_verify')));
     
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- Create the trigger function for sending push notifications
CREATE OR REPLACE FUNCTION public.handle_new_notification_trigger()
RETURNS TRIGGER AS $$
DECLARE
  v_url TEXT;
  v_payload JSONB;
BEGIN
  v_url := 'https://dacdutkuqqqwhlbqhhvf.supabase.co/functions/v1/send-push';

  v_payload := jsonb_build_object(
    'record', row_to_json(NEW)
  );

  -- Perform an asynchronous POST request to our Edge Function
  PERFORM net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', 'BOOYAH_SECRET_12345'
    ),
    body := v_payload::text
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS tr_after_insert_notification ON public.notifications;

-- Create trigger on notifications table
CREATE TRIGGER tr_after_insert_notification
AFTER INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_notification_trigger();

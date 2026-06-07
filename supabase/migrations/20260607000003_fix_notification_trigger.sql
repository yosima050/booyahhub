-- Re-create the trigger function for sending push notifications with correct net.http_post parameters
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

  -- Perform an asynchronous POST request to our Edge Function with correct arguments types
  PERFORM net.http_post(
    url := v_url,
    body := v_payload,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-webhook-secret', 'BOOYAH_SECRET_12345'
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

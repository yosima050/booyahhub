-- 1. Add missing updated_at column to device_tokens
ALTER TABLE public.device_tokens ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT timezone('utc'::text, now());

-- 2. Add RLS Policies for device_tokens table
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow users to view own device tokens" ON public.device_tokens;
DROP POLICY IF EXISTS "Allow users to insert own device tokens" ON public.device_tokens;
DROP POLICY IF EXISTS "Allow users to update own device tokens" ON public.device_tokens;
DROP POLICY IF EXISTS "Allow users to delete own device tokens" ON public.device_tokens;

CREATE POLICY "Allow users to view own device tokens" 
ON public.device_tokens FOR SELECT TO authenticated 
USING (user_id = (SELECT id FROM public.users WHERE uuid = auth.uid()));

CREATE POLICY "Allow users to insert own device tokens" 
ON public.device_tokens FOR INSERT TO authenticated 
WITH CHECK (user_id = (SELECT id FROM public.users WHERE uuid = auth.uid()));

CREATE POLICY "Allow users to update own device tokens" 
ON public.device_tokens FOR UPDATE TO authenticated 
USING (user_id = (SELECT id FROM public.users WHERE uuid = auth.uid()))
WITH CHECK (user_id = (SELECT id FROM public.users WHERE uuid = auth.uid()));

CREATE POLICY "Allow users to delete own device tokens" 
ON public.device_tokens FOR DELETE TO authenticated 
USING (user_id = (SELECT id FROM public.users WHERE uuid = auth.uid()));

-- 3. Add RLS Policies for notifications table
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow users to view own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Allow users to update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Allow users to delete own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Allow platform users to insert notifications" ON public.notifications;

CREATE POLICY "Allow users to view own notifications" 
ON public.notifications FOR SELECT TO authenticated 
USING (user_id = (SELECT id FROM public.users WHERE uuid = auth.uid()));

CREATE POLICY "Allow users to update own notifications" 
ON public.notifications FOR UPDATE TO authenticated 
USING (user_id = (SELECT id FROM public.users WHERE uuid = auth.uid()))
WITH CHECK (user_id = (SELECT id FROM public.users WHERE uuid = auth.uid()));

CREATE POLICY "Allow users to delete own notifications" 
ON public.notifications FOR DELETE TO authenticated 
USING (user_id = (SELECT id FROM public.users WHERE uuid = auth.uid()));

CREATE POLICY "Allow platform users to insert notifications" 
ON public.notifications FOR INSERT TO authenticated 
WITH CHECK ((SELECT role FROM public.users WHERE uuid = auth.uid()) = 'platform'::user_role);

-- 4. Clean up legacy function and alter functions/procedures to SECURITY DEFINER
DROP FUNCTION IF EXISTS public.sp_finalize_leaderboard(integer);

ALTER PROCEDURE public.sp_finalize_leaderboard(bigint) SECURITY DEFINER;
ALTER PROCEDURE public.sp_send_room_id(bigint, varchar, varchar, bigint, text) SECURITY DEFINER;
ALTER PROCEDURE public.sp_verify_claim(bigint, bigint, boolean, varchar) SECURITY DEFINER;
ALTER FUNCTION public.fn_send_announcement(uuid, bigint, text, text, text) SECURITY DEFINER;

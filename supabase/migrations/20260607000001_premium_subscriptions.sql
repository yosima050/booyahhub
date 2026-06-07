-- Add Midtrans integration columns to premium_requests table
ALTER TABLE public.premium_requests 
ADD COLUMN IF NOT EXISTS midtrans_snap_token character varying,
ADD COLUMN IF NOT EXISTS midtrans_status character varying,
ADD COLUMN IF NOT EXISTS midtrans_transaction_id character varying,
ADD COLUMN IF NOT EXISTS payment_type character varying;

-- Enable Row Level Security on premium_requests if not already enabled
ALTER TABLE public.premium_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any to prevent conflicts
DROP POLICY IF EXISTS "Allow users to view own premium requests" ON public.premium_requests;
DROP POLICY IF EXISTS "Allow users to insert own premium requests" ON public.premium_requests;
DROP POLICY IF EXISTS "Allow users and platform to update premium requests" ON public.premium_requests;

-- 1. SELECT Policy: Allow users to view their own premium requests, and allow platform managers to view all
CREATE POLICY "Allow users to view own premium requests" 
ON public.premium_requests 
FOR SELECT 
TO authenticated 
USING (
  admin_user_id = (SELECT id FROM public.users WHERE uuid = auth.uid())
  OR 
  (SELECT role FROM public.users WHERE uuid = auth.uid()) = 'platform'::user_role
);

-- 2. INSERT Policy: Allow users to insert their own premium requests
CREATE POLICY "Allow users to insert own premium requests" 
ON public.premium_requests 
FOR INSERT 
TO authenticated 
WITH CHECK (
  admin_user_id = (SELECT id FROM public.users WHERE uuid = auth.uid())
);

-- 3. UPDATE Policy: Allow users to update their own requests (primarily for midtrans_snap_token) and platform managers to update any
CREATE POLICY "Allow users and platform to update premium requests" 
ON public.premium_requests 
FOR UPDATE 
TO authenticated 
USING (
  admin_user_id = (SELECT id FROM public.users WHERE uuid = auth.uid())
  OR 
  (SELECT role FROM public.users WHERE uuid = auth.uid()) = 'platform'::user_role
)
WITH CHECK (
  admin_user_id = (SELECT id FROM public.users WHERE uuid = auth.uid())
  OR 
  (SELECT role FROM public.users WHERE uuid = auth.uid()) = 'platform'::user_role
);

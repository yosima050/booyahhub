-- 1. Add RLS Policies for match_results table
ALTER TABLE public.match_results ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "results_select" ON public.match_results;
DROP POLICY IF EXISTS "results_insert_admin" ON public.match_results;
DROP POLICY IF EXISTS "results_update" ON public.match_results;

CREATE POLICY "results_select" ON public.match_results FOR SELECT USING (true);

CREATE POLICY "results_insert_admin" ON public.match_results FOR INSERT
  WITH CHECK ((SELECT role FROM public.users WHERE uuid = auth.uid()) = 'admin'::user_role);

CREATE POLICY "results_update" ON public.match_results FOR UPDATE
  USING ((SELECT role FROM public.users WHERE uuid = auth.uid()) IN ('admin'::user_role, 'platform'::user_role));

-- 2. Add RLS Policies for prize_claims table
ALTER TABLE public.prize_claims ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "claims_select" ON public.prize_claims;
DROP POLICY IF EXISTS "claims_insert" ON public.prize_claims;
DROP POLICY IF EXISTS "claims_update" ON public.prize_claims;

CREATE POLICY "claims_select" ON public.prize_claims FOR SELECT
  USING (user_id = (SELECT id FROM public.users WHERE uuid = auth.uid()) OR (SELECT role FROM public.users WHERE uuid = auth.uid()) = 'platform'::user_role);

CREATE POLICY "claims_insert" ON public.prize_claims FOR INSERT
  WITH CHECK ((SELECT role FROM public.users WHERE uuid = auth.uid()) IN ('admin'::user_role, 'platform'::user_role));

CREATE POLICY "claims_update" ON public.prize_claims FOR UPDATE
  USING (user_id = (SELECT id FROM public.users WHERE uuid = auth.uid()) OR (SELECT role FROM public.users WHERE uuid = auth.uid()) = 'platform'::user_role);

-- 3. Add RLS Policies for scrim_announcements table
ALTER TABLE public.scrim_announcements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "announcements_select" ON public.scrim_announcements;
DROP POLICY IF EXISTS "announcements_insert" ON public.scrim_announcements;
DROP POLICY IF EXISTS "announcements_update" ON public.scrim_announcements;
DROP POLICY IF EXISTS "announcements_delete" ON public.scrim_announcements;

CREATE POLICY "announcements_select" ON public.scrim_announcements FOR SELECT USING (true);

CREATE POLICY "announcements_insert" ON public.scrim_announcements FOR INSERT
  WITH CHECK ((SELECT role FROM public.users WHERE uuid = auth.uid()) IN ('admin'::user_role, 'platform'::user_role));

CREATE POLICY "announcements_update" ON public.scrim_announcements FOR UPDATE
  USING ((SELECT role FROM public.users WHERE uuid = auth.uid()) IN ('admin'::user_role, 'platform'::user_role));

CREATE POLICY "announcements_delete" ON public.scrim_announcements FOR DELETE
  USING ((SELECT role FROM public.users WHERE uuid = auth.uid()) IN ('admin'::user_role, 'platform'::user_role));

-- 4. Add RLS Policies for audit_logs table
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "audit_logs_select" ON public.audit_logs;
DROP POLICY IF EXISTS "audit_logs_insert" ON public.audit_logs;

CREATE POLICY "audit_logs_select" ON public.audit_logs FOR SELECT
  USING ((SELECT role FROM public.users WHERE uuid = auth.uid()) = 'platform'::user_role);

CREATE POLICY "audit_logs_insert" ON public.audit_logs FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- 5. Add RLS Policies for platform_settings table
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "platform_settings_select" ON public.platform_settings;
DROP POLICY IF EXISTS "platform_settings_modify" ON public.platform_settings;

CREATE POLICY "platform_settings_select" ON public.platform_settings FOR SELECT USING (true);

CREATE POLICY "platform_settings_modify" ON public.platform_settings FOR ALL
  USING ((SELECT role FROM public.users WHERE uuid = auth.uid()) = 'platform'::user_role);

-- 6. Add RLS Policies for sessions table
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sessions_all" ON public.sessions;

CREATE POLICY "sessions_all" ON public.sessions FOR ALL
  USING (user_id = (SELECT id FROM public.users WHERE uuid = auth.uid()));

-- ══════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS) – Paste di Supabase SQL Editor
-- Aktifkan RLS di semua tabel untuk keamanan
-- ══════════════════════════════════════════════════════════

-- 1. Aktifkan RLS di semua tabel
ALTER TABLE users             ENABLE ROW LEVEL SECURITY;
ALTER TABLE scrims            ENABLE ROW LEVEL SECURITY;
ALTER TABLE registrations     ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members      ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_results     ENABLE ROW LEVEL SECURITY;
ALTER TABLE prize_claims      ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications     ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE premium_requests  ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_profiles    ENABLE ROW LEVEL SECURITY;

-- 2. Helper function: ambil role user (cek UUID bukan ID)
CREATE OR REPLACE FUNCTION auth.user_role()
RETURNS TEXT AS $$
  SELECT role FROM users WHERE uuid = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER;

-- 3. USERS: hanya bisa lihat diri sendiri, platform bisa lihat semua
CREATE POLICY "users_select" ON users FOR SELECT
  USING (uuid = auth.uid() OR (SELECT role FROM users WHERE uuid = auth.uid()) = 'platform');

CREATE POLICY "users_insert_self" ON users FOR INSERT
  WITH CHECK (uuid = auth.uid());

CREATE POLICY "users_update_self" ON users FOR UPDATE
  USING (uuid = auth.uid());

-- 4. SCRIMS: semua bisa lihat open, admin hanya kelola punyanya
CREATE POLICY "scrims_select_all" ON scrims FOR SELECT
  USING (status IN ('open','closed','ongoing','finished') AND deleted_at IS NULL
         OR auth.user_role() IN ('admin','platform'));

CREATE POLICY "scrims_insert_admin" ON scrims FOR INSERT
  WITH CHECK (auth.user_role() = 'admin' AND admin_id = auth.uid());

CREATE POLICY "scrims_update_own" ON scrims FOR UPDATE
  USING (admin_id = auth.uid() OR auth.user_role() = 'platform');

CREATE POLICY "scrims_delete" ON scrims FOR DELETE
  USING (admin_id = auth.uid() OR auth.user_role() = 'platform');

-- 5. REGISTRATIONS: peserta lihat punyanya, admin lihat scrimnya
CREATE POLICY "reg_select_own" ON registrations FOR SELECT
  USING ((SELECT uuid FROM users WHERE id = user_id) = auth.uid()
         OR EXISTS (SELECT 1 FROM scrims WHERE id = scrim_id AND admin_id = auth.uid())
         OR auth.user_role() = 'platform');

CREATE POLICY "reg_insert_peserta" ON registrations FOR INSERT
  WITH CHECK (auth.user_role() = 'peserta' AND (SELECT uuid FROM users WHERE id = user_id) = auth.uid());

CREATE POLICY "reg_update_own" ON registrations FOR UPDATE
  USING ((SELECT uuid FROM users WHERE id = user_id) = auth.uid()
         OR EXISTS (SELECT 1 FROM scrims WHERE id = scrim_id AND admin_id = auth.uid()));

CREATE POLICY "reg_delete" ON registrations FOR DELETE
  USING ((SELECT uuid FROM users WHERE id = user_id) = auth.uid()
         OR EXISTS (SELECT 1 FROM scrims WHERE id = scrim_id AND admin_id = auth.uid()));

-- 6. TEAM MEMBERS: semua bisa lihat, pendaftar/admin/platform bisa kelola
CREATE POLICY "tm_select" ON team_members FOR SELECT
  USING (EXISTS (SELECT 1 FROM registrations WHERE registrations.id = team_members.registration_id));

CREATE POLICY "tm_insert" ON team_members FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM registrations
      WHERE registrations.id = team_members.registration_id
      AND (
        registrations.user_id = (SELECT id FROM users WHERE uuid = auth.uid())
        OR EXISTS (
          SELECT 1 FROM scrims
          WHERE scrims.id = registrations.scrim_id
          AND (
            scrims.admin_id = (SELECT id FROM users WHERE uuid = auth.uid())
            OR (SELECT role::text FROM users WHERE uuid = auth.uid()) = 'platform'
          )
        )
      )
    )
  );

CREATE POLICY "tm_update" ON team_members FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM registrations
      WHERE registrations.id = team_members.registration_id
      AND (
        registrations.user_id = (SELECT id FROM users WHERE uuid = auth.uid())
        OR EXISTS (
          SELECT 1 FROM scrims
          WHERE scrims.id = registrations.scrim_id
          AND (
            scrims.admin_id = (SELECT id FROM users WHERE uuid = auth.uid())
            OR (SELECT role::text FROM users WHERE uuid = auth.uid()) = 'platform'
          )
        )
      )
    )
  );

CREATE POLICY "tm_delete" ON team_members FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM registrations
      WHERE registrations.id = team_members.registration_id
      AND (
        registrations.user_id = (SELECT id FROM users WHERE uuid = auth.uid())
        OR EXISTS (
          SELECT 1 FROM scrims
          WHERE scrims.id = registrations.scrim_id
          AND (
            scrims.admin_id = (SELECT id FROM users WHERE uuid = auth.uid())
            OR (SELECT role::text FROM users WHERE uuid = auth.uid()) = 'platform'
          )
        )
      )
    )
  );

-- 7. NOTIFICATIONS: hanya pemilik yang bisa lihat & update
CREATE POLICY "notif_select_own" ON notifications FOR SELECT
  USING ((SELECT uuid FROM users WHERE id = user_id) = auth.uid());

CREATE POLICY "notif_update_own" ON notifications FOR UPDATE
  USING ((SELECT uuid FROM users WHERE id = user_id) = auth.uid());

-- 8. MATCH_RESULTS: semua bisa lihat, admin bisa input
CREATE POLICY "results_select" ON match_results FOR SELECT USING (true);

CREATE POLICY "results_insert_admin" ON match_results FOR INSERT
  WITH CHECK (auth.user_role() = 'admin');

CREATE POLICY "results_update" ON match_results FOR UPDATE
  USING (auth.user_role() IN ('admin', 'platform'));

-- 9. PRIZE_CLAIMS: peserta lihat punyanya, platform kelola semua
CREATE POLICY "claims_select" ON prize_claims FOR SELECT
  USING ((SELECT uuid FROM users WHERE id = user_id) = auth.uid() OR auth.user_role() = 'platform');

CREATE POLICY "claims_insert" ON prize_claims FOR INSERT
  WITH CHECK (auth.user_role() IN ('admin', 'system'));

CREATE POLICY "claims_update_own" ON prize_claims FOR UPDATE
  USING ((SELECT uuid FROM users WHERE id = user_id) = auth.uid() OR auth.user_role() = 'platform');

-- 10. TRANSACTIONS: platform bisa lihat & manage
CREATE POLICY "tx_select" ON transactions FOR SELECT
  USING ((SELECT uuid FROM users WHERE id = user_id) = auth.uid() OR auth.user_role() = 'platform');

CREATE POLICY "tx_insert" ON transactions FOR INSERT
  WITH CHECK (auth.user_role() IN ('system', 'platform'));

-- 11. PREMIUM_REQUESTS: admin bisa buat, platform bisa kelola
CREATE POLICY "pr_select" ON premium_requests FOR SELECT
  USING ((SELECT uuid FROM users WHERE id = admin_user_id) = auth.uid() OR auth.user_role() = 'platform');

CREATE POLICY "pr_insert" ON premium_requests FOR INSERT
  WITH CHECK (auth.user_role() = 'admin' AND (SELECT uuid FROM users WHERE id = admin_user_id) = auth.uid());

CREATE POLICY "pr_update_plat" ON premium_requests FOR UPDATE
  USING (auth.user_role() = 'platform');

-- 12. ADMIN_PROFILES: semua bisa lihat (untuk tampil di scrim card)
CREATE POLICY "ap_select" ON admin_profiles FOR SELECT USING (true);

CREATE POLICY "ap_update_own" ON admin_profiles FOR UPDATE
  USING (user_id = auth.uid() OR auth.user_role() = 'platform');

-- ══════════════════════════════════════════════════════════
-- STORAGE BUCKET POLICIES
-- Setup di Supabase Storage Dashboard dulu:
-- 1. Buat bucket: "payment-proofs" → Private
-- 2. Buat bucket: "avatars" → Public
-- ══════════════════════════════════════════════════════════

-- Payment proofs bucket policies
CREATE POLICY "proof_upload" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'payment-proofs'
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "proof_read_own_or_admin" ON storage.objects FOR SELECT
  USING (
    bucket_id = 'payment-proofs'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR auth.user_role() IN ('admin', 'platform')
    )
  );

-- Avatars bucket policies
CREATE POLICY "avatar_upload" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
  );

CREATE POLICY "avatar_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- ══════════════════════════════════════════════════════════
-- RPC FUNCTIONS (Stored Procedures)
-- Panggil dari Flutter menggunakan: db.rpc('function_name', params: {...})
-- ══════════════════════════════════════════════════════════

-- Send room ID to verified participants
CREATE OR REPLACE FUNCTION sp_send_room_id(
  p_scrim_id INT,
  p_room_id TEXT,
  p_room_pass TEXT,
  p_admin_id UUID,
  p_extra_msg TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  -- Update scrim dengan room info
  UPDATE scrims
  SET room_id = p_room_id,
      room_password = p_room_pass
  WHERE id = p_scrim_id AND admin_id = p_admin_id;

  -- Kirim notifikasi ke peserta terverifikasi
  INSERT INTO notifications (user_id, type, title, message, scrim_id, sent_by)
  SELECT r.user_id, 'room_id_sent', 'Room ID Tersedia',
         COALESCE(p_extra_msg || E'\n', '') || 'Room ID: ' || p_room_id ||
         E'\nPassword: ' || p_room_pass,
         p_scrim_id, p_admin_id
  FROM registrations r
  WHERE r.scrim_id = p_scrim_id
    AND r.status IN ('verified', 'waiting_room_id')
    AND r.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Finalize leaderboard dan alokasi hadiah
CREATE OR REPLACE FUNCTION sp_finalize_leaderboard(p_scrim_id INT)
RETURNS VOID AS $$
BEGIN
  -- Update ranking berdasarkan total_point
  WITH ranked AS (
    SELECT id,
           ROW_NUMBER() OVER (ORDER BY total_point DESC) as rank
    FROM match_results
    WHERE scrim_id = p_scrim_id
  )
  UPDATE match_results mr
  SET rank = r.rank
  FROM ranked r
  WHERE mr.id = r.id;

  -- Auto-create prize_claims untuk top 3
  INSERT INTO prize_claims (user_id, scrim_id, match_result_id, prize_amount, status)
  SELECT mr.registration_id, p_scrim_id, mr.id,
         CASE
           WHEN mr.rank = 1 THEN (SELECT prize_pool * 0.5 FROM scrims WHERE id = p_scrim_id)
           WHEN mr.rank = 2 THEN (SELECT prize_pool * 0.3 FROM scrims WHERE id = p_scrim_id)
           WHEN mr.rank = 3 THEN (SELECT prize_pool * 0.2 FROM scrims WHERE id = p_scrim_id)
           ELSE 0
         END,
         'available'
  FROM match_results mr
  WHERE mr.scrim_id = p_scrim_id AND mr.rank <= 3
  ON CONFLICT DO NOTHING;

  -- Update scrim status
  UPDATE scrims SET status = 'finished' WHERE id = p_scrim_id;

  -- Notifikasi pemenang
  INSERT INTO notifications (user_id, type, title, message, scrim_id, sent_by)
  SELECT mr.registration_id, 'prize_available', '🏆 Hadiah Tersedia',
         'Anda mendapatkan peringkat ' || mr.rank || ' di scrim ini. Hadiah siap diklaim!',
         p_scrim_id,
         (SELECT admin_id FROM scrims WHERE id = p_scrim_id)
  FROM match_results mr
  WHERE mr.scrim_id = p_scrim_id AND mr.rank <= 3;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify prize claim
CREATE OR REPLACE FUNCTION sp_verify_claim(
  p_claim_id INT,
  p_platform_id UUID,
  p_approve BOOLEAN,
  p_reason TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_user_id BIGINT;
  v_prize_amount INT;
BEGIN
  SELECT user_id, prize_amount INTO v_user_id, v_prize_amount
  FROM prize_claims WHERE id = p_claim_id;

  IF p_approve THEN
    UPDATE prize_claims
    SET status = 'completed',
        approved_by = p_platform_id,
        approved_at = NOW()
    WHERE id = p_claim_id;

    -- Create transaction record
    INSERT INTO transactions (user_id, type, amount, description)
    VALUES (v_user_id, 'prize_payout', v_prize_amount, 'Prize transfer untuk claim ID: ' || p_claim_id);
  ELSE
    UPDATE prize_claims
    SET status = 'rejected',
        reject_reason = p_reason,
        rejected_by = p_platform_id,
        rejected_at = NOW()
    WHERE id = p_claim_id;
  END IF;

  -- Notifikasi ke peserta
  INSERT INTO notifications (user_id, type, title, message, sent_by)
  SELECT u.uuid,
         CASE WHEN p_approve THEN 'claim_approved' ELSE 'claim_rejected' END,
         CASE WHEN p_approve THEN '💰 Transfer Selesai!' ELSE '❌ Klaim Ditolak' END,
         CASE WHEN p_approve THEN 'Hadiah Anda telah ditransfer!'
              ELSE 'Klaim Anda ditolak: ' || COALESCE(p_reason, 'Silakan hubungi admin')
         END,
         p_platform_id
  FROM users u WHERE u.id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Send announcement (Automatic via Midtrans webhook - no manual verification)
CREATE OR REPLACE FUNCTION fn_send_announcement(
  p_admin_id UUID,
  p_scrim_id INT DEFAULT NULL,
  p_title TEXT,
  p_message TEXT,
  p_target TEXT DEFAULT 'all'
)
RETURNS INT AS $$
DECLARE
  v_sent_count INT = 0;
  v_recipient_ids BIGINT[];
BEGIN
  -- Ambil recipient IDs sesuai target
  IF p_scrim_id IS NOT NULL THEN
    IF p_target = 'verified' THEN
      SELECT ARRAY_AGG(DISTINCT r.user_id)
      INTO v_recipient_ids
      FROM registrations r
      WHERE r.scrim_id = p_scrim_id
        AND r.status = 'verified'
        AND r.deleted_at IS NULL;
    ELSIF p_target = 'pending' THEN
      SELECT ARRAY_AGG(DISTINCT r.user_id)
      INTO v_recipient_ids
      FROM registrations r
      WHERE r.scrim_id = p_scrim_id
        AND r.status = 'pending_payment'
        AND r.deleted_at IS NULL;
    ELSE -- all peserta di scrim
      SELECT ARRAY_AGG(DISTINCT r.user_id)
      INTO v_recipient_ids
      FROM registrations r
      WHERE r.scrim_id = p_scrim_id
        AND r.deleted_at IS NULL;
    END IF;
  ELSE
    -- All peserta
    SELECT ARRAY_AGG(id)
    INTO v_recipient_ids
    FROM users
    WHERE role = 'peserta' AND deleted_at IS NULL;
  END IF;

  -- Insert ke notifications untuk setiap recipient
  INSERT INTO notifications (user_id, type, title, message, sent_by, scrim_id)
  SELECT uid, 'announcement', p_title, p_message, p_admin_id, p_scrim_id
  FROM UNNEST(v_recipient_ids) AS uid;

  GET DIAGNOSTICS v_sent_count = ROW_COUNT;
  RETURN v_sent_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ══════════════════════════════════════════════════════════
-- VIEW: Admin scrim report
-- ══════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW v_admin_scrim_report AS
SELECT
  s.id, s.title, s.mode, s.scheduled_at,
  s.slot_total, s.slot_filled,
  (s.slot_total - s.slot_filled) AS slot_remaining,
  s.fee, s.prize_pool,
  COUNT(r.id) FILTER (WHERE r.status = 'verified') AS verified_teams,
  COUNT(r.id) FILTER (WHERE r.status = 'pending_payment') AS pending_verify,
  COUNT(r.id) FILTER (WHERE r.status = 'rejected') AS rejected_teams,
  (s.fee * COUNT(r.id) FILTER (WHERE r.status = 'verified')) AS estimated_income,
  s.status, s.admin_id
FROM scrims s
LEFT JOIN registrations r ON s.id = r.scrim_id
GROUP BY s.id;

-- ══════════════════════════════════════════════════════════
-- VIEW: User riwayat scrim
-- ══════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW v_user_riwayat AS
SELECT
  r.id, r.scrim_id, s.title, s.scheduled_at,
  r.team_name, r.status as reg_status,
  mr.rank, mr.total_point, mr.placement, mr.kills,
  pc.prize_amount, pc.status as prize_status,
  r.created_at
FROM registrations r
JOIN scrims s ON r.scrim_id = s.id
LEFT JOIN match_results mr ON r.id = mr.registration_id
LEFT JOIN prize_claims pc ON mr.id = pc.match_result_id
ORDER BY r.created_at DESC;

-- ══════════════════════════════════════════════════════════
-- VIEW: Leaderboard scrim (BIGINT/UUID datatype consistency check)
-- ══════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW v_leaderboard AS
SELECT
  mr.id, mr.scrim_id, mr.rank,
  r.team_name, u.name AS leader_name,
  mr.placement, mr.kills,
  mr.total_point,
  pc.prize_amount, pc.status as prize_status
FROM match_results mr
JOIN registrations r ON mr.registration_id = r.id
JOIN users u ON r.user_id = u.id
LEFT JOIN prize_claims pc ON mr.id = pc.match_result_id
ORDER BY mr.rank;

-- ══════════════════════════════════════════════════════════
-- VIEW: Platform finance
-- ══════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW v_platform_finance AS
SELECT
  COUNT(DISTINCT s.id) AS total_scrims,
  COUNT(DISTINCT r.user_id) FILTER (WHERE r.status = 'verified') AS total_participants,
  COALESCE(SUM(s.fee * r.id::INT), 0) FILTER (WHERE r.status = 'verified') AS total_revenue,
  COUNT(DISTINCT pc.id) FILTER (WHERE pc.status = 'completed') AS claims_completed,
  COALESCE(SUM(pc.prize_amount), 0) FILTER (WHERE pc.status = 'completed') AS total_prizes_paid,
  NOW() AS last_updated
FROM scrims s
LEFT JOIN registrations r ON s.id = r.scrim_id AND r.deleted_at IS NULL
LEFT JOIN prize_claims pc ON s.id = pc.scrim_id;

-- ══════════════════════════════════════════════════════════
-- SCHEMA MIGRATIONS (Run in Supabase SQL Editor if needed)
-- ══════════════════════════════════════════════════════════
-- Allow nullable scrim_id and match_result_id in prize_claims to support Admin Cashout
ALTER TABLE public.prize_claims ALTER COLUMN scrim_id DROP NOT NULL;
ALTER TABLE public.prize_claims ALTER COLUMN match_result_id DROP NOT NULL;

-- Update fn_get_public_stats to include user counts and player records for Home screen stats
CREATE OR REPLACE FUNCTION public.fn_get_public_stats()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_ongoing_scrims INT;
  v_total_registrations INT;
  v_verification_rate INT;
  v_total_users INT;
  v_total_filled INT;
  v_max_filled INT;
BEGIN
  -- Count ongoing scrims
  SELECT COUNT(*)::INT INTO v_ongoing_scrims
  FROM public.scrims
  WHERE status = 'ongoing' AND deleted_at IS NULL;

  -- Count total registrations
  SELECT COUNT(*)::INT INTO v_total_registrations
  FROM public.registrations;

  -- Count total players (users with role = 'peserta')
  SELECT COUNT(*)::INT INTO v_total_users
  FROM public.users
  WHERE role = 'peserta' AND deleted_at IS NULL;

  -- Sum of all slots filled (pemain aktif)
  SELECT COALESCE(SUM(slot_filled), 0)::INT INTO v_total_filled
  FROM public.scrims
  WHERE deleted_at IS NULL;

  -- Max of slot_filled (rekor peserta)
  SELECT COALESCE(MAX(slot_filled), 0)::INT INTO v_max_filled
  FROM public.scrims
  WHERE deleted_at IS NULL;

  -- Calculate verification rate
  IF v_total_registrations > 0 THEN
    SELECT ROUND((COUNT(*)::FLOAT / v_total_registrations::FLOAT) * 100) INTO v_verification_rate
    FROM public.registrations
    WHERE status = 'verified';
  ELSE
    v_verification_rate := 97;
  END IF;

  RETURN jsonb_build_object(
    'ongoing_scrims', v_ongoing_scrims,
    'total_registrations', v_total_registrations,
    'verification_rate', v_verification_rate,
    'total_users', v_total_users,
    'total_filled', v_total_filled,
    'max_filled', v_max_filled
  );
END;
$function$;



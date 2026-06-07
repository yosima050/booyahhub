-- 1. Drop existing procedures or functions safely based on prokind
DO $$
BEGIN
    -- Drop sp_finalize_leaderboard
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid 
        WHERE nspname = 'public' AND proname = 'sp_finalize_leaderboard'
    ) THEN
        IF (SELECT prokind FROM pg_proc JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid WHERE nspname = 'public' AND proname = 'sp_finalize_leaderboard') = 'p' THEN
            DROP PROCEDURE public.sp_finalize_leaderboard(bigint);
        ELSE
            DROP FUNCTION public.sp_finalize_leaderboard(bigint);
        END IF;
    END IF;

    -- Drop sp_send_room_id
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid 
        WHERE nspname = 'public' AND proname = 'sp_send_room_id'
    ) THEN
        IF (SELECT prokind FROM pg_proc JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid WHERE nspname = 'public' AND proname = 'sp_send_room_id') = 'p' THEN
            DROP PROCEDURE public.sp_send_room_id(bigint, varchar, varchar, bigint, text);
        ELSE
            DROP FUNCTION public.sp_send_room_id(bigint, varchar, varchar, bigint, text);
        END IF;
    END IF;

    -- Drop sp_verify_claim
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid 
        WHERE nspname = 'public' AND proname = 'sp_verify_claim'
    ) THEN
        IF (SELECT prokind FROM pg_proc JOIN pg_namespace ON pg_proc.pronamespace = pg_namespace.oid WHERE nspname = 'public' AND proname = 'sp_verify_claim') = 'p' THEN
            DROP PROCEDURE public.sp_verify_claim(bigint, bigint, boolean, varchar);
        ELSE
            DROP FUNCTION public.sp_verify_claim(bigint, bigint, boolean, varchar);
        END IF;
    END IF;
END $$;

-- 2. Re-create sp_finalize_leaderboard as FUNCTION
CREATE OR REPLACE FUNCTION public.sp_finalize_leaderboard(p_scrim_id bigint)
RETURNS void AS $$
DECLARE
    v_prize_1st INTEGER;
    v_prize_2nd INTEGER;
    v_prize_3rd INTEGER;
    v_prize_pct_1 NUMERIC;
    v_prize_pct_2 NUMERIC;
    v_prize_pct_3 NUMERIC;
    v_prize_total INTEGER;
    v_rec RECORD;
BEGIN
    -- Ambil persentase hadiah dari settings
    SELECT value::NUMERIC INTO v_prize_pct_1 FROM platform_settings WHERE key = 'prize_1st_pct';
    SELECT value::NUMERIC INTO v_prize_pct_2 FROM platform_settings WHERE key = 'prize_2nd_pct';
    SELECT value::NUMERIC INTO v_prize_pct_3 FROM platform_settings WHERE key = 'prize_3rd_pct';
    SELECT prize_pool INTO v_prize_total FROM scrims WHERE id = p_scrim_id;

    v_prize_1st := ROUND(v_prize_total * v_prize_pct_1 / 100);
    v_prize_2nd := ROUND(v_prize_total * v_prize_pct_2 / 100);
    v_prize_3rd := ROUND(v_prize_total * v_prize_pct_3 / 100);

    -- Update rank berdasarkan total_point
    WITH ranked AS (
        SELECT id,
               RANK() OVER (ORDER BY total_point DESC, kills DESC) AS new_rank
        FROM match_results
        WHERE scrim_id = p_scrim_id
    )
    UPDATE match_results mr
    SET rank = ranked.new_rank
    FROM ranked WHERE mr.id = ranked.id;

    -- Alokasi prize
    UPDATE match_results SET prize_amount = v_prize_1st WHERE scrim_id = p_scrim_id AND rank = 1;
    UPDATE match_results SET prize_amount = v_prize_2nd WHERE scrim_id = p_scrim_id AND rank = 2;
    UPDATE match_results SET prize_amount = v_prize_3rd WHERE scrim_id = p_scrim_id AND rank = 3;

    -- Update status scrim
    UPDATE scrims SET status = 'finished' WHERE id = p_scrim_id;

    -- Buat prize_claims untuk juara 1-3
    INSERT INTO prize_claims (user_id, scrim_id, match_result_id, amount, status)
    SELECT r.user_id, mr.scrim_id, mr.id, mr.prize_amount, 'available'
    FROM match_results mr
    JOIN registrations r ON mr.registration_id = r.id
    WHERE mr.scrim_id = p_scrim_id
      AND mr.rank <= 3
      AND mr.prize_amount > 0
    ON CONFLICT (match_result_id) DO NOTHING;

    -- Kirim notifikasi hasil ke semua peserta
    FOR v_rec IN
        SELECT r.user_id, mr.rank, mr.total_point, mr.prize_amount
        FROM match_results mr
        JOIN registrations r ON mr.registration_id = r.id
        WHERE mr.scrim_id = p_scrim_id
    LOOP
        INSERT INTO notifications (user_id, type, title, message, data, scrim_id)
        SELECT
            v_rec.user_id, 'match_result',
            'Hasil Pertandingan Tersedia',
            CASE WHEN v_rec.rank <= 3
                THEN format('🏆 Tim kamu meraih peringkat #%s! Hadiah Rp%s siap diklaim.', v_rec.rank, v_rec.prize_amount)
                ELSE format('Pertandingan selesai. Tim kamu peringkat #%s dengan %s poin.', v_rec.rank, v_rec.total_point)
            END,
            jsonb_build_object('rank', v_rec.rank, 'points', v_rec.total_point, 'prize', v_rec.prize_amount),
            p_scrim_id;
    END LOOP;

    -- Catat audit log
    INSERT INTO audit_logs (action, entity_type, entity_id, description)
    VALUES ('update', 'scrim', p_scrim_id, 'Leaderboard finalized, prizes allocated');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Re-create sp_send_room_id as FUNCTION
CREATE OR REPLACE FUNCTION public.sp_send_room_id(
    p_scrim_id bigint, 
    p_room_id varchar, 
    p_room_pass varchar, 
    p_admin_id bigint, 
    p_extra_msg text
)
RETURNS void AS $$
DECLARE
    v_title   VARCHAR;
    v_count   INTEGER;
BEGIN
    -- Validasi form kosong
    IF p_room_id IS NULL OR p_room_id = '' OR p_room_pass IS NULL OR p_room_pass = '' THEN
        RAISE EXCEPTION 'Room ID dan Password tidak boleh kosong';
    END IF;

    SELECT title INTO v_title FROM scrims WHERE id = p_scrim_id;

    -- Validasi peserta terverifikasi
    SELECT COUNT(*) INTO v_count
    FROM registrations WHERE scrim_id = p_scrim_id AND status = 'verified';

    IF v_count = 0 THEN
        RAISE EXCEPTION 'Tidak ada peserta terverifikasi untuk dikirim Room ID';
    END IF;

    -- Simpan Room ID
    UPDATE scrims
    SET room_id = p_room_id, room_password = p_room_pass, room_sent_at = NOW()
    WHERE id = p_scrim_id;

    -- Update status registrasi
    UPDATE registrations
    SET status = 'waiting_room_id'
    WHERE scrim_id = p_scrim_id AND status = 'verified';

    -- Kirim notifikasi ke semua peserta verified
    INSERT INTO notifications (user_id, type, title, message, data, sent_by, scrim_id)
    SELECT
        r.user_id,
        'room_id_sent',
        'Room ID Tersedia – ' || v_title,
        format('Room ID: %s · Password: %s%s',
            p_room_id, p_room_pass,
            CASE WHEN p_extra_msg IS NOT NULL THEN E'\n' || p_extra_msg ELSE '' END),
        jsonb_build_object('room_id', p_room_id, 'room_password', p_room_pass, 'scrim_id', p_scrim_id),
        p_admin_id,
        p_scrim_id
    FROM registrations r
    WHERE r.scrim_id = p_scrim_id
      AND r.status IN ('verified','waiting_room_id');

    -- Audit log
    INSERT INTO audit_logs (actor_id, actor_role, action, entity_type, entity_id, description)
    VALUES (p_admin_id, 'admin', 'send', 'scrim', p_scrim_id,
        format('Room ID sent to %s participants', v_count));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Re-create sp_verify_claim as FUNCTION
CREATE OR REPLACE FUNCTION public.sp_verify_claim(
    p_claim_id bigint, 
    p_platform_id bigint, 
    p_approve boolean, 
    p_reason varchar
)
RETURNS void AS $$
DECLARE
    v_user_id   BIGINT;
    v_amount    INTEGER;
    v_scrim_id  BIGINT;
BEGIN
    SELECT user_id, amount, scrim_id
    INTO v_user_id, v_amount, v_scrim_id
    FROM prize_claims WHERE id = p_claim_id;

    IF p_approve THEN
        UPDATE prize_claims
        SET status = 'verified', verified_by = p_platform_id, verified_at = NOW()
        WHERE id = p_claim_id;

        -- Catat transaksi keluar
        INSERT INTO transactions (type, amount, reference_type, reference_id, description, user_id, scrim_id)
        VALUES ('prize_payout', -v_amount, 'prize_claims', p_claim_id,
            'Hadiah terkirim ke pemenang', v_user_id, v_scrim_id);

        -- Notifikasi ke pemenang
        INSERT INTO notifications (user_id, type, title, message, data, sent_by, scrim_id)
        VALUES (v_user_id, 'prize_sent',
            '🎉 Hadiah Berhasil Dikirim!',
            format('Hadiah sebesar Rp%s telah berhasil ditransfer ke rekening kamu.', v_amount),
            jsonb_build_object('amount', v_amount, 'claim_id', p_claim_id),
            p_platform_id, v_scrim_id);
    ELSE
        UPDATE prize_claims
        SET status = 'rejected', reject_reason = p_reason,
            verified_by = p_platform_id, verified_at = NOW()
        WHERE id = p_claim_id;

        -- Kembalikan status ke available
        UPDATE prize_claims SET status = 'available' WHERE id = p_claim_id;

        INSERT INTO notifications (user_id, type, title, message, data, sent_by, scrim_id)
        VALUES (v_user_id, 'prize_processing',
            'Klaim Hadiah Ditolak',
            'Alasan: ' || COALESCE(p_reason, 'Nomor rekening tidak valid. Silakan coba lagi.'),
            jsonb_build_object('claim_id', p_claim_id, 'reason', p_reason),
            p_platform_id, v_scrim_id);
    END IF;

    INSERT INTO audit_logs (actor_id, actor_role, action, entity_type, entity_id, description)
    VALUES (p_platform_id, 'platform',
        CASE WHEN p_approve THEN 'verify' ELSE 'reject' END,
        'prize_claim', p_claim_id,
        CASE WHEN p_approve THEN 'Prize transferred' ELSE 'Prize rejected: ' || COALESCE(p_reason,'') END);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

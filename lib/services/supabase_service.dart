// Satu file service untuk semua operasi Supabase
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

// Akses cepat client
final _db = Supabase.instance.client;
final _auth = Supabase.instance.client.auth;
final _storage = Supabase.instance.client.storage;

// ══════════════════════════════════════════════════════════
// AUTH SERVICE (UC-01, UC-09, UC-10)
// ══════════════════════════════════════════════════════════
class AuthService {
  // UC-01: Register
  static Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    String role = 'peserta',
    String? phone,
    String? ffId,
  }) async {
    final res = await _auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role,
        'phone': phone,
        'ff_id': ffId,
      },
    );

    // Data tambahan ke tabel users (trigger Supabase / RPC)
    if (res.user != null) {
      await _db.from('users').upsert({
        'id': res.user!.id,  // UUID dari Supabase Auth
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'ff_id': ffId,
      });

      // Buat admin_profile jika role admin
      if (role == 'admin') {
        await _db.from('admin_profiles').insert({
          'user_id': res.user!.id,
          'display_name': name,
        });
      }
    }
    return res;
  }

  // UC-09: Login
  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // UC-10: Logout
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Ambil user sekarang
  static User? get currentUser => _auth.currentUser;

  // Ambil role dari metadata
  static String get currentRole =>
      _auth.currentUser?.userMetadata?['role'] as String? ?? 'peserta';

  // Stream perubahan auth state
  static Stream<AuthState> get authStream => _auth.onAuthStateChange;
}

// ══════════════════════════════════════════════════════════
// SCRIM SERVICE (UC-02, UC-11)
// ══════════════════════════════════════════════════════════
class ScrimService {
  // UC-11: Ambil daftar scrim terbuka
  static Future<List<Map<String, dynamic>>> getAll({
    String status = 'open',
    String? mode,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    var query = _db
        .from('scrims')
        .select('''
          id, uuid, title, mode, description,
          scheduled_at, registration_closes_at,
          slot_total, slot_filled, fee, prize_pool,
          is_premium, is_featured, status,
          admin_profiles!inner(display_name, is_trusted, rating)
        ''')
        .eq('status', status)
        .isFilter('deleted_at', null); // BERHENTI DI SINI, jangan .order() dulu

    if (mode != null) query = query.filter('mode', 'eq', mode);
    if (search != null && search.isNotEmpty) {
      query = query.filter('title', 'like', '%$search%');
    }
    
    // Terapkan .order() dan .range() di paling akhir
    final res = await query
        .order('is_featured', ascending: false)
        .order('scheduled_at')
        .range((page - 1) * limit, page * limit - 1);
        
    return List<Map<String, dynamic>>.from(res);
  }

  // UC-11: Detail scrim
  static Future<Map<String, dynamic>> getById(String id) async {
    final res = await _db
        .from('scrims')
        .select('''
          *, admin_profiles(display_name, is_trusted, rating, is_premium)
        ''')
        .eq('id', id)
        .isFilter('deleted_at', null)
        .single();
    return res;
  }

  // UC-02: Buat scrim baru (Admin)
  static Future<Map<String, dynamic>> create({
    required String title,
    required String mode,
    required String scheduledAt,
    required String registrationClosesAt,
    required int slotTotal,
    required int fee,
    String? description,
    String? rules,
  }) async {
    // Validasi backdate (UC-02 Langkah 6a)
    if (DateTime.parse(scheduledAt).isBefore(DateTime.now())) {
      throw Exception('Tanggal tidak valid (backdate)');
    }

    final res = await _db
        .from('scrims')
        .insert({
          'admin_id': AuthService.currentUser!.id,
          'title': title,
          'mode': mode,
          'description': description,
          'rules': rules,
          'scheduled_at': scheduledAt,
          'registration_closes_at': registrationClosesAt,
          'slot_total': slotTotal,
          'fee': fee,
          'status': 'open',
        })
        .select()
        .single();
    return res;
  }

  // UC-02: Update jadwal scrim
  static Future<void> update(String id, Map<String, dynamic> data) async {
    await _db.from('scrims').update(data).eq('id', id);
  }

  // UC-16: Kirim Room ID via RPC (stored procedure)
  static Future<void> sendRoomId({
    required int scrimId,
    required String roomId,
    required String password,
    String? extraMessage,
  }) async {
    await _db.rpc('sp_send_room_id', params: {
      'p_scrim_id': scrimId,
      'p_room_id': roomId,
      'p_room_pass': password,
      'p_admin_id': AuthService.currentUser!.id,
      'p_extra_msg': extraMessage,
    });
  }

  // Realtime: subscribe perubahan slot
  static RealtimeChannel subscribeSlot(
    int scrimId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    return _db
        .channel('scrim_slot_$scrimId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'scrims',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: '$scrimId',
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

}

// ══════════════════════════════════════════════════════════
// REGISTRATION SERVICE (UC-06, UC-07)
// ══════════════════════════════════════════════════════════
class RegistrationService {
  // UC-06: Booking slot
  static Future<Map<String, dynamic>> book({
    required int scrimId,
    required String teamName,
    required String captainFfId,
    required String phone,
    List<String> members = const [],
  }) async {
    // Cek slot real-time sebelum booking
    final scrim = await _db
        .from('scrims')
        .select('slot_filled, slot_total, status')
        .eq('id', scrimId)
        .single();

    // UC-06 Langkah 2a: slot penuh
    if (scrim['status'] != 'open' ||
        (scrim['slot_filled'] as int) >= (scrim['slot_total'] as int)) {
      throw Exception('Slot Penuh – Scrim sudah ditutup');
    }

    // Insert registration
    final reg = await _db
        .from('registrations')
        .insert({
          'scrim_id': scrimId,
          'user_id': AuthService.currentUser!.id,
          'team_name': teamName,
          'captain_ff_id': captainFfId,
          'phone': phone,
          'status': 'pending_payment',
        })
        .select()
        .single();

    // Insert anggota tim
    if (members.isNotEmpty) {
      await _db.from('team_members').insert(
        members.asMap().entries.map((e) => {
          'registration_id': reg['id'],
          'ff_id': e.value,
          'member_order': e.key + 1,
        }).toList(),
      );
    }

    return reg;
  }

  // UC-06: Upload bukti bayar
  static Future<void> uploadPayment({
    required int registrationId,
    required String paymentMethod,
    required String proofUrl,
  }) async {
    // Cek expired (UC-06 Langkah 6a)
    final reg = await _db
        .from('registrations')
        .select('booking_expires_at')
        .eq('id', registrationId)
        .single();

    final expires = DateTime.parse(reg['booking_expires_at'] as String);
    if (DateTime.now().isAfter(expires)) {
      // Auto-cancel
      await _db.from('registrations').update({
        'status': 'rejected',
        'reject_reason': 'Batas waktu upload terlewat'
      }).eq('id', registrationId);
      throw Exception('Batas waktu upload sudah terlewat. Booking dibatalkan.');
    }

    await _db.from('registrations').update({
      'payment_method': paymentMethod,
      'payment_proof_url': proofUrl,
      'payment_uploaded_at': DateTime.now().toIso8601String(),
      'status': 'waiting_verify',
    }).eq('id', registrationId);
  }

  // UC-07: Admin verifikasi pembayaran (via RPC)
  static Future<void> verifyPayment({
    required int registrationId,
    required bool approve,
    String? reason,
  }) async {
    await _db.rpc('sp_verify_payment', params: {
      'p_reg_id': registrationId,
      'p_admin_id': AuthService.currentUser!.id,
      'p_approve': approve,
      'p_reason': reason,
    });
  }

  // UC-12: Riwayat scrim peserta
    static Future<List<Map<String, dynamic>>> getMyRiwayat() async {
      final user = AuthService.currentUser;
      if (user == null) return []; // ✅ Safe fallback

      final res = await _db
          .from('v_user_riwayat')
          .select()
          .eq('user_id', user.id) // ✅ Use user.id safely
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    }

  // UC-15: Admin lihat pendaftar
  static Future<List<Map<String, dynamic>>> getByScrim(int scrimId) async {
    final res = await _db
        .from('registrations')
        .select('''
          *, users(name, phone),
          team_members(ff_id, member_order)
        ''')
        .eq('scrim_id', scrimId)
        .isFilter('deleted_at', null)
        .order('created_at');
    return List<Map<String, dynamic>>.from(res);
  }

  // Realtime: subscribe status pendaftaran user
  static RealtimeChannel subscribeMyStatus(
    String userId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    return _db
        .channel('my_reg_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'registrations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }
}

// ══════════════════════════════════════════════════════════
// RESULT SERVICE (UC-08, UC-14)
// ══════════════════════════════════════════════════════════
class ResultService {
  // UC-08: Input hasil pertandingan
  static Future<void> submitResults({
    required int scrimId,
    required List<Map<String, dynamic>> results,
  }) async {
    // Validasi (UC-08 Langkah 5a)
    for (final r in results) {
      if ((r['kills'] as int) < 0 || (r['placement'] as int) < 1) {
        throw Exception('Nilai kills/placement tidak valid');
      }
    }

    // Upsert semua hasil (trigger DB akan hitung poin otomatis)
    await _db.from('match_results').upsert(
      results
          .map((r) => {
                'scrim_id': scrimId,
                'registration_id': r['registration_id'],
                'team_name': r['team_name'],
                'placement': r['placement'],
                'kills': r['kills'],
                'inputted_by': AuthService.currentUser!.id,
              })
          .toList(),
      onConflict: 'scrim_id, registration_id',
    );

    // Finalize: hitung rank + alokasi hadiah
    await _db
        .rpc('sp_finalize_leaderboard', params: {'p_scrim_id': scrimId});
  }

  // UC-14: Ambil leaderboard
  static Future<List<Map<String, dynamic>>> getLeaderboard(int scrimId) async {
    final res = await _db
        .from('v_leaderboard')
        .select()
        .eq('scrim_id', scrimId)
        .order('rank');
    return List<Map<String, dynamic>>.from(res);
  }

  // Realtime: leaderboard live update
  static RealtimeChannel subscribeLeaderboard(
    int scrimId,
    void Function() onUpdate,
  ) {
    return _db
        .channel('leaderboard_$scrimId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'match_results',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'scrim_id',
            value: '$scrimId',
          ),
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }
}

// ══════════════════════════════════════════════════════════
// CLAIM SERVICE (UC-04, UC-05)
// ══════════════════════════════════════════════════════════
class ClaimService {
  // UC-04: Ambil hadiah tersedia
  static Future<List<Map<String, dynamic>>> getMyClaims() async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    final res = await _db
        .from('prize_claims')
        .select('''
          *, scrims(title), match_results(rank, total_point)
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // UC-04: Ajukan klaim
  static Future<void> requestClaim({
    required int claimId,
    required String bankType,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    // UC-04 Langkah 6a: validasi rekening
    if (accountNumber.isEmpty || accountName.isEmpty) {
      throw Exception('Data rekening tidak boleh kosong');
    }

    await _db.from('prize_claims').update({
      'status': 'processing',
      'bank_type': bankType,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_name': accountName,
      'claimed_at': DateTime.now().toIso8601String(),
    }).eq('id', claimId).eq('status', 'available');
  }

  // UC-05: Platform verifikasi klaim
  static Future<void> verifyClaim({
    required int claimId,
    required bool approve,
    String? reason,
  }) async {
    await _db.rpc('sp_verify_claim', params: {
      'p_claim_id': claimId,
      'p_platform_id': AuthService.currentUser!.id,
      'p_approve': approve,
      'p_reason': reason,
    });
  }

  // Platform: Antrian klaim pending
  static Future<List<Map<String, dynamic>>> getPendingClaims() async {
    final res = await _db
        .from('prize_claims')
        .select('*, users(name), scrims(title)')
        .eq('status', 'processing')
        .order('claimed_at');
    return List<Map<String, dynamic>>.from(res);
  }
}

// ══════════════════════════════════════════════════════════
// NOTIFICATION SERVICE (UC-13, UC-17)
// ══════════════════════════════════════════════════════════
class NotificationService {
  // UC-13: Ambil notifikasi
static Future<List<Map<String, dynamic>>> getAll({int limit = 20}) async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    final res = await _db
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(res);
  }

  // Hitung unread
  static Future<int> getUnreadCount() async {
    final user = AuthService.currentUser;
    if (user == null) return 0;

    final res = await _db
        .from('notifications')
        .select('id')
        .eq('user_id', AuthService.currentUser!.id)
        .eq('is_read', false)
        .count();
    return res.count;
  }

  // UC-13: Tandai dibaca
  static Future<void> markRead(int id) async {
    await _db.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', id).eq('user_id', AuthService.currentUser!.id);
  }

  // Tandai semua dibaca
  static Future<void> markAllRead() async {
    await _db.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('user_id', AuthService.currentUser!.id).eq('is_read', false);
  }

  // UC-17: Kirim pengumuman (Admin)
  static Future<int> sendAnnouncement({
    required String title,
    required String message,
    int? scrimId,
    String target = 'all', // all | verified | pending
  }) async {
    // Panggil RPC yang sudah ada di PostgreSQL
    final result = await _db.rpc('fn_send_announcement', params: {
      'p_admin_id': AuthService.currentUser!.id,
      'p_scrim_id': scrimId,
      'p_title': title,
      'p_message': message,
      'p_target': target,
    });
    return result as int; // jumlah penerima
  }

  // Realtime: notifikasi baru langsung masuk
  static RealtimeChannel subscribeNotifications(
    String userId,
    void Function(Map<String, dynamic>) onNew,
  ) {
    return _db
        .channel('notif_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => onNew(payload.newRecord),
        )
        .subscribe();
  }
}

// ══════════════════════════════════════════════════════════
// STORAGE SERVICE (Upload file bukti bayar)
// ══════════════════════════════════════════════════════════
class StorageService {
  static const _bucket = 'payment-proofs';

  // Upload foto bukti bayar → return public URL
  static Future<String> uploadPaymentProof({
    required String fileName,
    required List<int> bytes,
  }) async {
    final userId = AuthService.currentUser!.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/${timestamp}_$fileName';
    
    await _storage
        .from(_bucket)
        .uploadBinary(path, Uint8List.fromList(bytes));
    final url = _storage.from(_bucket).getPublicUrl(path);
    return url;
  }

  // Upload foto profil
  static Future<String> uploadAvatar(List<int> bytes, String ext) async {
    final userId = AuthService.currentUser!.id;
    final path = 'avatars/$userId.$ext';
    await _storage.from('avatars').uploadBinary(path, Uint8List.fromList(bytes),
        fileOptions: const FileOptions(upsert: true));
    return _storage.from('avatars').getPublicUrl(path);
  }
}

// ══════════════════════════════════════════════════════════
// PLATFORM SERVICE (UC-03, UC-19, UC-20, UC-21)
// ══════════════════════════════════════════════════════════
class PlatformService {
  // UC-03: Daftar semua user
static Future<List<Map<String, dynamic>>> getUsers({
    String? role,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    var query = _db
        .from('users')
        .select('id, name, email, role::text, is_suspended, phone, ff_id, created_at')
        .isFilter('deleted_at', null); // Cast role to text
        
    if (role != null) query = query.filter('role', 'eq', role);
    if (search != null) query = query.filter('name', 'like', '%$search%');
    
    // Terapkan .order() dan .range() di paling akhir
    final res = await query
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  // UC-03: Suspend / aktifkan akun
  static Future<void> toggleSuspend(String userId, bool suspend,
      {String? reason}) async {
    // Cek target bukan platform lain
    final target =
        await _db.from('users').select('role').eq('id', userId).single();
    if (target['role'] == 'platform') throw Exception('Akses Ditolak');

    await _db.from('users').update({
      'is_suspended': suspend,
      'suspension_reason': reason,
      'suspended_at': suspend ? DateTime.now().toIso8601String() : null,
      'suspended_by': suspend ? AuthService.currentUser!.id : null,
    }).eq('id', userId);
  }

  // UC-03: Ubah role
  static Future<void> changeRole(String userId, String newRole) async {
    await _db.from('users').update({'role': newRole}).eq('id', userId);
  }

  // UC-19: Pending premium request
  static Future<List<Map<String, dynamic>>> getPremiumRequests() async {
    final res = await _db
        .from('premium_requests')
        .select('*, users(name, email)')
        .eq('status', 'pending')
        .order('created_at');
    return List<Map<String, dynamic>>.from(res);
  }

  // UC-19: Approve / reject premium
  static Future<void> processPremium(int requestId, bool approve) async {
    if (approve) {
      final req = await _db
          .from('premium_requests')
          .select('admin_user_id, package_type')
          .eq('id', requestId)
          .single();

      final months = {
        '1_month': 1,
        '3_months': 3,
        '6_months': 6,
        '1_year': 12
      }[req['package_type']] ?? 1;

      final expired = DateTime.now().add(Duration(days: months * 30));

      await _db.from('admin_profiles').update({
        'is_premium': true,
        'premium_started_at': DateTime.now().toIso8601String(),
        'premium_expired_at': expired.toIso8601String(),
      }).eq('user_id', req['admin_user_id']);

      // Notifikasi ke admin
      await _db.from('notifications').insert({
        'user_id': req['admin_user_id'],
        'type': 'announcement',
        'title': '⭐ Premium Aktif!',
        'message': 'Akun admin Anda berhasil di-upgrade ke Premium.',
        'sent_by': AuthService.currentUser!.id,
      });
    }

    await _db.from('premium_requests').update({
      'status': approve ? 'approved' : 'rejected',
      'approved_by': AuthService.currentUser!.id,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  // UC-20: Dashboard keuangan
  static Future<Map<String, dynamic>> getFinance() async {
    final summary = await _db.from('v_platform_finance').select().single();
    final txRecent = await _db
        .from('transactions')
        .select('*, users(name)')
        .order('created_at', ascending: false)
        .limit(20);
    return {'summary': summary, 'transactions': txRecent};
  }

  // UC-21: Laporan keseluruhan
  static Future<Map<String, dynamic>> getReport() async {
    final finance = await _db.from('v_platform_finance').select().single();
    if ((finance['total_scrims'] as int? ?? 0) == 0) {
      throw Exception('Data tidak cukup untuk dianalisis');
    }

    final topAdmins = await _db
        .from('admin_profiles')
        .select('*, users(name)')
        .order('total_scrims_created', ascending: false)
        .limit(10);

    final scrimStats = await _db
        .from('scrims')
        .select('status')
        .isFilter('deleted_at', null);

    return {
      'summary': finance,
      'top_admins': topAdmins,
      'scrim_stats': scrimStats,
    };
  }
}

// ══════════════════════════════════════════════════════════
// ADMIN SERVICE (Dashboard Admin)
// ══════════════════════════════════════════════════════════
class AdminService {
  static Future<Map<String, dynamic>> getDashboard() async {
    final user = AuthService.currentUser;
    
    if (user == null) {
      return {
        'total_scrims': 0,
        'total_teams': 0,
        'active_scrims': 0,
        'gross_income': 0,
        'pending_verify': 0,
      };
    }

    final uid = user.id;

    // Parallel queries
    final results = await Future.wait([
      _db
          .from('scrims')
          .select('id, status, slot_filled, slot_total, fee')
          .eq('admin_id', uid)
          .isFilter('deleted_at', null),
      _db
          .from('registrations')
          .select('id, status')
          .eq('status', 'waiting_verify'),
    ]);

    final myScrims = results[0] as List;
    final pending = results[1] as List;

    final grossIncome = myScrims.fold<int>(0, (sum, s) =>
        sum + ((s['fee'] as int) * (s['slot_filled'] as int)));

    return {
      'total_scrims': myScrims.length,
      'total_teams': myScrims.fold(0, (s, x) => s + (x['slot_filled'] as int)),
      'active_scrims': myScrims.where((s) => s['status'] == 'open').length,
      'gross_income': grossIncome,
      'pending_verify': pending.length,
    };
  }

  static Future<List<Map<String, dynamic>>> getReport(
      {String period = '30'}) async {
    final uid = AuthService.currentUser!.id;
    final since = DateTime.now().subtract(Duration(days: int.parse(period)));

    final res = await _db
        .from('v_admin_scrim_report')
        .select()
        .eq('admin_id', uid)
        .filter('scheduled_at', 'gte', since.toIso8601String())
        .order('scheduled_at', ascending: false);

    if ((res as List).isEmpty) throw Exception('Belum ada data scrim');
    return List<Map<String, dynamic>>.from(res);
  }
  // UC-18: Get scrim report with aggregated stats
  static Future<Map<String, dynamic>> getScrimReport({int days = 30}) async {
    final uid = AuthService.currentUser!.id;
    final since = days == 0
        ? DateTime(2000)
        : DateTime.now().subtract(Duration(days: days));

    final scrims = await _db
        .from('scrims')
        .select('''
          id, title, scheduled_at, slot_filled, slot_total,
          fee, prize_pool, status,
          registrations(count)
        ''')
        .eq('admin_id', uid)
        .filter('scheduled_at', 'gte', since.toIso8601String())
        .order('scheduled_at', ascending: false);

    // Calculate stats
    int totalScrims = (scrims as List).length;
    int totalTeams = 0;
    int totalRevenue = 0;
    int newScrims = 0;
    int newTeams = 0;
    double verifyRate = 0.9;
    
    final now = DateTime.now();
    for (final s in scrims) {
      final filled = s['slot_filled'] as int? ?? 0;
      totalTeams += filled;
      totalRevenue += ((s['fee'] as int? ?? 0) * filled);
      
      if (s['scheduled_at'] != null) {
        final scrimDate = DateTime.parse(s['scheduled_at']);
        if (scrimDate.isAfter(now.subtract(Duration(days: 3)))) {
          newScrims++;
          newTeams += filled;
        }
      }
    }

    return {
      'scrims': scrims,
      'stats': {
        'total_scrims': totalScrims,
        'total_teams': totalTeams,
        'total_revenue': totalRevenue,
        'net_revenue': (totalRevenue * 0.85).toInt(), // 85% after fees
        'new_scrims': newScrims,
        'new_teams': newTeams,
        'revenue_change': 18, // Placeholder
        'verification_rate': 97, // Placeholder
        'chart_data': List.filled(12, 0.5), // Placeholder
      }
    };
  }
}

// ══════════════════════════════════════════════════════════
// USER SERVICE
// ══════════════════════════════════════════════════════════
class UserService {
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final res = await _db
        .from('users')
        .select('id, name, email, phone, ff_id, team_name, username, role')
        .eq('id', userId)
        .single();
    return Map<String, dynamic>.from(res);
  }

  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    final registrations = await _db
        .from('registrations')
        .select('id')
        .eq('user_id', userId);
    
    final kills = await _db
        .from('v_user_stats')
        .select('total_kills, total_rewards')
        .eq('user_id', userId)
        .maybeSingle();

    return {
      'total_scrims': (registrations as List).length,
      'total_kills': kills?['total_kills'] ?? 0,
      'total_rewards': kills?['total_rewards'] ?? 0,
    };
  }
}

// ══════════════════════════════════════════════════════════
// BOOKING SERVICE
// ══════════════════════════════════════════════════════════
class BookingService {
  static Future<List<Map<String, dynamic>>> getAvailableSlots(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    
    // Query scrims with available slots on the given date
    final res = await _db
        .from('scrims')
        .select('''
          id, title, scheduled_at, fee, slot_filled, slot_total
        ''')
        .gte('scheduled_at', startOfDay)
        .lte('scheduled_at', endOfDay)
        .eq('status', 'open')
        .order('scheduled_at');

    // Filter for slots that have availability (slot_filled < slot_total)
    final availableSlots = (res as List)
        .where((s) => (s['slot_filled'] as int) < (s['slot_total'] as int))
        .map((s) => {
          ...s as Map<String, dynamic>,
          'filled': s['slot_filled'],
          'total': s['slot_total'],
          'scrim_id': s['id'],
        })
        .toList();

    return availableSlots;
  }}

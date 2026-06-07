// Satu file service untuk semua operasi Supabase
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

// Akses cepat client
final _db = Supabase.instance.client;
final _auth = Supabase.instance.client.auth;
final _storage = Supabase.instance.client.storage;

// ══════════════════════════════════════════════════════════
// AUTH SERVICE (UC-01, UC-09, UC-10)
// ══════════════════════════════════════════════════════════
class AuthService {
  // UC-01: Register personal account
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
        'phone': phone?.trim().isEmpty == true ? null : phone,
        'ff_id': ffId?.trim().isEmpty == true ? null : ffId,
      },
    );

    // Data tambahan ke tabel users (UUID dari Supabase Auth)
    if (res.user != null) {
      try {
        await _db.from('users').insert({
          'uuid': res.user!.id,
          'name': name,
          'email': email,
          'username': email.split('@')[0],
          'role': role,
          'phone': phone?.trim().isEmpty == true ? null : phone,
          'ff_id': ffId?.trim().isEmpty == true ? null : ffId,
        });
      } catch (e) {
        debugPrint('Error inserting user: $e');
        rethrow;
      }

      // Buat admin_profile jika role admin (skip untuk peserta)
      if (role == 'admin') {
        try {
          // Resolve bigint ID from users table
          final userProfile = await _db
              .from('users')
              .select('id')
              .eq('uuid', res.user!.id)
              .single();

          await _db.from('admin_profiles').insert({
            'user_id': userProfile['id'],  // Gunakan bigint id yang valid
            'display_name': name,
          });
        } catch (e) {
          debugPrint('Error creating admin profile: $e');
          // Jangan rethrow - user sudah berhasil dibuat
        }
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

  // Google Sign-In & Register
  static Future<AuthResponse?> signInWithGoogle({bool isTestingMock = false}) async {
    if (isTestingMock) {
      // Developer / Sandbox Testing Mock Flow:
      // Mendaftarkan / masuk secara transparan dengan email simulasi.
      // Membantu proses testing alur UI dan fungsionalitas database secara lancar tanpa hambatan API Key.
      const String mockEmail = 'gamers@google.com';
      const String mockPassword = 'GoogleMockPassword123!';
      const String mockName = 'Google Gamer';
      
      try {
        final res = await _auth.signInWithPassword(
          email: mockEmail,
          password: mockPassword,
        );
        return res;
      } catch (e) {
        // Jika belum terdaftar, sign-up secara otomatis
        try {
          await register(
            name: mockName,
            email: mockEmail,
            password: mockPassword,
            role: 'peserta',
          );
        } catch (_) {
          // Abaikan jika sudah ada di DB tapi auth state berbeda
        }
        
        final res = await _auth.signInWithPassword(
          email: mockEmail,
          password: mockPassword,
        );
        return res;
      }
    } else {
      // Production OAuth Flow via Supabase
      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'com.example.booyahhub://login-callback',
      );
      return null;
    }
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

  // Sinkronisasi atau buat profil pengguna (sangat berguna untuk Google OAuth)
  static Future<void> syncOrCreateUserProfile() async {
    final user = currentUser;
    if (user == null) return;

    try {
      // 1. Cek apakah user sudah terdaftar di tabel public.users
      final existingUser = await _db
          .from('users')
          .select('id, role')
          .eq('uuid', user.id)
          .maybeSingle();

      if (existingUser == null) {
        // 2. Jika belum ada (misal user Google baru), buat record baru
        final email = user.email ?? '';
        final name = user.userMetadata?['name'] ?? 
                     user.userMetadata?['full_name'] ?? 
                     email.split('@')[0];
        
        final String role = user.userMetadata?['role'] as String? ?? 'peserta';

        // Insert ke users table
        final newUser = await _db.from('users').insert({
          'uuid': user.id,
          'name': name,
          'email': email,
          'username': '${email.split('@')[0]}_${DateTime.now().millisecondsSinceEpoch % 10000}',
          'role': role,
        }).select('id').single();

        final int newUserId = newUser['id'];

        // 3. Jika role-nya admin, pastikan buat admin_profiles dengan id bigint yang benar!
        if (role == 'admin') {
          await _db.from('admin_profiles').insert({
            'user_id': newUserId,
            'display_name': name,
          });
        }
      } else {
        // Jika user sudah ada tetapi admin_profiles belum ada (karena bug UUID di kode lama)
        final String role = existingUser['role'] as String;
        if (role == 'admin') {
          final int userId = existingUser['id'];
          final existingProfile = await _db
              .from('admin_profiles')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();
              
          if (existingProfile == null) {
            final name = user.userMetadata?['name'] ?? 
                         user.userMetadata?['full_name'] ?? 
                         user.email?.split('@')[0] ?? 'Admin';
            await _db.from('admin_profiles').insert({
              'user_id': userId,
              'display_name': name,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing user profile: $e');
    }
  }

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
          admin_profiles(display_name, is_trusted, rating)
        ''')
        .eq('status', status)
        .isFilter('deleted_at', null); // BERHENTI DI SINI, jangan .order() dulu

    if (mode != null) query = query.eq('mode', mode);
    if (search != null && search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }
    
    // Terapkan .order() dan .range() di paling akhir
    final res = await query
        .order('is_featured', ascending: false)
        .order('scheduled_at', ascending: true)
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
          'description': ?description,
          'rules': ?rules,
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
    // Resolve UUID to bigint ID
    final userProfile = await _db
        .from('users')
        .select('id')
        .eq('uuid', AuthService.currentUser!.id)
        .single();
    final int adminBigId = userProfile['id'];

    await _db.rpc('sp_send_room_id', params: {
      'p_scrim_id': scrimId,
      'p_room_id': roomId,
      'p_room_pass': password,
      'p_admin_id': adminBigId,
      'p_extra_msg': ?extraMessage,
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
// UPDATE: REGISTRATION SERVICE (MIDTRANS INTEGRATED ONLY)
// ══════════════════════════════════════════════════════════
class RegistrationService {
  /// UC-06: Booking slot & menginisiasi Token Transaksi Midtrans
  static Future<Map<String, dynamic>> book({
    required int scrimId,
    required String teamName,
    required String captainFfId,
    required String phone,
    required int paymentAmount,
    String? midtransSnapToken, // Token dari Backend / Edge Function Anda
    List<String> members = const [],
  }) async {
    // 1. Cek ketersediaan slot real-time sebelum melakukan booking
    final scrim = await _db
        .from('scrims')
        .select('slot_filled, slot_total, status')
        .eq('id', scrimId)
        .single();

    if (scrim['status'] != 'open' ||
        (scrim['slot_filled'] as int) >= (scrim['slot_total'] as int)) {
      throw Exception('Slot Penuh – Scrim sudah ditutup');
    }

    // 2. Ambil nilai BigInt ID milik user yang sedang aktif
    final userProfile = await _db
        .from('users')
        .select('id')
        .eq('uuid', AuthService.currentUser!.id)
        .single();
    final int buyerId = userProfile['id'];

    // 3. Cek apakah user sudah punya registrasi untuk scrim ini
    final existingRegs = await _db
        .from('registrations')
        .select()
        .eq('scrim_id', scrimId)
        .eq('user_id', buyerId)
        .maybeSingle();

    Map<String, dynamic> reg;
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    if (existingRegs != null) {
      final String existingStatus = existingRegs['status'] as String;
      if (existingStatus == 'verified' || existingStatus == 'waiting_verify') {
        throw Exception('Anda sudah terdaftar di scrim ini!');
      }

      // Update registrasi yang ada (reset status ke pending_payment)
      reg = await _db
          .from('registrations')
          .update({
            'team_name': teamName,
            'captain_ff_id': captainFfId,
            'phone': phone,
            'status': 'pending_payment',
            'payment_amount': paymentAmount,
            'booking_expires_at': expiresAt.toIso8601String(),
            'midtrans_snap_token': midtransSnapToken,
            'midtrans_status': 'pending',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existingRegs['id'])
          .select()
          .single();

      // Hapus anggota tim yang lama untuk di-insert ulang
      await _db
          .from('team_members')
          .delete()
          .eq('registration_id', reg['id']);
    } else {
      // Masukkan data pendaftaran ke tabel registrations (baru)
      reg = await _db
          .from('registrations')
          .insert({
            'scrim_id': scrimId,
            'user_id': buyerId,
            'team_name': teamName,
            'captain_ff_id': captainFfId,
            'phone': phone,
            'status': 'pending_payment',
            'payment_amount': paymentAmount,
            'booking_expires_at': expiresAt.toIso8601String(),
            'midtrans_snap_token': midtransSnapToken,
          })
          .select()
          .single();
    }

    // 4. Masukkan susunan anggota tim ke tabel team_members
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

  /// Memperbarui status pendaftaran (Biasanya dipicu setelah ada respon callback dari Midtrans SDK)
  static Future<void> updatePaymentStatus({
    required int registrationId,
    required String newStatus, // 'verified', 'expired', atau 'failed'
    String? midtransTransactionId,
    String? paymentType,
  }) async {
    await _db.from('registrations').update({
      'status': newStatus,
      'midtrans_transaction_id': midtransTransactionId?.trim().isEmpty == true ? null : midtransTransactionId,
      'payment_type': paymentType?.trim().isEmpty == true ? null : paymentType,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', registrationId);
  }

  // UC-12: Riwayat scrim peserta
  static Future<List<Map<String, dynamic>>> getMyRiwayat() async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    // Resolve UUID to BIGINT ID
    final userProfile = await _db
        .from('users')
        .select('id')
        .eq('uuid', user.id)
        .maybeSingle();
    
    if (userProfile == null) return [];

    final res = await _db
        .from('v_user_riwayat')
        .select()
        .eq('user_id', userProfile['id'])
        .order('registration_id', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // UC-15: Admin lihat pendaftar di scrim
  static Future<List<Map<String, dynamic>>> getByScrim(int scrimId) async {
    final res = await _db
        .from('registrations')
        .select('''
          *, users(name, phone),
          team_members(ff_id, member_order)
        ''')
        .eq('scrim_id', scrimId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: true);
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

    // Resolve UUID to bigint ID
    final userProfile = await _db
        .from('users')
        .select('id')
        .eq('uuid', AuthService.currentUser!.id)
        .single();
    final int inputtedByBigInt = userProfile['id'];

    // Upsert semua hasil (trigger DB akan hitung poin otomatis)
    await _db.from('match_results').upsert(
      results
          .map((r) => {
                'scrim_id': scrimId,
                'registration_id': r['registration_id'],
                'team_name': r['team_name'],
                'placement': r['placement'],
                'kills': r['kills'],
                'inputted_by': inputtedByBigInt,
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
        .order('rank', ascending: true);
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

    try {
      final userProfile = await _db
          .from('users')
          .select('id')
          .eq('uuid', user.id)
          .maybeSingle();
      if (userProfile == null) return [];
      final int profileId = userProfile['id'];

      final res = await _db
          .from('prize_claims')
          .select('''
            *, scrims(title), match_results(rank, total_point)
          ''')
          .eq('user_id', profileId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error getMyClaims: $e');
      return [];
    }
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
    // Resolve UUID to bigint ID
    final userProfile = await _db
        .from('users')
        .select('id')
        .eq('uuid', AuthService.currentUser!.id)
        .single();
    final int platformBigId = userProfile['id'];

    await _db.rpc('sp_verify_claim', params: {
      'p_claim_id': claimId,
      'p_platform_id': platformBigId,
      'p_approve': approve,
      'p_reason': ?reason,
    });
  }

  // Platform: Antrian klaim pending
  static Future<List<Map<String, dynamic>>> getPendingClaims() async {
    final res = await _db
        .from('prize_claims')
        .select('*, users!prize_claims_user_id_fkey(name), scrims(title)')
        .eq('status', 'processing')
        .order('claimed_at', ascending: true);
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

    try {
      // 🟢 LANGKAH 1: Cari baris profil user berdasarkan UUID-nya untuk mendapatkan BIGINT id
      final userProfile = await _db
          .from('users')
          .select('id')
          .eq('uuid', user.id)
          .maybeSingle();
      
      if (userProfile == null) return [];
      final int profileId = userProfile['id']; // Ini baru ID berbentuk angka bulat sah!

      // 🟢 LANGKAH 2: Tembak tabel notifications menggunakan BIGINT profileId yang valid
      final res = await _db
          .from('notifications')
          .select()
          .eq('user_id', profileId) // Tembak ID angka bulat ke kolom user_id
          .order('created_at', ascending: false)
          .limit(limit);
          
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error loading notifications database: $e');
      return [];
    }
  }

  // UC-13: Tandai dibaca
  static Future<void> markRead(int id) async {
    final user = AuthService.currentUser;
    if (user == null) return;
    try {
      final userProfile = await _db
          .from('users')
          .select('id')
          .eq('uuid', user.id)
          .maybeSingle();
      if (userProfile == null) return;
      final int profileId = userProfile['id'];

      await _db.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', id).eq('user_id', profileId);
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  // Tandai semua dibaca
  static Future<void> markAllRead() async {
    final user = AuthService.currentUser;
    if (user == null) return;
    try {
      final userProfile = await _db
          .from('users')
          .select('id')
          .eq('uuid', user.id)
          .maybeSingle();
      if (userProfile == null) return;
      final int profileId = userProfile['id'];

      await _db.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('user_id', profileId).eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all notifications read: $e');
    }
  }

  // UC-17: Kirim pengumuman (Admin)
  static Future<int> sendAnnouncement({
    required String title,
    required String message,
    int? scrimId,
    String target = 'all',
  }) async {
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
    int limit = 50, // default up to 50 users
  }) async {
    var query = _db
        .from('users')
        .select('id, name, email, role, is_suspended, suspension_reason, phone, ff_id, created_at')
        .isFilter('deleted_at', null);
        
    if (role != null) query = query.eq('role', role);
    if (search != null && search.isNotEmpty) {
      query = query.or('name.ilike.%$search%,email.ilike.%$search%');
    }
    
    // Terapkan .order() dan .range() di paling akhir
    final res = await query
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  // UC-03: Suspend / aktifkan akun
  static Future<void> toggleSuspend(dynamic userId, bool suspend,
      {String? reason}) async {
    final target =
        await _db.from('users').select('role').eq('id', userId).single();
    if (target['role'] == 'platform') throw Exception('Akses Ditolak');

    await _db.from('users').update({
      'is_suspended': suspend,
      'suspension_reason': suspend ? reason : null,
      'suspended_at': suspend ? DateTime.now().toIso8601String() : null,
      'suspended_by': suspend ? AuthService.currentUser!.id : null,
    }).eq('id', userId);
  }

  // UC-03: Ubah role
  static Future<void> changeRole(dynamic userId, String newRole) async {
    await _db.from('users').update({'role': newRole}).eq('id', userId);
  }

  // UC-03: Hapus user (Soft Delete)
  static Future<void> deleteUser(dynamic userId) async {
    await _db.from('users').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // UC-19: Pending premium request
  static Future<List<Map<String, dynamic>>> getPremiumRequests() async {
    final res = await _db
        .from('premium_requests')
        .select('*, users!premium_requests_admin_user_id_fkey(name, email)')
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }

  // UC-19: Approve / reject premium
  static Future<void> processPremium(int requestId, bool approve) async {
    // Resolve UUID to bigint ID
    final userProfile = await _db
        .from('users')
        .select('id')
        .eq('uuid', AuthService.currentUser!.id)
        .single();
    final int platformBigId = userProfile['id'];

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

      // 1. Promote user role to admin in public.users
      await _db.from('users').update({
        'role': 'admin',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', req['admin_user_id']);

      // 2. Check if admin profile exists, insert if not, update if yes
      final existingProfile = await _db
          .from('admin_profiles')
          .select('id')
          .eq('user_id', req['admin_user_id'])
          .maybeSingle();

      if (existingProfile == null) {
        final userDetail = await _db
            .from('users')
            .select('name')
            .eq('id', req['admin_user_id'])
            .single();

        await _db.from('admin_profiles').insert({
          'user_id': req['admin_user_id'],
          'display_name': userDetail['name'] ?? 'Admin',
          'is_premium': true,
          'premium_started_at': DateTime.now().toIso8601String(),
          'premium_expired_at': expired.toIso8601String(),
          'total_scrims_created': 0,
          'total_participants': 0,
          'rating': 5.0,
          'is_trusted': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        await _db.from('admin_profiles').update({
          'is_premium': true,
          'premium_started_at': DateTime.now().toIso8601String(),
          'premium_expired_at': expired.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', req['admin_user_id']);
      }

      // Notifikasi ke admin
      await _db.from('notifications').insert({
        'user_id': req['admin_user_id'],
        'type': 'announcement',
        'title': '⭐ Premium Aktif!',
        'message': 'Akun admin Anda berhasil di-upgrade ke Premium.',
        'sent_by': platformBigId,
      });
    }

    await _db.from('premium_requests').update({
      'status': approve ? 'approved' : 'rejected',
      'approved_by': platformBigId,
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

    final topAdmins = await _db
        .from('admin_profiles')
        .select('display_name, is_premium, total_scrims_created, total_participants')
        .order('total_scrims_created', ascending: false)
        .limit(10);

    final userRoles = await _db
        .from('users')
        .select('role')
        .isFilter('deleted_at', null);

    final scrims = await _db
        .from('scrims')
        .select('status')
        .isFilter('deleted_at', null);

    final recentUsers = await _db
        .from('users')
        .select('created_at')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(100);

    return {
      'summary': finance,
      'top_admins': topAdmins,
      'user_roles': userRoles,
      'scrims': scrims,
      'recent_users': recentUsers,
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
        'stats': {
          'total_scrims': 0,
          'total_teams': 0,
          'active_scrims': 0,
          'gross_income': 0,
        },
        'recent_scrims': <Map<String, dynamic>>[],
      };
    }

    try {
      final userProfile = await _db
          .from('users')
          .select('id')
          .eq('uuid', user.id)
          .single();
      final int adminBigId = userProfile['id'];

      // Parallel queries
      final results = await Future.wait([
        _db
            .from('scrims')
            .select('id, status, slot_filled, slot_total, fee')
            .eq('admin_id', adminBigId)
            .isFilter('deleted_at', null),
        _db
            .from('scrims')
            .select('id, uuid, title, scheduled_at, slot_filled, slot_total, status')
            .eq('admin_id', adminBigId)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false),
      ]);

      final myScrims = results[0] as List;
      final recentScrims = results[1] as List;

      final grossIncome = myScrims.fold<int>(0, (sum, s) {
        final fee = (s['fee'] as num? ?? 0).toInt();
        final filled = (s['slot_filled'] as num? ?? 0).toInt();
        return sum + (fee * filled);
      });

      return {
        'stats': {
          'total_scrims': myScrims.length,
          'total_teams': myScrims.fold(0, (s, x) => s + ((x['slot_filled'] as num? ?? 0).toInt())),
          'active_scrims': myScrims.where((s) => s['status'] == 'open' || s['status'] == 'closed' || s['status'] == 'ongoing').length,
          'gross_income': grossIncome,
        },
        'recent_scrims': List<Map<String, dynamic>>.from(recentScrims),
      };
    } catch (e) {
      debugPrint('Error getDashboard: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getReport(
      {String period = '30'}) async {
    final uid = AuthService.currentUser!.id;
    final since = DateTime.now().subtract(Duration(days: int.parse(period)));

    final res = await _db
        .from('v_admin_scrim_report')
        .select()
        .eq('admin_id', uid)
        .gte('scheduled_at', since.toIso8601String())
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
        .select('id, name, email, phone, ff_id, team_name, username, role, avatar_url, admin_profiles(*)')
        .eq('uuid', userId) // 🟢 DIPERBAIKI: Menyaring berdasarkan string UUID, bukan BIGINT id
        .single();
    return Map<String, dynamic>.from(res);
  }

  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Hitung total scrim dari registrations
      final registrations = await _db
          .from('registrations')
          .select('id')
          .eq('user_id', userId);

      final List regList = registrations as List;
      final regIds = regList.map((r) => r['id']).toList();

      int totalKills = 0;
      int totalRewards = 0;

      if (regIds.isNotEmpty) {
        // Ambil stats dari v_user_riwayat (view yang tersedia)
        final riwayat = await _db
            .from('v_user_riwayat')
            .select('total_point')
            .eq('user_id', userId);

        for (final r in (riwayat as List)) {
          totalRewards += (r['total_point'] as int? ?? 0);
        }

        // Ambil total kills dari match_results berdasarkan registration_id
        final results = await _db
            .from('match_results')
            .select('kills')
            .inFilter('registration_id', regIds);

        for (final res in (results as List)) {
          totalKills += (res['kills'] as int? ?? 0);
        }
      }

      return {
        'total_scrims': regList.length,
        'total_kills': totalKills,
        'total_rewards': totalRewards,
      };
    } catch (e) {
      debugPrint('Error getUserStats: $e');
      return {'total_scrims': 0, 'total_kills': 0, 'total_rewards': 0};
    }
  }

  /// Register device token (FCM) for push notifications
  static Future<bool> registerDeviceToken({
    required String authUuid,
    required String token,
    required String platform, // 'android', 'ios', 'web'
  }) async {
    try {
      // 1. Resolve UUID to BIGINT ID
      final userProfile = await _db
          .from('users')
          .select('id')
          .eq('uuid', authUuid)
          .maybeSingle();

      if (userProfile == null) {
        debugPrint('Error registering device token: User profile not found for UUID: $authUuid');
        return false;
      }
      final int profileId = userProfile['id'];

      // 2. Check if token already exists for this user
      final existing = await _db
          .from('device_tokens')
          .select()
          .eq('token', token)
          .eq('user_id', profileId);

      if (existing.isNotEmpty) {
        // Token already registered, make sure it is active
        final currentToken = existing.first;
        if (currentToken['is_active'] != true) {
          await _db.from('device_tokens').update({
            'is_active': true,
            'last_used_at': DateTime.now().toIso8601String(),
          }).eq('id', currentToken['id']);
        }
        return true;
      }

      // 3. Register new token
      await _db.from('device_tokens').insert({
        'user_id': profileId,
        'token': token,
        'platform': platform,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'last_used_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error registering device token: $e');
      return false;
    }
  }

  /// Deactivate device token (on logout)
  static Future<bool> deactivateDeviceToken(String token) async {
    try {
      await _db.from('device_tokens').update({
        'is_active': false,
        'last_used_at': DateTime.now().toIso8601String(),
          }).eq('token', token);

      return true;
    } catch (e) {
      debugPrint('Error deactivating device token: $e');
      return false;
    }
  }
}

// ══════════════════════════════════════════════════════════
// BOOKING SERVICE
// ══════════════════════════════════════════════════════════
// ══════════════════════════════════════════════════════════
// BOOKING SERVICE (Optimasi Sinkronisasi Kalender UI)
// ══════════════════════════════════════════════════════════
class BookingService {
  static Future<List<Map<String, dynamic>>> getAvailableSlots(DateTime date) async {
    // Saring rentang waktu dari jam 00:00:00 sampai 23:59:59 pada hari tersebut
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    
    final res = await _db
        .from('scrims')
        .select('''
          id, title, mode, scheduled_at, fee, prize_pool, slot_filled, slot_total, is_premium,
          admin_profiles(display_name)
        ''') // 🟢 Menambahkan kolom mode, prize_pool, is_premium, dan admin_profiles agar UI Booking Screen tidak error kekurangan data
        .gte('scheduled_at', startOfDay)
        .lte('scheduled_at', endOfDay)
        .eq('status', 'open')
        .isFilter('deleted_at', null)
        .order('scheduled_at');

    // Kita return langsung tanpa membuang slot yang penuh, agar status "PENUH" merah tetap tampil di layar BooyahHub
    return (res as List).map((s) => {
      ...s as Map<String, dynamic>,
      'filled': s['slot_filled'],
      'total': s['slot_total'],
      'scrim_id': s['id'],
    }).toList();
  }
}
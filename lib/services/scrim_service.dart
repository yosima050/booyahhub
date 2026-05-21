/// Scrim & Registration Service
/// Handles: Scrims, Registrations, Team Members
/// Integrates with Midtrans payment gateway
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:booyahhub/shared/models/scrim_models.dart';
import 'package:booyahhub/shared/models/utility_models.dart';
import 'package:booyahhub/shared/models/enums/db_enums.dart';

final _db = Supabase.instance.client;

class ScrimService {
  // ════════════════════════════════════════════
  // SCRIM OPERATIONS
  // ════════════════════════════════════════════

  /// Get all open scrims (from v_scrim_list view for performance)
  static Future<List<ScrimListViewDto>> getOpenScrims({
    String? mode,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _db
          .from('v_scrim_list')
          .select()
          .eq('status', 'open');

      if (mode != null && mode.isNotEmpty) {
        query = query.eq('mode', mode);
      }

      if (search != null && search.isNotEmpty) {
        query = query.ilike('title', '%$search%');
      }

      final response = await query
          .order('scheduled_at', ascending: true)
          .range(offset, offset + limit - 1);
      return List<ScrimListViewDto>.from(
        response.map((s) => ScrimListViewDto.fromJson(s)),
      );
    } catch (e) {
      debugPrint('Error getting open scrims: $e');
      return [];
    }
  }

  /// Get scrim by ID (with details from main table)
  static Future<ScrimModel?> getScrimById(String scrimId) async {
    try {
      final response = await _db
          .from('scrims')
          .select()
          .eq('id', scrimId)
          .single();

      return ScrimModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting scrim by id: $e');
      return null;
    }
  }

/// Get scrims by admin ID
  static Future<List<ScrimModel>> getScrimsByAdminId(
    String adminId, {
    String? status,
    int limit = 50,
  }) async {
    try {
      // 1. Definisikan query dasar dengan filter utama terlebih dahulu
      var query = _db.from('scrims').select().eq('admin_id', adminId);

      // 2. Tambahkan filter opsional sebelum melakukan pengurutan data
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status); // Sekarang AMAN dan terdefinisi
      }

      // 3. Jalankan pengurutan (order) dan batasan data (limit) di paling akhir
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
          
      return List<ScrimModel>.from(
        response.map((s) => ScrimModel.fromJson(s)),
      );
    } catch (e) {
      debugPrint('Error getting scrims by admin: $e');
      return [];
    }
  } 

  /// Create new scrim (admin only)
  /// Note: prize_pool is auto-calculated via database trigger
  static Future<ScrimModel?> createScrim({
    required String adminId,
    required String title,
    required ScrimMode mode,
    required DateTime scheduledAt,
    required DateTime registrationClosesAt,
    required int slotTotal,
    required int fee,
    String? description,
  }) async {
    try {
      final response = await _db.from('scrims').insert({
        'admin_id': adminId,
        'title': title,
        'mode': mode.dbValue,
        'scheduled_at': scheduledAt.toIso8601String(),
        'registration_closes_at': registrationClosesAt.toIso8601String(),
        'slot_total': slotTotal,
        'slot_filled': 0,
        'fee': fee,
        'status': 'draft',
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return ScrimModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating scrim: $e');
      return null;
    }
  }

  /// Update scrim
  static Future<bool> updateScrim({
    required String scrimId,
    String? title,
    DateTime? scheduledAt,
    DateTime? registrationClosesAt,
    int? slotTotal,
    ScrimStatus? status,
    String? roomId,
    String? roomPassword,
    String? description,
  }) async {
    try {
      await _db.from('scrims').update({
        'title': ?title,
        if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
        if (registrationClosesAt != null)
          'registration_closes_at': registrationClosesAt.toIso8601String(),
        'slot_total': ?slotTotal,
        if (status != null) 'status': status.dbValue,
        'room_id': ?roomId,
        'room_password': ?roomPassword,
        'description': ?description,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', scrimId);

      return true;
    } catch (e) {
      debugPrint('Error updating scrim: $e');
      return false;
    }
  }

  /// Change scrim status
  static Future<bool> updateScrimStatus(
    String scrimId,
    ScrimStatus newStatus,
  ) async {
    try {
      await _db.from('scrims').update({
        'status': newStatus.dbValue,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', scrimId);

      return true;
    } catch (e) {
      debugPrint('Error updating scrim status: $e');
      return false;
    }
  }

  /// Send room ID to all verified registrations
  static Future<bool> sendRoomIdToParticipants({
    required String scrimId,
    required String roomId,
    required String roomPassword,
  }) async {
    try {
      // Update scrim with room details
      await updateScrim(
        scrimId: scrimId,
        roomId: roomId,
        roomPassword: roomPassword,
      );

      // Note: Notifications are typically sent via a backend/cloud function
      // This updates the database, triggering notifications via Supabase hooks

      return true;
    } catch (e) {
      debugPrint('Error sending room ID: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════
  // REGISTRATION OPERATIONS (Midtrans Integration)
  // ════════════════════════════════════════════

/// Get all registrations for a scrim
  static Future<List<RegistrationModel>> getScrimRegistrations(
    String scrimId, {
    String? status,
  }) async {
    try {
      // 1. Definisikan filter utama turnamen ID
      var query = _db.from('registrations').select().eq('scrim_id', scrimId);

      // 2. Tambahkan filter status jika parameter dikirim oleh aplikasi
      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status); // Sekarang AMAN dan terdefinisi
      }

      // 3. Terapkan pengurutan data kronologis di baris eksekusi akhir
      final response = await query.order('created_at', ascending: false);
      
      return List<RegistrationModel>.from(
        response.map((r) => RegistrationModel.fromJson(r)),
      );
    } catch (e) {
      debugPrint('Error getting scrim registrations: $e');
      return [];
    }
  }

  /// Get user's registrations (for their booking history)
  static Future<List<UserRiwayatViewDto>> getUserRegistrations(String userId) async {
    try {
      final response = await _db
          .from('v_user_riwayat')
          .select()
          .eq('user_id', userId)
          .order('scheduled_at', ascending: false);

      return List<UserRiwayatViewDto>.from(
        response.map((r) => UserRiwayatViewDto.fromJson(r)),
      );
    } catch (e) {
      debugPrint('Error getting user registrations: $e');
      return [];
    }
  }

  /// Get registration by ID
  static Future<RegistrationModel?> getRegistrationById(String registrationId) async {
    try {
      final response = await _db
          .from('registrations')
          .select()
          .eq('id', registrationId)
          .single();

      return RegistrationModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting registration: $e');
      return null;
    }
  }

  /// Create new registration (initiates Midtrans payment)
  /// Returns registration with Midtrans Snap Token
  static Future<RegistrationModel?> createRegistration({
    required String scrimId,
    required String userId,
    required String teamName,
    required String captainFfId,
    required String phone,
    required int paymentAmount,
    String? midtransSnapToken,
  }) async {
    try {
      final expiresAt = DateTime.now().add(Duration(minutes: 15)); // 15 min checkout limit

      final response = await _db.from('registrations').insert({
        'scrim_id': scrimId,
        'user_id': userId,
        'team_name': teamName,
        'captain_ff_id': captainFfId,
        'phone': phone,
        'status': 'pending_payment',
        'payment_amount': paymentAmount,
        'booking_expires_at': expiresAt.toIso8601String(),
        'midtrans_snap_token': midtransSnapToken,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return RegistrationModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating registration: $e');
      return null;
    }
  }

  /// Update registration status (called after Midtrans callback)
  static Future<bool> updateRegistrationStatus({
    required String registrationId,
    required RegistrationStatus newStatus,
    String? midtransTransactionId,
    String? paymentType,
  }) async {
    try {
      await _db.from('registrations').update({
        'status': newStatus.dbValue,
        'midtrans_transaction_id': ?midtransTransactionId,
        'payment_type': ?paymentType,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', registrationId);

      return true;
    } catch (e) {
      debugPrint('Error updating registration status: $e');
      return false;
    }
  }

  /// Update registration with Midtrans details (after successful payment)
  static Future<bool> updateRegistrationMidtrans({
    required String registrationId,
    required String midtransTransactionId,
    required String paymentType,
  }) async {
    try {
      await _db.from('registrations').update({
        'midtrans_transaction_id': midtransTransactionId,
        'payment_type': paymentType,
        'status': 'waiting_verify', // Auto move to verification after payment
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', registrationId);

      return true;
    } catch (e) {
      debugPrint('Error updating midtrans details: $e');
      return false;
    }
  }

  /// Get registration count for a scrim (for slot calculation)
  static Future<int> getRegistrationCount(String scrimId) async {
    try {
      final response = await _db
          .from('registrations')
          .select('id')
          .eq('scrim_id', scrimId)
          .eq('status', 'verified');

      return response.length;
    } catch (e) {
      debugPrint('Error getting registration count: $e');
      return 0;
    }
  }

  // ════════════════════════════════════════════
  // TEAM MEMBER OPERATIONS
  // ════════════════════════════════════════════

  /// Get team members for a registration
  static Future<List<TeamMemberModel>> getTeamMembers(String registrationId) async {
    try {
      final response = await _db
          .from('team_members')
          .select()
          .eq('registration_id', registrationId)
          .order('member_order', ascending: true);

      return List<TeamMemberModel>.from(
        response.map((m) => TeamMemberModel.fromJson(m)),
      );
    } catch (e) {
      debugPrint('Error getting team members: $e');
      return [];
    }
  }

  /// Add team member to registration
  static Future<TeamMemberModel?> addTeamMember({
    required String registrationId,
    required String ffId,
    required int memberOrder, // 1, 2, or 3
  }) async {
    try {
      final response = await _db.from('team_members').insert({
        'registration_id': registrationId,
        'ff_id': ffId,
        'member_order': memberOrder,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return TeamMemberModel.fromJson(response);
    } catch (e) {
      debugPrint('Error adding team member: $e');
      return null;
    }
  }

  /// Update team member
  static Future<bool> updateTeamMember({
    required String teamMemberId,
    String? ffId,
  }) async {
    try {
      await _db.from('team_members').update({
        'ff_id': ?ffId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', teamMemberId);

      return true;
    } catch (e) {
      debugPrint('Error updating team member: $e');
      return false;
    }
  }

  /// Delete team member
  static Future<bool> deleteTeamMember(String teamMemberId) async {
    try {
      await _db.from('team_members').delete().eq('id', teamMemberId);
      return true;
    } catch (e) {
      debugPrint('Error deleting team member: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════
  // REAL-TIME SUBSCRIPTIONS
  // ════════════════════════════════════════════

  /// Listen to scrim status changes in real-time
  static RealtimeChannel listenToScrimUpdates(String scrimId) {
    return _db.realtime.channel('realtime:scrims:id=eq.$scrimId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'scrims',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: scrimId,
          ),
          callback: (payload) {
            debugPrint('Scrim updated: $payload');
          },
        );
  }

  /// Listen to registration changes for a scrim
  static RealtimeChannel listenToRegistrations(String scrimId) {
    return _db.realtime.channel('realtime:registrations:scrim_id=eq.$scrimId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'registrations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'scrim_id',
            value: scrimId,
          ),
          callback: (payload) {
            debugPrint('Registration updated: $payload');
          },
        );
  }
}

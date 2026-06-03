/// User & Authentication Service
/// Handles: Users, Admin Profiles, Bank Accounts, FCM Tokens
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:booyahhub/shared/models/user_models.dart';
import 'package:booyahhub/shared/models/enums/db_enums.dart';

final _db = Supabase.instance.client;
final _auth = Supabase.instance.client.auth;

class UserService {
  // ════════════════════════════════════════════
  // USER OPERATIONS
  // ════════════════════════════════════════════

  /// Get current logged-in user with their profile
  static Future<UserModel?> getCurrentUser() async {
    try {
      final authUser = _auth.currentUser;
      if (authUser == null) return null;

      final response = await _db
          .from('users')
          .select()
          .eq('uuid', authUser.id)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  /// Get user by UUID
  static Future<UserModel?> getUserByUuid(String uuid) async {
    try {
      final response = await _db
          .from('users')
          .select()
          .eq('uuid', uuid)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting user by uuid: $e');
      return null;
    }
  }

  /// Get user by ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _db
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting user by id: $e');
      return null;
    }
  }

  /// Search users by name or email (for admin/debug)
  static Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _db
          .from('users')
          .select()
          .or('name.ilike.%$query%,email.ilike.%$query%');

      return List<UserModel>.from(
        response.map((u) => UserModel.fromJson(u)),
      );
    } catch (e) {
      debugPrint('Error getting users: $e');
      return [];
    }
  }

  /// Update user profile
  static Future<bool> updateUserProfile({
    required String userId,
    String? name,
    String? avatarUrl,
    String? phone,
    String? ffId,
  }) async {
    try {
      await _db.from('users').update({
        'name': ?name,
        'avatar_url': ?avatarUrl,
        'phone': ?phone,
        'ff_id': ?ffId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  /// Update FCM token for push notifications
  static Future<bool> updateFcmToken(String userId, String token) async {
    try {
      await _db.from('users').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════
  // ADMIN PROFILE OPERATIONS
  // ════════════════════════════════════════════

  /// Get admin profile by user ID
  static Future<AdminProfileModel?> getAdminProfile(String userId) async {
    try {
      final response = await _db
          .from('admin_profiles')
          .select()
          .eq('user_id', userId)
          .single();

      return AdminProfileModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting admin profile: $e');
      return null;
    }
  }

  /// Create admin profile (called during registration if role is 'admin')
  static Future<AdminProfileModel?> createAdminProfile({
    required String userId,
    required String displayName,
    String? bio,
  }) async {
    try {
      final response = await _db.from('admin_profiles').insert({
        'user_id': userId,
        'display_name': displayName,
        'bio': bio,
        'is_premium': false,
        'rating': 0.0,
        'is_trusted': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return AdminProfileModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating admin profile: $e');
      return null;
    }
  }

  /// Update admin profile
  static Future<bool> updateAdminProfile({
    required String userId,
    String? displayName,
    String? bio,
    bool? isPremium,
    double? rating,
    bool? isTrusted,
  }) async {
    try {
      await _db.from('admin_profiles').update({
        'display_name': ?displayName,
        'bio': ?bio,
        'is_premium': ?isPremium,
        'rating': ?rating,
        'is_trusted': ?isTrusted,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('Error updating admin profile: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════
  // BANK ACCOUNT OPERATIONS
  // ════════════════════════════════════════════

  /// Get all bank accounts for a user
  static Future<List<BankAccountModel>> getUserBankAccounts(String userId) async {
    try {
      final response = await _db
          .from('bank_accounts')
          .select()
          .eq('user_id', userId)
          .order('is_primary', ascending: false);

      return List<BankAccountModel>.from(
        response.map((b) => BankAccountModel.fromJson(b)),
      );
    } catch (e) {
      debugPrint('Error getting bank accounts: $e');
      return [];
    }
  }

  /// Get primary bank account (for payout)
  static Future<BankAccountModel?> getPrimaryBankAccount(String userId) async {
    try {
      final response = await _db
          .from('bank_accounts')
          .select()
          .eq('user_id', userId)
          .eq('is_primary', true)
          .single();

      return BankAccountModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting primary bank account: $e');
      return null;
    }
  }

  /// Add bank account
  static Future<BankAccountModel?> addBankAccount({
    required String userId,
    required BankType bankType,
    required String bankName,
    required String accountNumber,
    required String accountName,
    bool isPrimary = false,
  }) async {
    try {
      // If this is primary, unset other primary accounts
      if (isPrimary) {
        await _db
            .from('bank_accounts')
            .update({'is_primary': false})
            .eq('user_id', userId);
      }

      final response = await _db.from('bank_accounts').insert({
        'user_id': userId,
        'bank_type': bankType.dbValue,
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_name': accountName,
        'is_primary': isPrimary,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return BankAccountModel.fromJson(response);
    } catch (e) {
      debugPrint('Error adding bank account: $e');
      return null;
    }
  }

  /// Update bank account
  static Future<bool> updateBankAccount({
    required String bankAccountId,
    String? bankName,
    String? accountNumber,
    String? accountName,
    bool? isPrimary,
  }) async {
    try {
      await _db.from('bank_accounts').update({
        'bank_name': ?bankName,
        'account_number': ?accountNumber,
        'account_name': ?accountName,
        'is_primary': ?isPrimary,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bankAccountId);

      return true;
    } catch (e) {
      debugPrint('Error updating bank account: $e');
      return false;
    }
  }

  /// Set as primary bank account
  static Future<bool> setPrimaryBankAccount({
    required String userId,
    required String bankAccountId,
  }) async {
    try {
      // Unset other primary
      await _db
          .from('bank_accounts')
          .update({'is_primary': false})
          .eq('user_id', userId);

      // Set this as primary
      await _db.from('bank_accounts').update({
        'is_primary': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bankAccountId);

      return true;
    } catch (e) {
      debugPrint('Error setting primary bank: $e');
      return false;
    }
  }

  /// Delete bank account
  static Future<bool> deleteBankAccount(String bankAccountId) async {
    try {
      await _db.from('bank_accounts').delete().eq('id', bankAccountId);
      return true;
    } catch (e) {
      debugPrint('Error deleting bank account: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════
  // DEVICE TOKEN OPERATIONS (For Push Notifications)
  // ════════════════════════════════════════════

  /// Register device token
  static Future<bool> registerDeviceToken({
    required String userId,
    required String token,
    required String platform, // 'android', 'ios', 'web'
  }) async {
    try {
      // Check if token already exists
      final existing = await _db
          .from('device_tokens')
          .select()
          .eq('token', token)
          .eq('user_id', userId);

      if (existing.isNotEmpty) {
        return true; // Already registered
      }

      await _db.from('device_tokens').insert({
        'user_id': userId,
        'token': token,
        'platform': platform,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
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
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('token', token);

      return true;
    } catch (e) {
      debugPrint('Error deactivating device token: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════
  // REAL-TIME SUBSCRIPTIONS
  // ════════════════════════════════════════════

  /// Listen to user updates in real-time
  static RealtimeChannel listenToUserUpdates(String userId) {
    return _db.realtime.channel('realtime:users:id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('User updated: $payload');
          },
        );
  }
}

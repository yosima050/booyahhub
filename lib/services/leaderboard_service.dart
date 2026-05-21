/// Leaderboard & Payout Service
/// Handles: Match Results, Prize Claims, Transactions
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:booyahhub/shared/models/leaderboard_models.dart';
import 'package:booyahhub/shared/models/utility_models.dart';
import 'package:booyahhub/shared/models/enums/db_enums.dart';

final _db = Supabase.instance.client;

class LeaderboardService {
  // ════════════════════════════════════════════
  // MATCH RESULT OPERATIONS
  // ════════════════════════════════════════════

  /// Get leaderboard for a scrim (from optimized v_leaderboard view)
  static Future<List<LeaderboardViewDto>> getScrimLeaderboard(String scrimId) async {
    try {
      final response = await _db
          .from('v_leaderboard')
          .select()
          .eq('scrim_id', scrimId)
          .order('rank', ascending: true);

      return List<LeaderboardViewDto>.from(
        response.map((l) => LeaderboardViewDto.fromJson(l)),
      );
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Get match result for a specific team/registration
  static Future<MatchResultModel?> getMatchResult(String registrationId) async {
    try {
      final response = await _db
          .from('match_results')
          .select()
          .eq('registration_id', registrationId)
          .single();

      return MatchResultModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting match result: $e');
      return null;
    }
  }

  /// Create match result entry (admin records match results)
  /// Note: prize_amount is auto-calculated by database trigger based on rank
  static Future<MatchResultModel?> createMatchResult({
    required String scrimId,
    required String registrationId,
    required String teamName,
    required int placement,
    required int kills,
  }) async {
    try {
      final response = await _db.from('match_results').insert({
        'scrim_id': scrimId,
        'registration_id': registrationId,
        'team_name': teamName,
        'placement': placement,
        'kills': kills,
        // placement_point, total_point, rank, and prize_amount are calculated by DB
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return MatchResultModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating match result: $e');
      return null;
    }
  }

  /// Update match result (if admin needs to correct data)
  static Future<bool> updateMatchResult({
    required String matchResultId,
    int? placement,
    int? kills,
  }) async {
    try {
      await _db.from('match_results').update({
        'placement': ?placement,
        'kills': ?kills,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', matchResultId);

      return true;
    } catch (e) {
      debugPrint('Error updating match result: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════
  // PRIZE CLAIM OPERATIONS
  // ════════════════════════════════════════════

  /// Get all prize claims for a user
  static Future<List<PrizeClaimModel>> getUserPrizeClaims(String userId) async {
    try {
      final response = await _db
          .from('prize_claims')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<PrizeClaimModel>.from(
        response.map((p) => PrizeClaimModel.fromJson(p)),
      );
    } catch (e) {
      debugPrint('Error getting user prize claims: $e');
      return [];
    }
  }

  /// Get prize claims for a specific scrim (for admin verification)
  static Future<List<PrizeClaimModel>> getScrimPrizeClaims(String scrimId) async {
    try {
      final response = await _db
          .from('prize_claims')
          .select()
          .eq('scrim_id', scrimId)
          .order('created_at', ascending: false);

      return List<PrizeClaimModel>.from(
        response.map((p) => PrizeClaimModel.fromJson(p)),
      );
    } catch (e) {
      debugPrint('Error getting scrim prize claims: $e');
      return [];
    }
  }

  /// Get pending prize claims (for admin to verify/process)
  static Future<List<PrizeClaimModel>> getPendingPrizeClaims() async {
    try {
      final response = await _db
          .from('prize_claims')
          .select()
          .eq('status', 'processing')
          .order('created_at', ascending: true);

      return List<PrizeClaimModel>.from(
        response.map((p) => PrizeClaimModel.fromJson(p)),
      );
    } catch (e) {
      debugPrint('Error getting pending prize claims: $e');
      return [];
    }
  }

  /// Create prize claim (user claims their prize)
  static Future<PrizeClaimModel?> createPrizeClaim({
    required String userId,
    required String scrimId,
    required String matchResultId,
    required int amount,
  }) async {
    try {
      final response = await _db.from('prize_claims').insert({
        'user_id': userId,
        'scrim_id': scrimId,
        'match_result_id': matchResultId,
        'amount': amount,
        'status': 'available', // Initial status
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return PrizeClaimModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating prize claim: $e');
      return null;
    }
  }

  /// Update prize claim status (admin verifies or rejects)
  static Future<bool> updatePrizeClaimStatus({
    required String prizeClaimId,
    required ClaimStatus newStatus,
  }) async {
    try {
      await _db.from('prize_claims').update({
        'status': newStatus.dbValue,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', prizeClaimId);

      return true;
    } catch (e) {
      debugPrint('Error updating prize claim status: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════
  // TRANSACTION LEDGER OPERATIONS
  // ════════════════════════════════════════════

  /// Get all transactions for a user
  static Future<List<TransactionModel>> getUserTransactions(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final response = await _db
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<TransactionModel>.from(
        response.map((t) => TransactionModel.fromJson(t)),
      );
    } catch (e) {
      debugPrint('Error getting user transactions: $e');
      return [];
    }
  }

  /// Get transactions for a specific scrim
  static Future<List<TransactionModel>> getScrimTransactions(String scrimId) async {
    try {
      final response = await _db
          .from('transactions')
          .select()
          .eq('scrim_id', scrimId)
          .order('created_at', ascending: false);

      return List<TransactionModel>.from(
        response.map((t) => TransactionModel.fromJson(t)),
      );
    } catch (e) {
      debugPrint('Error getting scrim transactions: $e');
      return [];
    }
  }

  /// Get transactions by type (for analysis)
  static Future<List<TransactionModel>> getTransactionsByType(
    TransactionType type, {
    int limit = 100,
  }) async {
    try {
      final response = await _db
          .from('transactions')
          .select()
          .eq('type', type.dbValue)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<TransactionModel>.from(
        response.map((t) => TransactionModel.fromJson(t)),
      );
    } catch (e) {
      debugPrint('Error getting transactions by type: $e');
      return [];
    }
  }

  /// Create transaction entry (automatic via RPC or trigger)
  /// Usually called by backend during payment/payout operations
  static Future<TransactionModel?> createTransaction({
    required TransactionType type,
    required int amount,
    required String userId,
    String? scrimId,
    String? description,
  }) async {
    try {
      final response = await _db.from('transactions').insert({
        'type': type.dbValue,
        'amount': amount,
        'user_id': userId,
        'scrim_id': scrimId,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return TransactionModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating transaction: $e');
      return null;
    }
  }

  /// Get user balance (sum of all transactions)
  static Future<int> getUserBalance(String userId) async {
    try {
      final response = await _db
          .from('transactions')
          .select('amount')
          .eq('user_id', userId);

      int balance = 0;
      for (var transaction in response) {
        balance += transaction['amount'] as int? ?? 0;
      }
      return balance;
    } catch (e) {
      debugPrint('Error getting user balance: $e');
      return 0;
    }
  }

  // ════════════════════════════════════════════
  // ADMIN ANALYTICS (Views)
  // ════════════════════════════════════════════

  /// Get admin's scrim report (analytics for a specific admin)
  static Future<List<AdminScrimReportViewDto>> getAdminScrimReports(
    String adminId,
  ) async {
    try {
      final response = await _db
          .from('v_admin_scrim_report')
          .select()
          .eq('admin_id', adminId)
          .order('created_at', ascending: false);

      return List<AdminScrimReportViewDto>.from(
        response.map((r) => AdminScrimReportViewDto.fromJson(r)),
      );
    } catch (e) {
      debugPrint('Error getting admin scrim reports: $e');
      return [];
    }
  }

  /// Get platform-wide financial data (super admin only)
  static Future<PlatformFinanceViewDto?> getPlatformFinanceReport() async {
    try {
      final response = await _db
          .from('v_platform_finance')
          .select()
          .single();

      return PlatformFinanceViewDto.fromJson(response);
    } catch (e) {
      debugPrint('Error getting platform finance report: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════
  // REAL-TIME SUBSCRIPTIONS
  // ════════════════════════════════════════════

  /// Listen to leaderboard changes for a scrim
  static RealtimeChannel listenToLeaderboard(String scrimId) {
    return _db.realtime
        .channel('realtime:match_results:scrim_id=eq.$scrimId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'match_results',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'scrim_id',
            value: scrimId,
          ),
          callback: (payload) {
            debugPrint('Leaderboard updated: $payload');
          },
        );
  }

  /// Listen to prize claims
  static RealtimeChannel listenToPrizeClaims(String scrimId) {
    return _db.realtime
        .channel('realtime:prize_claims:scrim_id=eq.$scrimId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'prize_claims',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'scrim_id',
            value: scrimId,
          ),
          callback: (payload) {
            debugPrint('Prize claim updated: $payload');
          },
        );
  }

  /// Listen to user transactions in real-time
  static RealtimeChannel listenToUserTransactions(String userId) {
    return _db.realtime
        .channel('realtime:transactions:user_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('Transaction updated: $payload');
          },
        );
  }
}

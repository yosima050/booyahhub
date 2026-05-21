/// Leaderboard & Payout Models
/// Maps to: public.match_results, public.prize_claims, public.transactions
library;

import 'package:booyahhub/shared/models/enums/db_enums.dart';

// ============================================
// MATCH RESULT MODEL (public.match_results)
// Scrim stats per team
// ============================================
class MatchResultModel {
  final String id; // bigint PK
  final String scrimId; // FK -> scrims.id
  final String registrationId; // FK -> registrations.id
  final String teamName;
  final int placement; // Final position (1, 2, 3, etc.)
  final int kills; // Total kills
  final int placementPoint; // Points from placement
  final int totalPoint; // placement_point + (kills * kill_point)
  final int rank; // Rank in leaderboard
  final int prizeAmount; // Allocated automatically to rank 1, 2, 3
  final DateTime createdAt;
  final DateTime updatedAt;

  MatchResultModel({
    required this.id,
    required this.scrimId,
    required this.registrationId,
    required this.teamName,
    required this.placement,
    required this.kills,
    required this.placementPoint,
    required this.totalPoint,
    required this.rank,
    required this.prizeAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse from Supabase response
  factory MatchResultModel.fromJson(Map<String, dynamic> json) {
    return MatchResultModel(
      id: json['id'].toString(),
      scrimId: json['scrim_id'].toString(),
      registrationId: json['registration_id'].toString(),
      teamName: json['team_name'] ?? '',
      placement: json['placement'] ?? 0,
      kills: json['kills'] ?? 0,
      placementPoint: json['placement_point'] ?? 0,
      totalPoint: json['total_point'] ?? 0,
      rank: json['rank'] ?? 0,
      prizeAmount: json['prize_amount'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final map = {
      'team_name': teamName,
      'placement': placement,
      'kills': kills,
      'placement_point': placementPoint,
      'total_point': totalPoint,
      'rank': rank,
      'prize_amount': prizeAmount,
    };

    if (!forUpdate) {
      map['scrim_id'] = scrimId;
      map['registration_id'] = registrationId;
      map['created_at'] = createdAt.toIso8601String();
    }

    map['updated_at'] = updatedAt.toIso8601String();
    return map;
  }

  /// Calculated properties
  bool get isTopThree => rank <= 3;
  bool get hasWon => rank == 1;
  String get rankDisplay => rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank';

  MatchResultModel copyWith({
    int? placement,
    int? kills,
    int? placementPoint,
    int? totalPoint,
    int? rank,
    int? prizeAmount,
  }) {
    return MatchResultModel(
      id: id,
      scrimId: scrimId,
      registrationId: registrationId,
      teamName: teamName,
      placement: placement ?? this.placement,
      kills: kills ?? this.kills,
      placementPoint: placementPoint ?? this.placementPoint,
      totalPoint: totalPoint ?? this.totalPoint,
      rank: rank ?? this.rank,
      prizeAmount: prizeAmount ?? this.prizeAmount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ============================================
// PRIZE CLAIM MODEL (public.prize_claims)
// Juara 1-3 payout requests
// ============================================
class PrizeClaimModel {
  final String id; // bigint PK
  final String userId; // FK -> users.id
  final String scrimId; // FK -> scrims.id
  final String matchResultId; // FK -> match_results.id
  final int amount; // Prize amount in IDR
  final ClaimStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrizeClaimModel({
    required this.id,
    required this.userId,
    required this.scrimId,
    required this.matchResultId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse from Supabase response
  factory PrizeClaimModel.fromJson(Map<String, dynamic> json) {
    return PrizeClaimModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      scrimId: json['scrim_id'].toString(),
      matchResultId: json['match_result_id'].toString(),
      amount: json['amount'] ?? 0,
      status: ClaimStatus.fromString(json['status']),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final map = {
      'amount': amount,
      'status': status.dbValue,
    };

    if (!forUpdate) {
      map['user_id'] = userId;
      map['scrim_id'] = scrimId;
      map['match_result_id'] = matchResultId;
      map['created_at'] = createdAt.toIso8601String();
    }

    map['updated_at'] = updatedAt.toIso8601String();
    return map;
  }

  /// Calculated properties
  bool get isPending => !status.isFinalized;
  bool get isVerified => status == ClaimStatus.verified;
  bool get isRejected => status == ClaimStatus.rejected;

  /// Format amount for display (IDR currency)
  String get amountDisplay {
    const separator = '.';
    final parts = amount.toString().split('');
    final result = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) {
        result.write(separator);
      }
      result.write(parts[i]);
    }
    return 'Rp ${result.toString()}';
  }

  PrizeClaimModel copyWith({
    int? amount,
    ClaimStatus? status,
  }) {
    return PrizeClaimModel(
      id: id,
      userId: userId,
      scrimId: scrimId,
      matchResultId: matchResultId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ============================================
// TRANSACTION MODEL (public.transactions)
// Ledger of all money inside the system
// ============================================
class TransactionModel {
  final String id; // bigint PK
  final String uuid;
  final TransactionType type;
  final int amount; // In IDR
  final String userId; // FK -> users.id
  final String? scrimId; // FK -> scrims.id (nullable for general transactions)
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.uuid,
    required this.type,
    required this.amount,
    required this.userId,
    this.scrimId,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse from Supabase response
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'].toString(),
      uuid: json['uuid'] ?? '',
      type: TransactionType.fromString(json['type']),
      amount: json['amount'] ?? 0,
      userId: json['user_id'].toString(),
      scrimId: json['scrim_id']?.toString(),
      description: json['description'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final map = {
      'type': type.dbValue,
      'amount': amount,
      'user_id': userId,
      'scrim_id': scrimId,
      'description': description,
    };

    if (!forUpdate) {
      map['uuid'] = uuid;
      map['created_at'] = createdAt.toIso8601String();
    }

    map['updated_at'] = updatedAt.toIso8601String();
    return map;
  }

  /// Calculated properties
  bool get isIncoming => type.isIncoming;
  bool get isOutgoing => type.isOutgoing;

  /// Format amount for display (IDR currency)
  String get amountDisplay {
    const separator = '.';
    final parts = amount.toString().split('');
    final result = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) {
        result.write(separator);
      }
      result.write(parts[i]);
    }
    return 'Rp ${result.toString()}';
  }

  /// Display with sign
  String get amountWithSign => isIncoming ? '+$amountDisplay' : '-$amountDisplay';

  TransactionModel copyWith({
    TransactionType? type,
    int? amount,
    String? scrimId,
    String? description,
  }) {
    return TransactionModel(
      id: id,
      uuid: uuid,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      userId: userId,
      scrimId: scrimId ?? this.scrimId,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

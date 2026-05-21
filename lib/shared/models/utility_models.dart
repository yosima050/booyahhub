/// Utility & Views Models
/// Maps to: public.notifications, public.device_tokens, public.scrim_announcements
/// Views: v_scrim_list, v_leaderboard, v_user_riwayat, v_admin_scrim_report, v_platform_finance
library;
import 'package:booyahhub/shared/models/enums/db_enums.dart';

// ============================================
// NOTIFICATION MODEL (public.notifications)
// ============================================
class NotificationModel {
  final String id; // bigint PK
  final String userId; // FK -> users.id
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data; // jsonb
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse from Supabase response
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      type: NotificationType.fromString(json['type']),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final map = {
      'title': title,
      'message': message,
      'type': type.dbValue,
      'data': data,
      'is_read': isRead,
    };

    if (!forUpdate) {
      map['user_id'] = userId;
      map['created_at'] = createdAt.toIso8601String();
    }

    map['updated_at'] = updatedAt.toIso8601String();
    return map;
  }

  NotificationModel copyWith({
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ============================================
// DEVICE TOKEN MODEL (public.device_tokens)
// For Push Notifications
// ============================================
class DeviceTokenModel {
  final String id; // bigint PK
  final String userId; // FK -> users.id
  final String token;
  final String platform; // 'android', 'ios', 'web'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeviceTokenModel({
    required this.id,
    required this.userId,
    required this.token,
    required this.platform,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse from Supabase response
  factory DeviceTokenModel.fromJson(Map<String, dynamic> json) {
    return DeviceTokenModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      token: json['token'] ?? '',
      platform: json['platform'] ?? 'android',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final map = {
      'token': token,
      'platform': platform,
      'is_active': isActive,
    };

    if (!forUpdate) {
      map['user_id'] = userId;
      map['created_at'] = createdAt.toIso8601String();
    }

    map['updated_at'] = updatedAt.toIso8601String();
    return map;
  }

  DeviceTokenModel copyWith({
    String? token,
    String? platform,
    bool? isActive,
  }) {
    return DeviceTokenModel(
      id: id,
      userId: userId,
      token: token ?? this.token,
      platform: platform ?? this.platform,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ============================================
// SCRIM ANNOUNCEMENT MODEL (public.scrim_announcements)
// ============================================
class ScrimAnnouncementModel {
  final String id; // bigint PK
  final String scrimId; // FK -> scrims.id
  final String adminId; // FK -> users.id
  final String title;
  final String message;
  final String target; // 'all', 'verified', 'pending'
  final DateTime createdAt;
  final DateTime updatedAt;

  ScrimAnnouncementModel({
    required this.id,
    required this.scrimId,
    required this.adminId,
    required this.title,
    required this.message,
    required this.target,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse from Supabase response
  factory ScrimAnnouncementModel.fromJson(Map<String, dynamic> json) {
    return ScrimAnnouncementModel(
      id: json['id'].toString(),
      scrimId: json['scrim_id'].toString(),
      adminId: json['admin_id'].toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      target: json['target'] ?? 'all',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final map = {
      'title': title,
      'message': message,
      'target': target,
    };

    if (!forUpdate) {
      map['scrim_id'] = scrimId;
      map['admin_id'] = adminId;
      map['created_at'] = createdAt.toIso8601String();
    }

    map['updated_at'] = updatedAt.toIso8601String();
    return map;
  }

  ScrimAnnouncementModel copyWith({
    String? title,
    String? message,
    String? target,
  }) {
    return ScrimAnnouncementModel(
      id: id,
      scrimId: scrimId,
      adminId: adminId,
      title: title ?? this.title,
      message: message ?? this.message,
      target: target ?? this.target,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ============================================
// DATABASE VIEWS - High-Performance Fetch Models
// ============================================

/// VIEW: v_scrim_list
/// Returns high-performance list for browsing open scrims
class ScrimListViewDto {
  final String scrimId;
  final String scrimUuid;
  final String title;
  final String adminName;
  final String mode;
  final DateTime scheduledAt;
  final DateTime registrationClosesAt;
  final int slotTotal;
  final int slotFilled;
  final int fee;
  final int prizePool;
  final ScrimStatus status;
  final bool adminIsPremium;
  final double adminRating;

  ScrimListViewDto({
    required this.scrimId,
    required this.scrimUuid,
    required this.title,
    required this.adminName,
    required this.mode,
    required this.scheduledAt,
    required this.registrationClosesAt,
    required this.slotTotal,
    required this.slotFilled,
    required this.fee,
    required this.prizePool,
    required this.status,
    required this.adminIsPremium,
    required this.adminRating,
  });

  factory ScrimListViewDto.fromJson(Map<String, dynamic> json) {
    return ScrimListViewDto(
      scrimId: json['scrim_id'].toString(),
      scrimUuid: json['scrim_uuid'] ?? '',
      title: json['title'] ?? '',
      adminName: json['admin_name'] ?? '',
      mode: json['mode'] ?? 'battle_royale',
      scheduledAt: DateTime.parse(json['scheduled_at'] ?? DateTime.now().toIso8601String()),
      registrationClosesAt: DateTime.parse(json['registration_closes_at'] ?? DateTime.now().toIso8601String()),
      slotTotal: json['slot_total'] ?? 100,
      slotFilled: json['slot_filled'] ?? 0,
      fee: json['fee'] ?? 0,
      prizePool: json['prize_pool'] ?? 0,
      status: ScrimStatus.fromString(json['status']),
      adminIsPremium: json['admin_is_premium'] ?? false,
      adminRating: (json['admin_rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  int get slotRemaining => slotTotal - slotFilled;
  bool get isFull => slotFilled >= slotTotal;
}

/// VIEW: v_leaderboard
/// Returns standardized leaderboard array ordered by rank and point systems
class LeaderboardViewDto {
  final String registrationId;
  final String teamName;
  final int rank;
  final int totalPoint;
  final int kills;
  final int placement;
  final int prizeAmount;

  LeaderboardViewDto({
    required this.registrationId,
    required this.teamName,
    required this.rank,
    required this.totalPoint,
    required this.kills,
    required this.placement,
    required this.prizeAmount,
  });

  factory LeaderboardViewDto.fromJson(Map<String, dynamic> json) {
    return LeaderboardViewDto(
      registrationId: json['registration_id'].toString(),
      teamName: json['team_name'] ?? '',
      rank: json['rank'] ?? 0,
      totalPoint: json['total_point'] ?? 0,
      kills: json['kills'] ?? 0,
      placement: json['placement'] ?? 0,
      prizeAmount: json['prize_amount'] ?? 0,
    );
  }
}

/// VIEW: v_user_riwayat
/// Returns detailed tournament logs for a specific user
class UserRiwayatViewDto {
  final String scrimId;
  final String scrimTitle;
  final String mode;
  final DateTime scheduledAt;
  final int fee;
  final RegistrationStatus registrationStatus;
  final int? rank;
  final int? totalPoint;
  final int? prizeAmount;
  final String? roomId;

  UserRiwayatViewDto({
    required this.scrimId,
    required this.scrimTitle,
    required this.mode,
    required this.scheduledAt,
    required this.fee,
    required this.registrationStatus,
    this.rank,
    this.totalPoint,
    this.prizeAmount,
    this.roomId,
  });

  factory UserRiwayatViewDto.fromJson(Map<String, dynamic> json) {
    return UserRiwayatViewDto(
      scrimId: json['scrim_id'].toString(),
      scrimTitle: json['scrim_title'] ?? '',
      mode: json['mode'] ?? 'battle_royale',
      scheduledAt: DateTime.parse(json['scheduled_at'] ?? DateTime.now().toIso8601String()),
      fee: json['fee'] ?? 0,
      registrationStatus: RegistrationStatus.fromString(json['registration_status']),
      rank: json['rank'],
      totalPoint: json['total_point'],
      prizeAmount: json['prize_amount'],
      roomId: json['room_id'],
    );
  }
}

/// VIEW: v_admin_scrim_report
/// Analytical stats for tournament creators
class AdminScrimReportViewDto {
  final String scrimId;
  final String title;
  final int registrationCount;
  final int verifiedCount;
  final int pendingCount;
  final int totalRegistrationFees;
  final int platformCut;
  final int adminEarnings;

  AdminScrimReportViewDto({
    required this.scrimId,
    required this.title,
    required this.registrationCount,
    required this.verifiedCount,
    required this.pendingCount,
    required this.totalRegistrationFees,
    required this.platformCut,
    required this.adminEarnings,
  });

  factory AdminScrimReportViewDto.fromJson(Map<String, dynamic> json) {
    return AdminScrimReportViewDto(
      scrimId: json['scrim_id'].toString(),
      title: json['title'] ?? '',
      registrationCount: json['registration_count'] ?? 0,
      verifiedCount: json['verified_count'] ?? 0,
      pendingCount: json['pending_count'] ?? 0,
      totalRegistrationFees: json['total_registration_fees'] ?? 0,
      platformCut: json['platform_cut'] ?? 0,
      adminEarnings: json['admin_earnings'] ?? 0,
    );
  }
}

/// VIEW: v_platform_finance
/// Super-admin matrix counting cash flows, global balances, pending verifications
class PlatformFinanceViewDto {
  final int totalIncomingFees;
  final int totalOutgoingPayouts;
  final int totalPlatformFees;
  final int pendingPayments;
  final int pendingVerifications;
  final int totalActiveUsers;
  final int totalActiveScrims;

  PlatformFinanceViewDto({
    required this.totalIncomingFees,
    required this.totalOutgoingPayouts,
    required this.totalPlatformFees,
    required this.pendingPayments,
    required this.pendingVerifications,
    required this.totalActiveUsers,
    required this.totalActiveScrims,
  });

  factory PlatformFinanceViewDto.fromJson(Map<String, dynamic> json) {
    return PlatformFinanceViewDto(
      totalIncomingFees: json['total_incoming_fees'] ?? 0,
      totalOutgoingPayouts: json['total_outgoing_payouts'] ?? 0,
      totalPlatformFees: json['total_platform_fees'] ?? 0,
      pendingPayments: json['pending_payments'] ?? 0,
      pendingVerifications: json['pending_verifications'] ?? 0,
      totalActiveUsers: json['total_active_users'] ?? 0,
      totalActiveScrims: json['total_active_scrims'] ?? 0,
    );
  }

  int get netBalance => totalIncomingFees - totalOutgoingPayouts;
}

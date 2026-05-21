/// Scrim & Tournament Models
/// Maps to: public.scrims, public.registrations, public.team_members
library;

import 'package:booyahhub/shared/models/enums/db_enums.dart';

// ============================================
// SCRIM MODEL (public.scrims) - Core Event
// ============================================
class ScrimModel {
  final String id; // bigint PK
  final String uuid;
  final String adminId; // FK -> users.id
  final String title;
  final ScrimMode mode;
  final DateTime scheduledAt;
  final DateTime registrationClosesAt;
  final int slotTotal; // Max 100
  final int slotFilled;
  final int fee; // Registration fee (0 if free)
  final int prizePool; // Auto-calculated via Database Trigger
  final ScrimStatus status;
  final String? roomId;
  final String? roomPassword;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScrimModel({
    required this.id,
    required this.uuid,
    required this.adminId,
    required this.title,
    required this.mode,
    required this.scheduledAt,
    required this.registrationClosesAt,
    required this.slotTotal,
    required this.slotFilled,
    required this.fee,
    required this.prizePool,
    required this.status,
    this.roomId,
    this.roomPassword,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse from Supabase response
  factory ScrimModel.fromJson(Map<String, dynamic> json) {
    return ScrimModel(
      id: json['id'].toString(),
      uuid: json['uuid'] ?? '',
      adminId: json['admin_id'].toString(),
      title: json['title'] ?? '',
      mode: ScrimMode.fromString(json['mode']),
      scheduledAt: DateTime.parse(json['scheduled_at'] ?? DateTime.now().toIso8601String()),
      registrationClosesAt: DateTime.parse(json['registration_closes_at'] ?? DateTime.now().toIso8601String()),
      slotTotal: json['slot_total'] ?? 100,
      slotFilled: json['slot_filled'] ?? 0,
      fee: json['fee'] ?? 0,
      prizePool: json['prize_pool'] ?? 0,
      status: ScrimStatus.fromString(json['status']),
      roomId: json['room_id'],
      roomPassword: json['room_password'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final map = {
      'title': title,
      'mode': mode.dbValue,
      'scheduled_at': scheduledAt.toIso8601String(),
      'registration_closes_at': registrationClosesAt.toIso8601String(),
      'slot_total': slotTotal,
      'slot_filled': slotFilled,
      'fee': fee,
      'prize_pool': prizePool,
      'status': status.dbValue,
      'room_id': roomId,
      'room_password': roomPassword,
      'description': description,
    };

    if (!forUpdate) {
      map['uuid'] = uuid;
      map['admin_id'] = adminId;
      map['created_at'] = createdAt.toIso8601String();
    }

    map['updated_at'] = updatedAt.toIso8601String();
    return map;
  }

  /// Calculated properties
  int get slotRemaining => slotTotal - slotFilled;
  double get slotPercentage => slotTotal > 0 ? (slotFilled / slotTotal) * 100 : 0;
  bool get isFull => slotFilled >= slotTotal;
  bool get isAlmostFull => slotPercentage >= 70;
  bool get isRegistrationOpen => registrationClosesAt.isAfter(DateTime.now()) && status == ScrimStatus.open;
  bool get canRegister => !isFull && isRegistrationOpen;
  Duration get registrationTimeLeft => registrationClosesAt.difference(DateTime.now());
  Duration get timeUntilStart => scheduledAt.difference(DateTime.now());

  ScrimModel copyWith({
    String? title,
    ScrimMode? mode,
    DateTime? scheduledAt,
    DateTime? registrationClosesAt,
    int? slotTotal,
    int? slotFilled,
    int? fee,
    int? prizePool,
    ScrimStatus? status,
    String? roomId,
    String? roomPassword,
    String? description,
  }) {
    return ScrimModel(
      id: id,
      uuid: uuid,
      adminId: adminId,
      title: title ?? this.title,
      mode: mode ?? this.mode,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      registrationClosesAt: registrationClosesAt ?? this.registrationClosesAt,
      slotTotal: slotTotal ?? this.slotTotal,
      slotFilled: slotFilled ?? this.slotFilled,
      fee: fee ?? this.fee,
      prizePool: prizePool ?? this.prizePool,
      status: status ?? this.status,
      roomId: roomId ?? this.roomId,
      roomPassword: roomPassword ?? this.roomPassword,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ============================================
// REGISTRATION MODEL (public.registrations)
// Team Bookings - Configured for Midtrans Automations
// ============================================
class RegistrationModel {
  final String id; // bigint PK
  final String uuid; // Acts as order_id for Midtrans transaction
  final String scrimId; // FK -> scrims.id
  final String userId; // FK -> users.id (The team leader)
  final String teamName;
  final String captainFfId; // Captain's Free Fire ID
  final String phone;
  final RegistrationStatus status;
  final int paymentAmount;
  final DateTime bookingExpiresAt; // Auto-set to 15-30 mins checkout limit
  final String? midtransSnapToken; // For opening Midtrans Snap Pop-up in Flutter
  final String? midtransTransactionId; // Official reference from Midtrans API response
  final String? paymentType; // e.g., 'qris', 'gopay', 'bank_transfer'
  final DateTime createdAt;
  final DateTime updatedAt;

  RegistrationModel({
    required this.id,
    required this.uuid,
    required this.scrimId,
    required this.userId,
    required this.teamName,
    required this.captainFfId,
    required this.phone,
    required this.status,
    required this.paymentAmount,
    required this.bookingExpiresAt,
    this.midtransSnapToken,
    this.midtransTransactionId,
    this.paymentType,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse from Supabase response
  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      id: json['id'].toString(),
      uuid: json['uuid'] ?? '',
      scrimId: json['scrim_id'].toString(),
      userId: json['user_id'].toString(),
      teamName: json['team_name'] ?? '',
      captainFfId: json['captain_ff_id'] ?? '',
      phone: json['phone'] ?? '',
      status: RegistrationStatus.fromString(json['status']),
      paymentAmount: json['payment_amount'] ?? 0,
      bookingExpiresAt: DateTime.parse(json['booking_expires_at'] ?? DateTime.now().toIso8601String()),
      midtransSnapToken: json['midtrans_snap_token'],
      midtransTransactionId: json['midtrans_transaction_id'],
      paymentType: json['payment_type'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final map = {
      'team_name': teamName,
      'captain_ff_id': captainFfId,
      'phone': phone,
      'status': status.dbValue,
      'payment_amount': paymentAmount,
      'booking_expires_at': bookingExpiresAt.toIso8601String(),
      'midtrans_snap_token': midtransSnapToken,
      'midtrans_transaction_id': midtransTransactionId,
      'payment_type': paymentType,
    };

    if (!forUpdate) {
      map['uuid'] = uuid;
      map['scrim_id'] = scrimId;
      map['user_id'] = userId;
      map['created_at'] = createdAt.toIso8601String();
    }

    map['updated_at'] = updatedAt.toIso8601String();
    return map;
  }

  /// Calculated properties
  bool get isExpired => bookingExpiresAt.isBefore(DateTime.now());
  Duration get timeUntilExpiry => bookingExpiresAt.difference(DateTime.now());
  bool get needsPayment => status.needsPayment;
  bool get isVerified => status.isVerified;

  RegistrationModel copyWith({
    String? teamName,
    String? captainFfId,
    String? phone,
    RegistrationStatus? status,
    int? paymentAmount,
    DateTime? bookingExpiresAt,
    String? midtransSnapToken,
    String? midtransTransactionId,
    String? paymentType,
  }) {
    return RegistrationModel(
      id: id,
      uuid: uuid,
      scrimId: scrimId,
      userId: userId,
      teamName: teamName ?? this.teamName,
      captainFfId: captainFfId ?? this.captainFfId,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      bookingExpiresAt: bookingExpiresAt ?? this.bookingExpiresAt,
      midtransSnapToken: midtransSnapToken ?? this.midtransSnapToken,
      midtransTransactionId: midtransTransactionId ?? this.midtransTransactionId,
      paymentType: paymentType ?? this.paymentType,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ============================================
// TEAM MEMBER MODEL (public.team_members)
// Players inside the registered team
// ============================================
class TeamMemberModel {
  final String id; // bigint PK
  final String registrationId; // FK -> registrations.id
  final String ffId; // Free Fire ID
  final int memberOrder; // 1 to 3
  final DateTime createdAt;
  final DateTime updatedAt;

  TeamMemberModel({
    required this.id,
    required this.registrationId,
    required this.ffId,
    required this.memberOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse from Supabase response
  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      id: json['id'].toString(),
      registrationId: json['registration_id'].toString(),
      ffId: json['ff_id'] ?? '',
      memberOrder: json['member_order'] ?? 1,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final map = {
      'ff_id': ffId,
      'member_order': memberOrder,
    };

    if (!forUpdate) {
      map['registration_id'] = registrationId;
      map['created_at'] = createdAt.toIso8601String();
    }

    map['updated_at'] = updatedAt.toIso8601String();
    return map;
  }

  TeamMemberModel copyWith({
    String? ffId,
    int? memberOrder,
  }) {
    return TeamMemberModel(
      id: id,
      registrationId: registrationId,
      ffId: ffId ?? this.ffId,
      memberOrder: memberOrder ?? this.memberOrder,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

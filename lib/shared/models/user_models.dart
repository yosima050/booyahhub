/// User & Authentication Models
/// Maps to: public.users, public.admin_profiles, public.bank_accounts
library;
import 'package:booyahhub/shared/models/enums/db_enums.dart';

// ============================================
// USER MODEL (public.users)
// ============================================
class UserModel {
  final String id; // bigint PK
  final String uuid; // uuid - links to auth.users.id
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final String? phone;
  final String? ffId; // Free Fire Game ID
  final String? fcmToken; // For Push Notifications
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.phone,
    this.ffId,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse from Supabase response
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: UserRole.fromString(json['role']),
      avatarUrl: json['avatar_url'],
      phone: json['phone'],
      ffId: json['ff_id'],
      fcmToken: json['fcm_token'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final map = {
      'name': name,
      'email': email,
      'role': role.value,
      'avatar_url': avatarUrl,
      'phone': phone,
      'ff_id': ffId,
      'fcm_token': fcmToken,
    };

    if (!forUpdate) {
      map['uuid'] = uuid;
      map['created_at'] = createdAt.toIso8601String();
    }

    map['updated_at'] = updatedAt.toIso8601String();
    return map;
  }

  /// Create copy with modifications
  UserModel copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? avatarUrl,
    String? phone,
    String? ffId,
    String? fcmToken,
  }) {
    return UserModel(
      id: id,
      uuid: uuid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      ffId: ffId ?? this.ffId,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ============================================
// ADMIN PROFILE MODEL (public.admin_profiles)
// ============================================
class AdminProfileModel {
  final String id; // bigint PK
  final String userId; // FK -> users.id (Unique)
  final String displayName;
  final String? bio;
  final bool isPremium;
  final double rating; // 0.00 to 5.00
  final bool isTrusted;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminProfileModel({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.isPremium = false,
    this.rating = 0.0,
    this.isTrusted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse from Supabase response
  factory AdminProfileModel.fromJson(Map<String, dynamic> json) {
    return AdminProfileModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      displayName: json['display_name'] ?? '',
      bio: json['bio'],
      isPremium: json['is_premium'] ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isTrusted: json['is_trusted'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final map = {
      'display_name': displayName,
      'bio': bio,
      'is_premium': isPremium,
      'rating': rating,
      'is_trusted': isTrusted,
    };

    if (!forUpdate) {
      map['user_id'] = userId;
      map['created_at'] = createdAt.toIso8601String();
    }

    map['updated_at'] = updatedAt.toIso8601String();
    return map;
  }

  AdminProfileModel copyWith({
    String? displayName,
    String? bio,
    bool? isPremium,
    double? rating,
    bool? isTrusted,
  }) {
    return AdminProfileModel(
      id: id,
      userId: userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      isPremium: isPremium ?? this.isPremium,
      rating: rating ?? this.rating,
      isTrusted: isTrusted ?? this.isTrusted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ============================================
// BANK ACCOUNT MODEL (public.bank_accounts)
// For payout options
// ============================================
class BankAccountModel {
  final String id; // bigint PK
  final String userId; // FK -> users.id
  final BankType bankType;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  BankAccountModel({
    required this.id,
    required this.userId,
    required this.bankType,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    this.isPrimary = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parse from Supabase response
  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      bankType: BankType.fromString(json['bank_type']),
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      accountName: json['account_name'] ?? '',
      isPrimary: json['is_primary'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final map = {
      'bank_type': bankType.dbValue,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_name': accountName,
      'is_primary': isPrimary,
    };

    if (!forUpdate) {
      map['user_id'] = userId;
      map['created_at'] = createdAt.toIso8601String();
    }

    map['updated_at'] = updatedAt.toIso8601String();
    return map;
  }

  /// Display format for UI
  String get displayName => '$bankName - $accountNumber';

  BankAccountModel copyWith({
    String? bankName,
    String? accountNumber,
    String? accountName,
    bool? isPrimary,
  }) {
    return BankAccountModel(
      id: id,
      userId: userId,
      bankType: bankType,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

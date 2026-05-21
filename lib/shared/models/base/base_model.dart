/// Base Model - Common fields for all database models
/// Provides timestamps and conversion utilities
abstract class BaseModel {
  final String id;
  final String uuid;
  final DateTime createdAt;
  final DateTime updatedAt;

  BaseModel({
    required this.id,
    required this.uuid,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson();

  /// Parse from Supabase response
  static T fromJson<T>(Map<String, dynamic> json) {
    throw UnimplementedError();
  }
}

/// Timestamp utility extension
extension TimestampExt on DateTime {
  /// Format for display
  String toDisplayFormat() => '$day/$month/$year ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:booyahhub/shared/models/utility_models.dart';
import 'package:booyahhub/shared/models/enums/db_enums.dart';

final _db = Supabase.instance.client;

class NotificationService {
  // ════════════════════════════════════════════
  // NOTIFICATION OPERATIONS
  // ════════════════════════════════════════════

  static Future<List<NotificationModel>> getUserNotifications(
    String userId, {
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    try {
      // 1. Inisialisasi query dasar untuk filter
      var query = _db.from('notifications').select().eq('user_id', userId);

      // 2. Jalankan filter opsional sebelum melakukan ordering
      if (unreadOnly) {
        query = query.eq('is_read', false); // Sekarang aman karena tipe data masih FilterBuilder
      }

      // 3. Lakukan order dan limit di akhir saat mengeksekusi ke database
      final response = await query
          .order('created_at', ascending: false) // TransformBuilder dipanggil paling akhir
          .limit(limit);

      return List<NotificationModel>.from(
        response.map((n) => NotificationModel.fromJson(n)),
      );
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await _db
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Create notification (typically called by backend/cloud functions)
  static Future<NotificationModel?> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _db.from('notifications').insert({
        'user_id': userId,
        'type': type.dbValue,
        'title': title,
        'message': message,
        'data': data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating notification: $e');
      return null;
    }
  }

  /// Mark notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _db.from('notifications').update({
        'is_read': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);

      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for a user
  static Future<bool> markAllNotificationsAsRead(String userId) async {
    try {
      await _db.from('notifications').update({
        'is_read': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId).eq('is_read', false);

      return true;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      return false;
    }
  }

  /// Delete notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      await _db.from('notifications').delete().eq('id', notificationId);
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════
  // SCRIM ANNOUNCEMENT OPERATIONS
  // ════════════════════════════════════════════

  /// Get announcements for a scrim
  static Future<List<ScrimAnnouncementModel>> getScrimAnnouncements(
    String scrimId,
  ) async {
    try {
      final response = await _db
          .from('scrim_announcements')
          .select()
          .eq('scrim_id', scrimId)
          .order('created_at', ascending: false);

      return List<ScrimAnnouncementModel>.from(
        response.map((a) => ScrimAnnouncementModel.fromJson(a)),
      );
    } catch (e) {
      debugPrint('Error getting announcements: $e');
      return [];
    }
  }

  /// Get announcement by ID
  static Future<ScrimAnnouncementModel?> getAnnouncementById(
    String announcementId,
  ) async {
    try {
      final response = await _db
          .from('scrim_announcements')
          .select()
          .eq('id', announcementId)
          .single();

      return ScrimAnnouncementModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting announcement: $e');
      return null;
    }
  }

  /// Create announcement (admin only)
  static Future<ScrimAnnouncementModel?> createAnnouncement({
    required String scrimId,
    required String adminId,
    required String title,
    required String message,
    String target = 'all', // 'all', 'verified', 'pending'
  }) async {
    try {
      final response = await _db.from('scrim_announcements').insert({
        'scrim_id': scrimId,
        'admin_id': adminId,
        'title': title,
        'message': message,
        'target': target,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return ScrimAnnouncementModel.fromJson(response);
    } catch (e) {
      debugPrint('Error creating announcement: $e');
      return null;
    }
  }

  /// Update announcement
  static Future<bool> updateAnnouncement({
    required String announcementId,
    String? title,
    String? message,
    String? target,
  }) async {
    try {
      await _db.from('scrim_announcements').update({
        'title': ?title,
        'message': ?message,
        'target': ?target,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', announcementId);

      return true;
    } catch (e) {
      debugPrint('Error updating announcement: $e');
      return false;
    }
  }

  /// Delete announcement
  static Future<bool> deleteAnnouncement(String announcementId) async {
    try {
      await _db.from('scrim_announcements').delete().eq('id', announcementId);
      return true;
    } catch (e) {
      debugPrint('Error deleting announcement: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════
  // NOTIFICATION TYPES DISPATCHING
  // Helper methods for common notification patterns
  // ════════════════════════════════════════════

  /// Notify payment confirmed
  static Future<void> notifyPaymentConfirmed({
    required String userId,
    required String scrimTitle,
    required String registrationId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.paymentConfirmed,
      title: 'Pembayaran Dikonfirmasi!',
      message: 'Pembayaran untuk $scrimTitle telah dikonfirmasi.',
      data: {'registration_id': registrationId},
    );
  }

  /// Notify payment rejected
  static Future<void> notifyPaymentRejected({
    required String userId,
    required String scrimTitle,
    required String registrationId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.paymentRejected,
      title: 'Pembayaran Ditolak',
      message: 'Pembayaran untuk $scrimTitle ditolak. Silakan coba lagi.',
      data: {'registration_id': registrationId},
    );
  }

  /// Notify room ID sent
  static Future<void> notifyRoomIdSent({
    required String userId,
    required String scrimTitle,
    required String roomId,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.roomIdSent,
      title: 'Room ID Dikirim',
      message: 'Room ID untuk $scrimTitle: $roomId',
      data: {'room_id': roomId},
    );
  }

  /// Notify schedule changed
  static Future<void> notifyScheduleChanged({
    required String userId,
    required String scrimTitle,
    required DateTime newTime,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.scheduleChanged,
      title: 'Jadwal Berubah',
      message: '$scrimTitle dijadwalkan ulang ke ${newTime.toString()}',
      data: {'new_time': newTime.toIso8601String()},
    );
  }

  /// Notify match result published
  static Future<void> notifyMatchResult({
    required String userId,
    required String scrimTitle,
    required int rank,
    required int points,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.matchResult,
      title: 'Hasil Pertandingan',
      message: '$scrimTitle: Rank #$rank dengan $points poin',
      data: {'rank': rank, 'points': points},
    );
  }

  /// Notify prize processing started
  static Future<void> notifyPrizeProcessing({
    required String userId,
    required String scrimTitle,
    required int amount,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.prizeProcessing,
      title: 'Hadiah Diproses',
      message: 'Hadiah Anda untuk $scrimTitle sedang diproses: Rp $amount',
      data: {'amount': amount},
    );
  }

  /// Notify prize sent
  static Future<void> notifyPrizeSent({
    required String userId,
    required String scrimTitle,
    required int amount,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.prizeSent,
      title: 'Hadiah Dikirim!',
      message: 'Hadiah Anda untuk $scrimTitle telah dikirim: Rp $amount',
      data: {'amount': amount},
    );
  }

  // ════════════════════════════════════════════
  // BULK NOTIFICATION (For broadcasts)
  // ════════════════════════════════════════════

  /// Send notification to multiple users
  /// Useful for announcements, reminders, etc.
  static Future<int> broadcastNotification({
    required List<String> userIds,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    int successCount = 0;
    for (final userId in userIds) {
      final result = await createNotification(
        userId: userId,
        type: type,
        title: title,
        message: message,
        data: data,
      );
      if (result != null) successCount++;
    }
    return successCount;
  }

  // ════════════════════════════════════════════
  // REAL-TIME SUBSCRIPTIONS
  // ════════════════════════════════════════════

  /// Listen to user notifications in real-time
  static RealtimeChannel listenToNotifications(String userId) {
    return _db.realtime
        .channel('realtime:notifications:user_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('New notification: $payload');
          },
        );
  }

  /// Listen to scrim announcements in real-time
  static RealtimeChannel listenToScrimAnnouncements(String scrimId) {
    return _db.realtime
        .channel('realtime:scrim_announcements:scrim_id=eq.$scrimId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'scrim_announcements',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'scrim_id',
            value: scrimId,
          ),
          callback: (payload) {
            debugPrint('New announcement: $payload');
          },
        );
  }
}

import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background handler
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static FirebaseMessaging? get _messaging {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseMessaging.instance;
  }
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  static String? _fcmToken;

  static String? get fcmToken => _fcmToken;

  /// Initialize Firebase Cloud Messaging and local notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    if (Firebase.apps.isEmpty) {
      debugPrint("Warning: Firebase is not initialized. Skipping PushNotificationService initialization.");
      return;
    }

    try {
      final messaging = _messaging;
      if (messaging == null) return;

      // 1. Request permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // 2. Configure local notifications for foreground
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
            
        const InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
        );

        await _localNotifications.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            // Handle notification tapped in foreground
            debugPrint("Notification tapped in foreground: ${response.payload}");
          },
        );

        // Create Android Notification Channel for Heads-up notifications
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel', // id
          'High Importance Notifications', // title
          description: 'This channel is used for important notifications.', // description
          importance: Importance.high,
          playSound: true,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        // 3. Register background message handler
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // 4. Configure foreground message presentation
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true, // Required to display a heads up notification
          badge: true,
          sound: true,
        );

        // 5. Listen to foreground messages and show local notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a message whilst in the foreground!');
          debugPrint('Message data: ${message.data}');

          if (message.notification != null) {
            debugPrint('Message also contained a notification: ${message.notification?.title}');
            
            RemoteNotification? notification = message.notification;
            AndroidNotification? android = message.notification?.android;

            if (notification != null) {
              _localNotifications.show(
                notification.hashCode,
                notification.title,
                notification.body,
                NotificationDetails(
                  android: AndroidNotificationDetails(
                    channel.id,
                    channel.name,
                    channelDescription: channel.description,
                    icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                    importance: Importance.max,
                    priority: Priority.high,
                    playSound: true,
                  ),
                ),
                payload: message.data.toString(),
              );
            }
          }
        });

        // 6. Listen to token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          debugPrint("FCM token refreshed: $newToken");
          _fcmToken = newToken;
          _registerTokenWithBackend(newToken);
        });

        // 7. Get initial token
        final token = await messaging.getToken();
        if (token != null) {
          debugPrint("FCM Token obtained: $token");
          _fcmToken = token;
          await _registerTokenWithBackend(token);
        }

        _initialized = true;
      }
    } catch (e) {
      debugPrint("Error initializing Push Notifications: $e");
    }
  }

  /// Register FCM Token to Supabase
  static Future<void> _registerTokenWithBackend(String token) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final platform = kIsWeb
        ? 'web'
        : Platform.isAndroid
            ? 'android'
            : Platform.isIOS
                ? 'ios'
                : 'other';

    debugPrint("Registering FCM token for user ${user.id} on $platform");
    await UserService.registerDeviceToken(
      authUuid: user.id,
      token: token,
      platform: platform,
    );
  }

  /// Manually trigger token registration (useful after login)
  static Future<void> registerCurrentToken() async {
    if (Firebase.apps.isEmpty) return;
    
    if (_fcmToken != null) {
      await _registerTokenWithBackend(_fcmToken!);
    } else {
      final messaging = _messaging;
      if (messaging == null) return;
      // Attempt to get token and register it
      final token = await messaging.getToken();
      if (token != null) {
        _fcmToken = token;
        await _registerTokenWithBackend(token);
      }
    }
  }

  /// Deactivate FCM token (on logout)
  static Future<void> deactivateToken() async {
    if (Firebase.apps.isEmpty) return;
    
    if (_fcmToken != null) {
      debugPrint("Deactivating FCM token in backend: $_fcmToken");
      await UserService.deactivateDeviceToken(_fcmToken!);
    }
  }
}

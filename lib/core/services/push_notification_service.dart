import 'dart:async';
import 'dart:developer' as dev;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for global access to PushNotificationService
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(Supabase.instance.client);
});

/// Production-Ready Firebase Push Notification Service
/// Handles FCM device token registration, permission requests, foreground/background message handling, and token persistence in Supabase `fcm_tokens`.
class PushNotificationService {
  final SupabaseClient _supabase;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? get _vapidKey {
    const key = String.fromEnvironment('FCM_VAPID_KEY', defaultValue: '');
    return key.isNotEmpty ? key : null;
  }

  PushNotificationService(this._supabase);

  /// Initializes FCM permissions, token sync, and foreground/background listeners.
  Future<void> initialize() async {
    // Skip FCM configuration on Windows desktop
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      dev.log('[PushNotificationService] Skipping FCM setup on Windows desktop platform.', name: 'PushNotificationService');
      return;
    }

    try {
      // 1. Request Notification Permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // 2. Setup High Importance Android Notification Channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important MCE Placement Connect notifications.',
        importance: Importance.max,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );

      await _localNotifications.initialize(settings: initializationSettings);

      // 3. Register FCM Token immediately
      await registerDeviceToken();

      // Listen to token refresh events
      _fcm.onTokenRefresh.listen((newToken) async {
        await _saveTokenToDatabase(newToken);
      });

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        dev.log('[PushNotificationService] FCM permission granted.', name: 'PushNotificationService');

        // Set foreground notification options so notifications display while app is open
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // 4. Handle foreground notifications (Shows Heads-Up Banner when app is open)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          dev.log(
            '[PushNotificationService] Foreground notification received: ${message.notification?.title} - ${message.notification?.body}',
            name: 'PushNotificationService',
          );

          final notification = message.notification;
          final android = message.notification?.android;

          if (notification != null && !kIsWeb) {
            _localNotifications.show(
              id: notification.hashCode,
              title: notification.title,
              body: notification.body,
              notificationDetails: NotificationDetails(
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
            );
          }
        });

        // 5. Handle app opened from background/terminated notification
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          dev.log(
            '[PushNotificationService] App opened from notification: ${message.data}',
            name: 'PushNotificationService',
          );
        });
      }
    } catch (e) {
      dev.log('[PushNotificationService] FCM initialization error: $e', name: 'PushNotificationService');
    }
  }

  /// Fetches current FCM token and saves it for the logged in user in `fcm_tokens`
  Future<void> registerDeviceToken() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) return;

    try {
      final token = await _fcm.getToken(
        vapidKey: kIsWeb ? _vapidKey : null,
      );
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      dev.log('[PushNotificationService] Error getting FCM token: $e', name: 'PushNotificationService');
    }
  }

  /// Persists FCM token to Supabase `fcm_tokens` table
  Future<void> _saveTokenToDatabase(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    String platform = 'web';
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android) platform = 'android';
      if (defaultTargetPlatform == TargetPlatform.iOS) platform = 'ios';
    }

    try {
      // Keep only the current token per user — prune stale rows from old
      // installs/rotations so FCM never targets an unregistered token.
      await _supabase
          .from('fcm_tokens')
          .delete()
          .eq('user_id', userId);
      await _supabase.from('fcm_tokens').insert({
        'user_id': userId,
        'token': token,
        'platform': platform,
        'created_at': DateTime.now().toIso8601String(),
      });
      dev.log('[PushNotificationService] Token saved for user $userId ($platform)', name: 'PushNotificationService');
    } catch (e) {
      dev.log('[PushNotificationService] Error persisting token to DB: $e', name: 'PushNotificationService');
    }
  }

  /// Deletes FCM token from database on user sign-out
  Future<void> unregisterDeviceToken() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) return;

    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _supabase.from('fcm_tokens').delete().eq('token', token);
        dev.log('[PushNotificationService] FCM token removed on sign-out.', name: 'PushNotificationService');
      }
    } catch (e) {
      dev.log('[PushNotificationService] Error unregistering token: $e', name: 'PushNotificationService');
    }
  }
}

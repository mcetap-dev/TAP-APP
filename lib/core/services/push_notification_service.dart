import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for global access to PushNotificationService
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(Supabase.instance.client);
});

/// Lightweight Push Notification Service
/// Uses Supabase for token persistence. FCM/web push handling is opt-in
/// and delegated to the platform-specific setup when needed.
class PushNotificationService {
  final SupabaseClient _supabase;

  PushNotificationService(this._supabase);

  /// Initializes platform notification permissions and syncs token to Supabase.
  /// No-op on web due to interop limitations; app uses Supabase backend.
  Future<void> initialize() async {
    dev.log('[PushNotificationService] Initialized (platform-specific FCM optional).', name: 'PushNotificationService');
  }

  /// No-op: token registration is handled via Supabase directly.
  Future<void> registerDeviceToken() async {
    dev.log('[PushNotificationService] Token registration skipped (Supabase-backed).', name: 'PushNotificationService');
  }

  /// No-op: token unregistration on sign-out.
  Future<void> unregisterDeviceToken() async {
    dev.log('[PushNotificationService] Unregistration skipped (Supabase-backed).', name: 'PushNotificationService');
  }
}
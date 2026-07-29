import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/realtime_service.dart';
import '../../domain/entities/application.dart';

part 'student_realtime_provider.g.dart';

/// Provides the raw stream of all application updates across the entire system.
@riverpod
Stream<Application> globalApplicationUpdates(Ref ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return const Stream.empty();

  return Supabase.instance.client
      .from('applications')
      .stream(primaryKey: ['id'])
      .eq('student_id', user.id)
      .map((maps) => maps.map((m) => Application.fromMap(m)).first);
}

/// A stateful notifier that tracks if the CURRENT student received a realtime update.
/// This is more efficient than making the UI parse every global update.
@riverpod
class StudentRealtimeController extends _$StudentRealtimeController {
  StreamSubscription? _sub;

  @override
  Application? build() {
    // Get the current user's ID to filter updates
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    // Listen to the global stream
    _sub = ref.watch(globalApplicationUpdatesProvider).listen((updatedApp) {
      // If the update belongs to the current student, update the local state
      if (updatedApp.studentId == userId) {
        state = updatedApp;
      }
    });

    // Clean up the subscription when this provider is disposed
    ref.onDispose(() {
      _sub?.cancel();
    });

    return null; // Initial state is null (no updates yet)
  }
}
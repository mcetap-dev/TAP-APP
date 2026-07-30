import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../domain/entities/user_profile.dart';
import '../../../audit/domain/entities/audit_log_entry.dart';
import '../../../audit/domain/repositories/audit_log_repository.dart';

// ── Datasource provider ────────────────────────────────────────────────────
final authDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(Supabase.instance.client);
});

// ── Auth state stream (logged in / out) ───────────────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authDatasourceProvider).authStateChanges;
});

// ── Current user profile ───────────────────────────────────────────────────
final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (authState) async {
      final user = authState.session?.user;
      if (user == null) return null;
      return ref.read(authDatasourceProvider).fetchProfile(user.id);
    },
    loading: () async => null,
    error: (_, __) async => null,
  );
});

// ── Auth notifier (actions & active state) ─────────────────────────────────
class AuthNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final AuthRemoteDatasource _datasource;
  final AuditLogRepository _auditLogRepo;

  AuthNotifier(this._datasource, this._auditLogRepo) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final user = _datasource.currentUser;
    if (user != null) {
      _loadProfile(user.id);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> _loadProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      var profile = await _datasource.fetchProfile(userId);
      if (profile == null) {
        // Fallback: create UserProfile from auth user metadata if database row is missing
        final user = _datasource.currentUser;
        if (user != null) {
          final metaRole = user.userMetadata?['role'] as String? ?? 'student';
          final metaName = user.userMetadata?['name'] as String? ?? user.userMetadata?['full_name'] as String? ?? user.email?.split('@').first ?? 'User';
          profile = UserProfile(
            id: user.id,
            email: user.email ?? '',
            name: metaName,
            role: UserRole.fromString(metaRole),
            approvalStatus: metaRole == 'student' ? ApprovalStatus.pending : ApprovalStatus.approved,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _datasource.signInWithPassword(
        email: email,
        password: password,
      );
      final userId = response.user?.id;
      if (userId != null) {
        await _loadProfile(userId);
        
        // Log the sign in action
        await _auditLogRepo.logAction(
          action: AuditAction.login,
          description: 'Logged in successfully.',
        );
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? department,
    String? rollNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _datasource.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        department: department,
        rollNumber: rollNumber,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _datasource.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refreshProfile(String userId) => _loadProfile(userId);
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserProfile?>>((ref) {
  final datasource = ref.watch(authDatasourceProvider);
  final auditLogRepo = ref.watch(auditLogRepositoryProvider);
  return AuthNotifier(datasource, auditLogRepo);
});
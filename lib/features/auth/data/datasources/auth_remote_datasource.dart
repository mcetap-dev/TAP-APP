import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_profile.dart';

class AuthRemoteDatasource {
  final SupabaseClient _client;

  AuthRemoteDatasource(this._client);

  // ── Auth State Stream ─────────────────────────────────────────────────────
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  // ── Sign In (OTP / Magic Link) ─────────────────────────────────────────────
  Future<void> signInWithOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
    );
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? department,
    String? rollNumber,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': fullName,
        'full_name': fullName,
        'role': role,
        if (department != null) 'department': department,
        if (rollNumber != null) 'usn': rollNumber,
      },
    );

    final user = response.user;
    if (user != null) {
      try {
        await _client.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'name': fullName,
          'role': role,
          if (department != null) 'department': department,
          if (rollNumber != null) 'usn': rollNumber,
          'approval_status': role == 'student' ? 'pending' : 'approved',
        });
      } catch (e) {
        // Silently ignore upsert errors here, AuthNotifier handles fallback
      }
    }

    return response;
  }

  // ── Sign In with Password ─────────────────────────────────────────────────
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    return _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Fetch Profile ─────────────────────────────────────────────────────────
  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data != null) {
        return UserProfile.fromMap(data);
      }
    } catch (e) {
      // Log error — do NOT silently swallow and fall back to student
      debugPrint('[fetchProfile] DB fetch failed for $userId: $e');
    }

    // Fallback: read role from auth metadata only — never default to student
    final user = currentUser;
    if (user != null && user.id == userId) {
      final email = user.email ?? '';
      final metaRole = user.userMetadata?['role'] as String?;
      final metaName = user.userMetadata?['name'] as String?
          ?? user.userMetadata?['full_name'] as String?
          ?? email.split('@').first;

      // Determine role from metadata or email domain — NO student fallback
      UserRole role;
      if (metaRole != null && metaRole.isNotEmpty) {
        try {
          role = UserRole.fromString(metaRole);
        } catch (_) {
          debugPrint('[fetchProfile] Unknown metaRole "$metaRole" for $email. Returning null.');
          return null;
        }
      } else if (email.startsWith('admin')) {
        role = UserRole.admin;
      } else if (email.startsWith('tap') || email.startsWith('tpo')) {
        role = UserRole.tpo;
      } else if (email.contains('faculty')) {
        role = UserRole.facultyCoordinator;
      } else {
        // Cannot determine role — return null so login fails visibly
        debugPrint('[fetchProfile] Cannot determine role for $email. Profile not found in DB.');
        return null;
      }

      return UserProfile(
        id: userId,
        role: role,
        name: metaName,
        email: email,
        approvalStatus: role == UserRole.student
            ? ApprovalStatus.pending
            : ApprovalStatus.approved,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return null;
  }
}

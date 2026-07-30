import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/entities/user_profile.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/pending_approval_screen.dart';
import '../../features/student/presentation/screens/student_dashboard_screen.dart';
import '../../features/student/presentation/screens/profile_setup_screen.dart';
import '../../features/student/presentation/screens/consent_form_screen.dart';
import '../../features/student/presentation/screens/eligible_drives_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/admin/presentation/screens/tpo_appointment_screen.dart';
import '../../features/admin/presentation/screens/audit_logs_screen.dart';
import '../../features/admin/presentation/screens/system_settings_screen.dart';
import '../../features/faculty/presentation/screens/faculty_dashboard_screen.dart';
import '../../features/faculty/presentation/screens/student_approval_queue_screen.dart';
import '../../features/tpo/presentation/screens/tpo_dashboard_screen.dart';
import '../../features/tpo/presentation/screens/drive_creation_wizard.dart';
import '../../features/tpo/presentation/screens/applicant_list_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Helper class to bridge Riverpod state changes to GoRouter's Listenable refresh
class GoRouterRefreshNotifier extends ChangeNotifier {
  late final ProviderSubscription _subscription;

  GoRouterRefreshNotifier(Ref ref) {
    _subscription = ref.listen<AsyncValue<UserProfile?>>(
      authNotifierProvider,
      (previous, next) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final profile = authState.valueOrNull;
      final isLoggedIn = profile != null;

      final authPaths = {'/login', '/signup', '/verify-otp'};
      final isOnAuth = authPaths.any((p) => state.matchedLocation.startsWith(p));

      // Still loading — don't redirect
      if (authState.isLoading) return null;

      // Not logged in → must be on auth screen
      if (!isLoggedIn && !isOnAuth) return '/login';

      // Logged in → handle redirection based on role and approval status
      if (isLoggedIn) {
        // If student is pending, force them to pending approval screen
        if (profile.role == UserRole.student && 
            profile.approvalStatus == ApprovalStatus.pending) {
          if (state.matchedLocation != '/pending-approval') {
            return '/pending-approval';
          }
          return null; // Already on pending-approval
        }

        // Otherwise, if they are on an auth screen, redirect to their dashboard
        if (isOnAuth) {
          return _dashboardPath(profile.role);
        }
        
        // If they are on pending-approval but are no longer pending, redirect to dashboard
        if (state.matchedLocation == '/pending-approval' && 
            (profile.role != UserRole.student || profile.approvalStatus != ApprovalStatus.pending)) {
          return _dashboardPath(profile.role);
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        name: 'verify-otp',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/pending-approval',
        name: 'pending-approval',
        builder: (_, __) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/student',
        name: 'student',
        builder: (_, __) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: '/student/profile-setup',
        name: 'student-profile-setup',
        builder: (_, __) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/student/consent-form',
        name: 'student-consent-form',
        builder: (_, __) => const ConsentFormScreen(),
      ),
      GoRoute(
        path: '/student/eligible-drives',
        name: 'student-eligible-drives',
        builder: (_, __) => const EligibleDrivesScreen(),
      ),
      GoRoute(
        path: '/faculty',
        name: 'faculty',
        builder: (_, __) => const FacultyDashboardScreen(),
      ),
      GoRoute(
        path: '/faculty/approval-queue',
        name: 'faculty-approval-queue',
        builder: (_, __) => const StudentApprovalQueueScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        name: 'admin-reports',
        builder: (_, __) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: '/admin/appoint-tpo',
        name: 'admin-appoint-tpo',
        builder: (_, __) => const TpoAppointmentScreen(),
      ),
      GoRoute(
        path: '/admin/audit-logs',
        name: 'admin-audit-logs',
        builder: (_, __) => const AuditLogsScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'admin-settings',
        builder: (_, __) => const SystemSettingsScreen(),
      ),
      GoRoute(
        path: '/tpo',
        name: 'tpo',
        builder: (_, __) => const TpoDashboardScreen(),
      ),
      GoRoute(
        path: '/tpo/create-drive',
        name: 'tpo-create-drive',
        builder: (_, __) => const DriveCreationWizard(),
      ),
      GoRoute(
        path: '/tpo/applicant-list',
        name: 'tpo-applicant-list',
        builder: (_, __) => const ApplicantListScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Not found: ${state.uri}')),
    ),
  );
});

final routerRefreshNotifierProvider = Provider<GoRouterRefreshNotifier>((ref) {
  return GoRouterRefreshNotifier(ref);
});

String _dashboardPath(UserRole role) {
  switch (role) {
    case UserRole.student:
      return '/student';
    case UserRole.facultyCoordinator:
      return '/faculty';
    case UserRole.admin:
      return '/admin';
    case UserRole.tpo:
      return '/tpo';
  }
  // Dart exhaustive switch above handles all cases, no fallback needed
}

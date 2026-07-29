import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/entities/user_profile.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/student/presentation/screens/student_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/faculty/presentation/screens/faculty_dashboard_screen.dart';
import '../../features/tpo/presentation/screens/tpo_dashboard_screen.dart';

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

      // Logged in → redirect off auth screens to role dashboard
      if (isLoggedIn && isOnAuth) return _dashboardPath(profile.role);

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
        path: '/student',
        name: 'student',
        builder: (_, __) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: '/faculty',
        name: 'faculty',
        builder: (_, __) => const FacultyDashboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/tpo',
        name: 'tpo',
        builder: (_, __) => const TpoDashboardScreen(),
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
}

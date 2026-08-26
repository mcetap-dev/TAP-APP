import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../shared/presentation/widgets/app_logo.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSeeding = false;
  late AnimationController _floatAnimCtrl;

  @override
  void initState() {
    super.initState();
    _floatAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatAnimCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final input = _emailCtrl.text.trim();
    final fullEmail = input.contains('@')
        ? input
        : '$input@mcehassan.ac.in';
    try {
      await ref.read(authNotifierProvider.notifier).signInWithPassword(
            email: fullEmail,
            password: _passwordCtrl.text,
          );

      if (mounted) {
        var profile = ref.read(authNotifierProvider).valueOrNull;
        if (profile == null) {
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            final profData = await Supabase.instance.client
                .from('profiles')
                .select()
                .eq('id', user.id)
                .maybeSingle();
            if (profData != null) {
              profile = UserProfile.fromMap(profData);
            }
          }
        }

        if (profile != null && mounted) {
          if (profile.role == UserRole.student) {
            if (!profile.emailVerified) {
              context.go('/verify-otp', extra: profile.email);
            } else if (!profile.profileCompleted) {
              context.go('/student/onboarding');
            } else if (profile.approvalStatus == ApprovalStatus.pending) {
              context.go('/pending-approval');
            } else {
              context.go('/student');
            }
          } else {
            context.go(_dashboardPath(profile.role));
          }
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _dashboardPath(UserRole role) {
    switch (role) {
      case UserRole.student:
        return '/student';
      case UserRole.facultyCoordinator:
        return '/faculty';
      case UserRole.faculty:
        return '/faculty/waiting';
      case UserRole.admin:
        return '/admin';
      case UserRole.tpo:
        return '/tpo';
    }
  }

  Future<void> _seedDemoAccounts() async {
    setState(() => _isSeeding = true);
    final client = Supabase.instance.client;

    final accounts = [
      {'email': 'admin@mcehassan.ac.in', 'pass': 'Pass123!word', 'name': 'System Admin', 'role': 'admin'},
      {'email': 'tap@mcehassan.ac.in', 'pass': 'Pass123!word', 'name': 'TPO Officer', 'role': 'tpo'},
      {'email': 'facultycse@mcehassan.ac.in', 'pass': 'Pass123!word', 'name': 'Dr. CSE Faculty', 'role': 'faculty_coordinator'},
      {'email': 'stud1@ms.mcehassan.ac.in', 'pass': 'Pass123!word', 'name': 'Student One', 'role': 'student'},
    ];

    int created = 0;
    String lastError = '';
    for (final acc in accounts) {
      try {
        final res = await client.auth.signUp(
          email: acc['email']!,
          password: acc['pass']!,
          data: {
            'name': acc['name'],
            'full_name': acc['name'],
            'role': acc['role'],
          },
        );
        if (res.user != null) {
          created++;
          try {
            await client.from('profiles').upsert({
              'id': res.user!.id,
              'email': acc['email'],
              'name': acc['name'],
              'role': acc['role'],
              'approval_status': acc['role'] == 'student' ? 'pending' : 'approved',
            });
          } catch (pe) {
            lastError = pe.toString();
          }
        }
      } catch (se) {
        lastError = se.toString();
      }
    }

    if (mounted) {
      setState(() => _isSeeding = false);
      final msg = created > 0
          ? 'Created $created accounts. You can now tap quick login!'
          : 'Setup Info: $lastError';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _fillPreset(String email, String password) {
    _emailCtrl.text = email;
    _passwordCtrl.text = password;
    setState(() {});
  }

  Widget _demoChip(String title, String roleKey, AppBrandTheme brandTheme) {
    return GestureDetector(
      onTap: () async {
        setState(() => _isLoading = true);
        try {
          await ref.read(authNotifierProvider.notifier).demoLogin(roleKey);
          if (mounted) {
            final profile = ref.read(authNotifierProvider).valueOrNull;
            if (profile != null) {
              context.go(_dashboardPath(profile.role));
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Demo login error: $e')),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: brandTheme.brassSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: brandTheme.brassPrimary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, size: 13, color: brandTheme.brassPrimary),
            const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: brandTheme.brassPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _friendlyError(String raw) {
    if (raw.contains('Invalid login')) return 'Invalid credentials or user not found. Create account via Sign Up first!';
    if (raw.contains('Email not confirmed')) return 'Email not confirmed. Please check your inbox or OTP.';
    if (raw.contains('network')) return 'No internet connection.';
    return 'Sign in failed: ${raw.replaceAll("AuthException", "")}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpacing.sp5),

                    const AppLogo(size: 110),

                    const SizedBox(height: AppSpacing.sp5),

                    // App Title
                    Text(
                      'MCE Placement Connect',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to track your placement season',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: brandTheme.textMuted,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sp5),

                    // Login Form Card
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(AppSpacing.sp6),
                      decoration: ShapeDecoration(
                        color: theme.colorScheme.surface,
                        shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.circular(AppShapes.radiusHero),
                          side: BorderSide(
                            color: brandTheme.cardBorder,
                            width: 1,
                          ),
                        ),
                        shadows: brandTheme.shadow2,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'EMAIL ADDRESS',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: brandTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: GoogleFonts.inter(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Email address is required';
                                }
                                final input = val.trim();
                                if (!input.contains('@') || !input.contains('.')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                hintText: 'Enter your email',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp4),

                            Text(
                              'PASSWORD',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: brandTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              style: GoogleFonts.inter(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                              ),
                              onFieldSubmitted: (_) => _submit(),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Password is required'
                                  : null,
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: brandTheme.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp2),

                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => context.push('/forgot-password'),
                                child: Text(
                                  'Forgot password?',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: brandTheme.brassPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp4),

                            // Primary Brass Button
                            GestureDetector(
                              onTap: _isLoading ? null : _submit,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: brandTheme.brassGradient,
                                  borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
                                  boxShadow: [
                                    BoxShadow(
                                      color: brandTheme.brassSoft,
                                      blurRadius: 30,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: brandTheme.onBrass,
                                          ),
                                        )
                                      : Text(
                                          'Sign in',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: brandTheme.onBrass,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp5),

                    // Quick 1-Tap Demo Credentials
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sp3),
                      decoration: BoxDecoration(
                        color: brandTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppShapes.radiusStandard),
                        border: Border.all(color: brandTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bolt_rounded, size: 16, color: brandTheme.brassPrimary),
                              const SizedBox(width: 6),
                              Text(
                                'QUICK 1-TAP DEMO LOGIN',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: brandTheme.brassPrimary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const Spacer(),
                              if (_isSeeding)
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 1.5),
                                )
                              else
                                GestureDetector(
                                  onTap: _seedDemoAccounts,
                                  child: Text(
                                    'Seed Accounts',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: brandTheme.textMuted,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sp3),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _demoChip('Admin', 'admin', brandTheme),
                              _demoChip('TAP / TPO', 'tpo', brandTheme),
                              _demoChip('ISE Faculty', 'faculty_ise', brandTheme),
                              _demoChip('CSE Faculty', 'faculty_cse', brandTheme),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "New here? ",
                          style: GoogleFonts.inter(
                            color: brandTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/signup'),
                          child: Text(
                            'Create an account',
                            style: GoogleFonts.inter(
                              color: brandTheme.brassPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Malnad College of Engineering',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'A Disha Placement Cell initiative',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: brandTheme.brassPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sp6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
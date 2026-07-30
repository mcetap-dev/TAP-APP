import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../core/utils/validators.dart';
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
    try {
      await ref.read(authNotifierProvider.notifier).signInWithPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );

      if (mounted) {
        final profile = ref.read(authNotifierProvider).valueOrNull;
        if (profile != null) {
          final target = _dashboardPath(profile.role);
          context.go(target);
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
            // Top Glow Effect
            Positioned(
              top: -60,
              left: MediaQuery.of(context).size.width / 2 - 140,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      brandTheme.brassSoft,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpacing.sp5),

                    // Floating Orb Logo Container
                    AnimatedBuilder(
                      animation: _floatAnimCtrl,
                      builder: (context, child) {
                        final val = _floatAnimCtrl.value;
                        final dy = -8 * (1 - (val - 0.5).abs() * 2);
                        return Transform.translate(
                          offset: Offset(0, dy),
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              gradient: brandTheme.brassGradient,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(42),
                                topRight: Radius.circular(68),
                                bottomLeft: Radius.circular(68),
                                bottomRight: Radius.circular(46),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: brandTheme.brassSoft,
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.workspace_premium_rounded,
                                size: 52,
                                color: brandTheme.onBrass,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.sp5),

                    // App Title
                    Text(
                      'Placement Connect',
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

                    // Quick Demo Login Chips
                    Wrap(
                      spacing: AppSpacing.sp2,
                      runSpacing: AppSpacing.sp2,
                      alignment: WrapAlignment.center,
                      children: [
                        _demoChip('Student', 'stud1@ms.mcehassan.ac.in', 'Pass123!word', brandTheme),
                        _demoChip('TPO', 'tap@mcehassan.ac.in', 'Pass123!word', brandTheme),
                        _demoChip('Faculty', 'facultycse@mcehassan.ac.in', 'Pass123!word', brandTheme),
                        _demoChip('Admin', 'admin@mcehassan.ac.in', 'Pass123!word', brandTheme),
                      ],
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
                              'EMAIL',
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
                              validator: AppValidators.email,
                              decoration: const InputDecoration(
                                hintText: 'you@mcehassan.ac.in',
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
                                hintText: '••••••••',
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
                            const SizedBox(height: AppSpacing.sp6),

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
                    const SizedBox(height: AppSpacing.sp3),

                    // Dev Seed Helper Action
                    TextButton.icon(
                      onPressed: _isSeeding ? null : _seedDemoAccounts,
                      icon: _isSeeding
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: brandTheme.brassPrimary,
                              ),
                            )
                          : Icon(Icons.flash_on_rounded, size: 16, color: brandTheme.brassPrimary),
                      label: Text(
                        _isSeeding ? 'Creating accounts...' : 'Step 1: Setup Demo Accounts',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: brandTheme.brassPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

  Widget _demoChip(String roleName, String email, String password, AppBrandTheme brandTheme) => ActionChip(
        avatar: Icon(Icons.person_rounded, size: 14, color: brandTheme.brassPrimary),
        label: Text(roleName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        onPressed: () => _fillPreset(email, password),
        backgroundColor: brandTheme.brassSoft,
        side: BorderSide(color: brandTheme.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      );
}
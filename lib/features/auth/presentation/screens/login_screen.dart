import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/theme/theme_extensions.dart';

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
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
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
    final brandTheme = theme.extension<AppBrandTheme>();
    final brass = brandTheme?.brassPrimary ?? theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand Mark
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: brass,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Placement Connect',
                        style: GoogleFonts.fraunces(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to track your placement season',
                    style: GoogleFonts.inter(
                      color: brandTheme?.textMuted ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Demo Login Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _demoChip('Student', 'stud1@ms.mcehassan.ac.in', 'Pass123!word', brass),
                      _demoChip('TPO', 'tap@mcehassan.ac.in', 'Pass123!word', brass),
                      _demoChip('Faculty', 'facultycse@mcehassan.ac.in', 'Pass123!word', brass),
                      _demoChip('Admin', 'admin@mcehassan.ac.in', 'Pass123!word', brass),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Login Form Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: brandTheme?.cardBorder ?? theme.colorScheme.outline,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.4 : 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'EMAIL',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: brandTheme?.textMuted ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                          const SizedBox(height: 18),

                          Text(
                            'PASSWORD',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: brandTheme?.textMuted ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                                  color: brandTheme?.textMuted ?? Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: brass,
                              foregroundColor: theme.brightness == Brightness.dark ? const Color(0xFF0A0A0B) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Sign in',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 18),

                          // Signature Flourish
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              4,
                              (i) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i < 2 ? brass : brandTheme?.cardBorder ?? Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "New here? ",
                        style: GoogleFonts.inter(
                          color: brandTheme?.textMuted ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/signup'),
                        child: Text(
                          'Create an account',
                          style: GoogleFonts.inter(
                            color: brass,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dev Seed Helper Action
                  TextButton.icon(
                    onPressed: _isSeeding ? null : _seedDemoAccounts,
                    icon: _isSeeding
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.flash_on_rounded, size: 16, color: brass),
                    label: Text(
                      _isSeeding ? 'Creating accounts...' : 'Step 1: Setup Demo Accounts',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: brass,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoChip(String roleName, String email, String password, Color brass) => ActionChip(
        avatar: Icon(Icons.person_rounded, size: 14, color: brass),
        label: Text(roleName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        onPressed: () => _fillPreset(email, password),
        backgroundColor: brass.withValues(alpha: 0.1),
        side: BorderSide(color: brass.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      );
}
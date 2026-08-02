import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/theme/theme_extensions.dart';

/// Returns the role for a given email based on domain.
/// - @ms.mcehassan.ac.in  → student
/// - @mcehassan.ac.in      → faculty (TPO/Admin are appointed later by Admin)
/// - anything else          → null (rejected)
String? _roleFromEmail(String email) {
  final lower = email.trim().toLowerCase();
  if (lower.endsWith('@ms.mcehassan.ac.in')) return 'student';
  if (lower.endsWith('@mcehassan.ac.in')) return 'faculty';
  return null; // All other emails are rejected
}

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usnCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _usnCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final base = AppValidators.email(v);
    if (base != null) return base;
    final lower = (v ?? '').trim().toLowerCase();
    if (lower.endsWith('@ms.mcehassan.ac.in')) return null; // valid student
    if (lower.endsWith('@mcehassan.ac.in')) return null;    // valid faculty/staff
    return 'Only MCE Hassan emails are allowed:\n'
        '• Students: yourname@ms.mcehassan.ac.in\n'
        '• Faculty/Staff: yourname@mcehassan.ac.in';
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailCtrl.text.trim();
    final role = _roleFromEmail(email)!;

    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signUp(
            email: email,
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text.trim(),
            role: role,
            rollNumber: role == 'student' ? _usnCtrl.text.trim().toUpperCase() : null,
          );

      if (mounted) {
        context.push('/verify-otp', extra: email);
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

  String _friendlyError(String raw) {
    if (raw.contains('already registered') || raw.contains('already been registered')) {
      return 'An account with this email already exists. Please sign in.';
    }
    if (raw.contains('Password should be')) return 'Password is too weak.';
    if (raw.contains('network')) return 'No internet connection.';
    return 'Sign-up failed. Please try again.';
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
                  const SizedBox(height: 16),
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
                        'Create Account',
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
                    'Use your institutional college email to register',
                    style: GoogleFonts.inter(
                      color: brandTheme?.textMuted ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),

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
                          _label('FULL NAME', brandTheme, theme),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            style: GoogleFonts.inter(color: theme.colorScheme.onSurface, fontSize: 14),
                            validator: AppValidators.name,
                            decoration: const InputDecoration(hintText: 'Your full name'),
                          ),
                          const SizedBox(height: 16),

                          _label('USN / ROLL NUMBER', brandTheme, theme),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _usnCtrl,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.characters,
                            style: GoogleFonts.inter(color: theme.colorScheme.onSurface, fontSize: 14),
                            validator: (v) {
                              if (_emailCtrl.text.trim().toLowerCase().endsWith('@ms.mcehassan.ac.in')) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Please enter your USN (e.g. 4MC22CS001)';
                                }
                              }
                              return null;
                            },
                            decoration: const InputDecoration(hintText: 'e.g. 4MC22CS001'),
                          ),
                          const SizedBox(height: 16),

                          _label('COLLEGE EMAIL', brandTheme, theme),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.inter(color: theme.colorScheme.onSurface, fontSize: 14),
                            validator: _validateEmail,
                            decoration: const InputDecoration(hintText: 'you@ms.mcehassan.ac.in'),
                          ),
                          const SizedBox(height: 16),

                          _label('PASSWORD', brandTheme, theme),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePass,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.inter(color: theme.colorScheme.onSurface, fontSize: 14),
                            validator: AppValidators.password,
                            decoration: InputDecoration(
                              hintText: 'Min 8 chars, upper, number, symbol',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: brandTheme?.textMuted ?? Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _label('CONFIRM PASSWORD', brandTheme, theme),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            style: GoogleFonts.inter(color: theme.colorScheme.onSurface, fontSize: 14),
                            onFieldSubmitted: (_) => _submit(),
                            validator: _validateConfirm,
                            decoration: InputDecoration(
                              hintText: 'Re-enter your password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: brandTheme?.textMuted ?? Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: brass.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: brass.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              '• Students: @ms.mcehassan.ac.in\n• Faculty / Staff: @mcehassan.ac.in',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: brass,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: brass,
                              foregroundColor: theme.brightness == Brightness.dark ? const Color(0xFF0A0A0B) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text('Create Account', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: GoogleFonts.inter(
                              color: brandTheme?.textMuted ?? theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13)),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text('Sign In',
                            style: GoogleFonts.inter(
                              color: brass,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t, AppBrandTheme? brandTheme, ThemeData theme) => Text(
        t,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: brandTheme?.textMuted ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/theme_extensions.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  late final String _email;
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    // If the router forced us here without an extra (pending OTP), fall back
    // to the notifier's tracked email.
    _email = widget.email.isNotEmpty
        ? widget.email
        : (ref.read(authNotifierProvider.notifier).pendingOtpEmail ?? widget.email);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final err = ref.read(authNotifierProvider.notifier).lastOtpError;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Could not send the code automatically ($err). Tap Resend to try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  bool get _otpIsComplete =>
      _otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(_otp);

  Future<void> _verify() async {
    // Guard against duplicate/concurrent verification requests.
    if (_isLoading || _isResending) return;

    if (!_otpIsComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit verification code')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).verifySignupOtp(
        email: _email,
        code: _otp,
      );
      // Router redirects to the role-appropriate screen once the profile loads.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    if (_isResending || _isLoading) return;
    setState(() => _isResending = true);
    try {
      await ref.read(authNotifierProvider.notifier).resendOtp(_email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A new 6-digit code has been sent to your email.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
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
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _friendlyError(String raw) {
    final msg = raw.replaceFirst('Exception: ', '').trim();
    final lower = msg.toLowerCase();
    if (lower.contains('expired')) return 'Code expired. Please request a new code.';
    if (lower.contains('too many incorrect')) return 'Too many incorrect attempts. Please request a new code.';
    if (lower.contains('already been used')) return 'This code has already been used. Please request a new one.';
    if (lower.contains('incorrect code')) {
      final m = RegExp(r'(\d+)\s+attempt').firstMatch(msg);
      if (m != null) return 'Incorrect code. ${m.group(1)} attempt(s) left.';
      return 'Incorrect code. Please check and try again.';
    }
    if (lower.contains('no active code')) return 'No active code found. Please request a new one.';
    if (lower.contains('invalid code')) return 'Invalid code. Please enter the 6-digit code.';
    if (lower.contains('please wait')) return msg;
    return 'Verification failed. Please try again.';
  }

  void _onOtpDigit(int index, String value) {
    // Multi-character input (e.g. paste) is split and distributed across the
    // six boxes. Only digits are accepted (inputFormatters).
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      final count = digits.length > 6 ? 6 : digits.length;
      for (var i = 0; i < count; i++) {
        _controllers[i].text = digits[i];
      }
      final next = count < 6 ? count : 5;
      _focusNodes[next].requestFocus();
    } else if (value.length == 1) {
      if (index < 5) _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otpIsComplete) _verify();
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: brass),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Check your email',
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
                  'We sent a 6-digit code to\n$_email',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: brandTheme?.textMuted ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),

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
                  child: Column(
                    children: [
                      Row(
                        children: List.generate(
                          6,
                          (i) => Expanded(
                            child: Container(
                              height: 52,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              child: TextFormField(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              onChanged: (v) => _onOtpDigit(i, v),
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: brandTheme?.surfaceAlt ?? theme.colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: brandTheme?.cardBorder ?? Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: brandTheme?.cardBorder ?? Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: brass, width: 2),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _verify,
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
                            : Text('Verify Email', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: _isResending ? null : _resend,
                        child: _isResending
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(
                                "Didn't receive the code? Resend",
                                style: GoogleFonts.inter(fontSize: 13, color: brass, fontWeight: FontWeight.w500),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    ref.read(authNotifierProvider.notifier).clearPendingOtp();
                    context.go('/login');
                  },
                  child: Text(
                    '← Back to sign in',
                    style: GoogleFonts.inter(
                      color: brandTheme?.textMuted ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

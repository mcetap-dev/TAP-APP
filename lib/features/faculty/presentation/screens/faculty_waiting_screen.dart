import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FacultyWaitingScreen extends ConsumerStatefulWidget {
  const FacultyWaitingScreen({super.key});

  @override
  ConsumerState<FacultyWaitingScreen> createState() => _FacultyWaitingScreenState();
}

class _FacultyWaitingScreenState extends ConsumerState<FacultyWaitingScreen> {
  bool _isChecking = false;

  Future<void> _checkAppointmentStatus() async {
    setState(() => _isChecking = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Trigger Riverpod auth notifier refresh which re-queries profiles and updates routing
      ref.read(authNotifierProvider.notifier).refreshProfile(user.id);
    }
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>()!;

    final userProfile = ref.watch(authNotifierProvider).valueOrNull;
    final userName = userProfile?.name ?? 'Faculty Member';
    final userEmail = userProfile?.email ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Waiting Icon Graphic
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: brandTheme.brassSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: brandTheme.brassPrimary.withValues(alpha: 0.4), width: 2),
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  size: 48,
                  color: brandTheme.brassPrimary,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Account Verified',
                style: GoogleFonts.fraunces(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Greeting & Role Message
              Text(
                'Welcome, $userName ($userEmail)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: brandTheme.brassPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: brandTheme.cardBorder),
                ),
                child: Text(
                  'Your faculty account has been verified, but you have not yet been assigned an appointment role.\n\n'
                  'Please wait until the System Administrator appoints you as a Faculty Coordinator or TPO Officer.\n\n'
                  'Your specialized dashboard will become accessible automatically upon appointment.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: brandTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              // Action Buttons: Check Status & Sign Out
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isChecking ? null : _checkAppointmentStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandTheme.brassPrimary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        _isChecking ? 'Checking Status...' : 'Check Appointment Status',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: brandTheme.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                      label: Text(
                        'Sign Out',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

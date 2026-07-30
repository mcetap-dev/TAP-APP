import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../providers/faculty_provider.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/presentation/widgets/floating_pill_nav_bar.dart';
import '../../../../shared/presentation/widgets/skeleton_loader.dart';
import '../../../../shared/presentation/widgets/state_block_widget.dart';

class FacultyDashboardScreen extends ConsumerStatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  ConsumerState<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends ConsumerState<FacultyDashboardScreen> {
  int _currentNavIndex = 0;

  static const _navDestinations = [
    NavDestinationItem(icon: Icons.dashboard_rounded, label: 'Overview'),
    NavDestinationItem(icon: Icons.verified_user_rounded, label: 'Verify'),
    NavDestinationItem(icon: Icons.analytics_rounded, label: 'Analytics'),
    NavDestinationItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  void _toggleVerify(UserProfile s, String facultyName) async {
    final isCurrentlyApproved = s.approvalStatus == ApprovalStatus.approved;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('profiles').update({
        'approval_status': !isCurrentlyApproved ? 'approved' : 'pending',
        'approved_by': !isCurrentlyApproved ? user?.id : null,
        'approved_at': !isCurrentlyApproved ? DateTime.now().toIso8601String() : null,
      }).eq('id', s.id);
      ref.invalidate(pendingStudentsProvider);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !isCurrentlyApproved
                ? '✅ Academic details for ${s.name} (${s.usn}) verified by $facultyName!'
                : 'Status reset for ${s.name}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: profileAsync.when(
              data: (profile) => _buildTabContent(_currentNavIndex, profile?.fullName ?? 'Faculty Advisor', brandTheme, theme),
              loading: () => Padding(
                padding: const EdgeInsets.only(top: 80, left: 16, right: 16),
                child: Column(
                  children: const [
                    SkeletonCardRow(),
                    SkeletonCardRow(),
                  ],
                ),
              ),
              error: (e, _) => StateBlockWidget(
                icon: Icons.error_outline_rounded,
                title: "Couldn't load dashboard",
                message: e.toString(),
                isError: true,
              ),
            ),
          ),

          // Floating Pill Nav Bar
          FloatingPillNavBar(
            selectedIndex: _currentNavIndex,
            onDestinationSelected: (index) => setState(() => _currentNavIndex = index),
            items: _navDestinations,
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(int tabIndex, String facultyName, AppBrandTheme brandTheme, ThemeData theme) {
    switch (tabIndex) {
      case 0:
        return _overviewTab(facultyName, brandTheme, theme);
      case 1:
        return _verificationTab(facultyName, theme, brandTheme);
      case 2:
        return _analyticsTab(theme, brandTheme);
      case 3:
        return _profileTab(facultyName, theme, brandTheme);
      default:
        return _overviewTab(facultyName, brandTheme, theme);
    }
  }

  Widget _overviewTab(String name, AppBrandTheme brandTheme, ThemeData theme) {
    final pendingStudentsAsync = ref.watch(pendingStudentsProvider);
    final topPadding = MediaQuery.of(context).padding.top + AppSpacing.sp3;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: topPadding,
        left: AppSpacing.sp5,
        right: AppSpacing.sp5,
        bottom: 110,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Welcome, ',
                        style: GoogleFonts.fraunces(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: name.split(' ').first,
                            style: GoogleFonts.fraunces(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: brandTheme.brassPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Department Faculty Advisor',
                      style: GoogleFonts.inter(fontSize: 12, color: brandTheme.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.logout_rounded, size: 20, color: brandTheme.textMuted),
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp5),

          pendingStudentsAsync.when(
            data: (students) {
              final pendingCount = students.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bento Primary Tile (B1 - 1.3fr)
                      Expanded(
                        flex: 13,
                        child: Container(
                          height: 160,
                          padding: const EdgeInsets.all(AppSpacing.sp5),
                          decoration: ShapeDecoration(
                            color: theme.colorScheme.surface,
                            shape: ContinuousRectangleBorder(
                              borderRadius: BorderRadius.circular(AppShapes.radiusHero),
                              side: BorderSide(color: brandTheme.cardBorder),
                            ),
                            shadows: brandTheme.shadow2,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$pendingCount',
                                    style: GoogleFonts.fraunces(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w600,
                                      color: brandTheme.brassPrimary,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pending Verifications',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: brandTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sp3),

                      // Bento Secondary Stat Tiles (B2 & B3 - 1.0fr Stack)
                      Expanded(
                        flex: 10,
                        child: SizedBox(
                          height: 160,
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.sp3),
                                  decoration: ShapeDecoration(
                                    color: theme.colorScheme.surface,
                                    shape: ContinuousRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppShapes.radiusStandard),
                                      side: BorderSide(color: brandTheme.cardBorder),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '0',
                                        style: GoogleFonts.fraunces(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: brandTheme.statusShortlisted,
                                        ),
                                      ),
                                      Text(
                                        'Verified Today',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: brandTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sp2),
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppSpacing.sp3),
                                  decoration: ShapeDecoration(
                                    color: theme.colorScheme.surface,
                                    shape: ContinuousRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppShapes.radiusStandard),
                                      side: BorderSide(color: brandTheme.cardBorder),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '0',
                                        style: GoogleFonts.fraunces(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        'Total Batch',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: brandTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sp6),

                  Text(
                    'PENDING VERIFICATION REQUESTS',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: brandTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp3),

                  if (students.isEmpty)
                    StateBlockWidget(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'All caught up!',
                      message: 'No pending student verification requests in your department.',
                    )
                  else
                    ...students.map((s) => _verificationCard(s, name, theme, brandTheme)),
                ],
              );
            },
            loading: () => const SkeletonCardRow(),
            error: (e, _) => StateBlockWidget(
              icon: Icons.error_outline_rounded,
              title: 'Failed to load requests',
              message: e.toString(),
              isError: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationTab(String facultyName, ThemeData theme, AppBrandTheme brandTheme) {
    final pendingStudentsAsync = ref.watch(pendingStudentsProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.sp4,
        left: AppSpacing.sp5,
        right: AppSpacing.sp5,
        bottom: 110,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Student Verification', style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Verify student academic records and eligibility', style: GoogleFonts.inter(fontSize: 13, color: brandTheme.textMuted)),
          const SizedBox(height: AppSpacing.sp5),

          pendingStudentsAsync.when(
            data: (students) {
              if (students.isEmpty) {
                return StateBlockWidget(
                  icon: Icons.verified_user_outlined,
                  title: 'No pending verifications',
                  message: 'All registered students in your department have been reviewed.',
                );
              }
              return Column(
                children: students.map((s) => _verificationCard(s, facultyName, theme, brandTheme)).toList(),
              );
            },
            loading: () => Column(
              children: const [
                SkeletonCardRow(),
                SkeletonCardRow(),
              ],
            ),
            error: (e, _) => StateBlockWidget(
              icon: Icons.error_outline_rounded,
              title: 'Error loading list',
              message: e.toString(),
              isError: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsTab(ThemeData theme, AppBrandTheme brandTheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.sp4,
        left: AppSpacing.sp5,
        right: AppSpacing.sp5,
        bottom: 110,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Department Analytics', style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Placement statistics for your batch', style: GoogleFonts.inter(fontSize: 13, color: brandTheme.textMuted)),
          const SizedBox(height: AppSpacing.sp5),
          StateBlockWidget(
            icon: Icons.analytics_outlined,
            title: 'Analytics Overview',
            message: 'Detailed batch analytics and placement ratios will populate once drives conclude.',
          ),
        ],
      ),
    );
  }

  Widget _profileTab(String name, ThemeData theme, AppBrandTheme brandTheme) => SingleChildScrollView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + AppSpacing.sp4,
          left: AppSpacing.sp5,
          right: AppSpacing.sp5,
          bottom: 110,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: brandTheme.brassGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.fraunces(fontSize: 32, color: brandTheme.onBrass, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp3),
                  const SizedBox(height: AppSpacing.sp3),
                  Text(name, style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600)),
                  Text('Department Faculty Advisor', style: GoogleFonts.inter(fontSize: 12, color: brandTheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _verificationCard(UserProfile s, String facultyName, ThemeData theme, AppBrandTheme brandTheme) {
    final isApproved = s.approvalStatus == ApprovalStatus.approved;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sp3),
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: ShapeDecoration(
        color: theme.colorScheme.surface,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.radiusStandard),
          side: BorderSide(color: brandTheme.cardBorder),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text('${s.usn} · CGPA ${s.cgpa}', style: GoogleFonts.ibmPlexMono(fontSize: 12, color: brandTheme.textMuted)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _toggleVerify(s, facultyName),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isApproved ? brandTheme.statusShortlisted.withValues(alpha: 0.16) : brandTheme.brassSoft,
                borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
              ),
              child: Text(
                isApproved ? 'Verified ✓' : 'Verify Details',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isApproved ? brandTheme.statusShortlisted : brandTheme.brassPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

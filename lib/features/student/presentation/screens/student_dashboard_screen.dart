import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/presentation/widgets/floating_pill_nav_bar.dart';
import '../../../../shared/presentation/widgets/status_thread_widget.dart';
import '../../../../shared/presentation/widgets/skeleton_loader.dart';
import '../../../../shared/presentation/widgets/state_block_widget.dart';
import '../providers/student_drive_provider.dart';
import '../../domain/entities/application.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  int _currentNavIndex = 0;

  static const _navDestinations = [
    NavDestinationItem(icon: Icons.home_rounded, label: 'Home'),
    NavDestinationItem(icon: Icons.work_rounded, label: 'Drives'),
    NavDestinationItem(icon: Icons.timeline_rounded, label: 'Timeline'),
    NavDestinationItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  void _showEditProfileSheet(BuildContext context, String currentName, String currentDept, String currentRoll, AppBrandTheme brandTheme, ThemeData theme) {
    final nameCtrl = TextEditingController(text: currentName);
    final deptCtrl = TextEditingController(text: currentDept.isEmpty ? 'Information Science & Engineering' : currentDept);
    final rollCtrl = TextEditingController(text: currentRoll.isEmpty ? '4MC23IS001' : currentRoll);
    final cgpaCtrl = TextEditingController(text: '8.5');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppShapes.radiusHero)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.sp5,
            top: AppSpacing.sp5,
            left: AppSpacing.sp5,
            right: AppSpacing.sp5,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Profile', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp4),

              Text('FULL NAME', style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w600, color: brandTheme.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(hintText: 'Full Name'),
              ),
              const SizedBox(height: AppSpacing.sp3),

              Text('DEPARTMENT', style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w600, color: brandTheme.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: deptCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(hintText: 'Department'),
              ),
              const SizedBox(height: AppSpacing.sp3),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ROLL / REG NO', style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w600, color: brandTheme.textMuted)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: rollCtrl,
                          style: GoogleFonts.ibmPlexMono(fontSize: 14),
                          decoration: const InputDecoration(hintText: '4MC23IS001'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CGPA', style: GoogleFonts.ibmPlexMono(fontSize: 11, fontWeight: FontWeight.w600, color: brandTheme.textMuted)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: cgpaCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.ibmPlexMono(fontSize: 14),
                          decoration: const InputDecoration(hintText: '8.5'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp6),

              GestureDetector(
                onTap: isSaving
                    ? null
                    : () async {
                        setSheetState(() => isSaving = true);
                        try {
                          final user = Supabase.instance.client.auth.currentUser;
                          if (user != null) {
                            await Supabase.instance.client.from('profiles').upsert({
                              'id': user.id,
                              'full_name': nameCtrl.text.trim(),
                              'department': deptCtrl.text.trim(),
                              'roll_number': rollCtrl.text.trim(),
                              'cgpa': double.tryParse(cgpaCtrl.text.trim()) ?? 8.5,
                            });
                            ref.read(authNotifierProvider.notifier).refreshProfile(user.id);
                          }
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setSheetState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Updated locally: ${e.toString()}'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.pop(ctx);
                          }
                        }
                      },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: brandTheme.brassGradient,
                    borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
                  ),
                  child: Center(
                    child: isSaving
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: brandTheme.onBrass))
                        : Text('Save Changes', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: brandTheme.onBrass)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          // Content layer with bottom padding for floating bar
          Positioned.fill(
            child: profileAsync.when(
              data: (profile) => _buildTabContent(_currentNavIndex, profile, brandTheme, theme),
              loading: () => Padding(
                padding: const EdgeInsets.only(top: 80, left: 16, right: 16),
                child: Column(
                  children: const [
                    SkeletonCardRow(),
                    SkeletonCardRow(),
                    SkeletonCardRow(),
                  ],
                ),
              ),
              error: (e, _) => StateBlockWidget(
                icon: Icons.error_outline_rounded,
                title: "Couldn't load dashboard",
                message: 'Connection dropped while fetching profile. Please retry.',
                isError: true,
                actionLabel: 'Retry',
                onAction: () => ref.read(authNotifierProvider.notifier).refreshProfile(''),
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

  Widget _buildTabContent(int tabIndex, dynamic profile, AppBrandTheme brandTheme, ThemeData theme) {
    final name = profile?.fullName ?? 'Sumukha';
    final dept = profile?.department ?? 'Information Science & Engineering';
    final roll = profile?.rollNumber ?? '4MC23IS001';

    switch (tabIndex) {
      case 0:
        return _dashboardTab(context, profile, name, brandTheme, theme);
      case 1:
        return _drivesTab(theme, brandTheme);
      case 2:
        return _applicationsTab(theme, brandTheme);
      case 3:
        return _profileTab(name, dept, roll, theme, brandTheme);
      default:
        return _dashboardTab(context, profile, name, brandTheme, theme);
    }
  }

  Widget _dashboardTab(BuildContext context, UserProfile? profile, String name, AppBrandTheme brandTheme, ThemeData theme) {
    final appsAsync = ref.watch(studentApplicationsProvider);
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
          // Greeting & User Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Hey, ',
                        style: GoogleFonts.fraunces(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: name.split(' ').first,
                            style: GoogleFonts.fraunces(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: brandTheme.brassPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Batch 2027 · ISE',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: brandTheme.textMuted,
                      ),
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

          appsAsync.when(
            data: (apps) {
              final shortlistedCount = apps.where((a) => a.status == ApplicationStatus.shortlisted).length;
              final offersCount = apps.where((a) => a.status == ApplicationStatus.selected).length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Asymmetric Bento Grid
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
                                    '${apps.length}',
                                    style: GoogleFonts.fraunces(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w600,
                                      color: brandTheme.brassPrimary,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Active applications',
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
                                        '$shortlistedCount',
                                        style: GoogleFonts.fraunces(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        'Shortlisted',
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
                                        '$offersCount',
                                        style: GoogleFonts.fraunces(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: brandTheme.statusShortlisted,
                                        ),
                                      ),
                                      Text(
                                        'Offers',
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

                  // Open Drives Section Header
                  Text(
                    'OPEN DRIVES FOR YOU',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: brandTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp3),

                  // Horizontal Drive Cards Scroll
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _horizontalDriveCard('PhonePe', 'PP', 'SDE-1 · Closes in 3d', 'CGPA 7.0+', brandTheme, theme),
                        const SizedBox(width: AppSpacing.sp3),
                        _horizontalDriveCard('Razorpay', 'RP', 'SDE Intern · Closes in 5d', 'All branches', brandTheme, theme),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp6),

                  // Recent Update Card
                  Text(
                    'RECENT UPDATE',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: brandTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp3),

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sp4),
                    decoration: ShapeDecoration(
                      color: theme.colorScheme.surface,
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(AppShapes.radiusStandard),
                        side: BorderSide(color: brandTheme.cardBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: brandTheme.statusShortlisted.withValues(alpha: 0.16),
                          ),
                          child: Icon(Icons.check_rounded, size: 18, color: brandTheme.statusShortlisted),
                        ),
                        const SizedBox(width: AppSpacing.sp3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Google — moved to Interview',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Round 2 scheduled for Aug 6',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: brandTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const SkeletonCardRow(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _horizontalDriveCard(String company, String logoInit, String desc, String badgeText, AppBrandTheme brandTheme, ThemeData theme) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: ShapeDecoration(
        color: theme.colorScheme.surface,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(AppShapes.radiusStandard),
          side: BorderSide(color: brandTheme.cardBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: brandTheme.brassGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    logoInit,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: brandTheme.onBrass,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.inter(fontSize: 12, color: brandTheme.textMuted),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: brandTheme.brassSoft,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              badgeText,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: brandTheme.brassPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drivesTab(ThemeData theme, AppBrandTheme brandTheme) {
    final drivesAsync = ref.watch(studentEligibleDrivesProvider);

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
          Text('Campus Placement Drives', style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Drives open for your batch & eligibility', style: GoogleFonts.inter(fontSize: 13, color: brandTheme.textMuted)),
          const SizedBox(height: AppSpacing.sp5),
          drivesAsync.when(
            data: (drives) {
              if (drives.isEmpty) {
                return StateBlockWidget(
                  icon: Icons.work_off_outlined,
                  title: 'No drives open right now',
                  message: "Check back after your coordinator publishes this cycle's calendar — you'll get a notification the moment a new drive opens.",
                );
              }
              return Column(
                children: drives.map((d) => _driveItem(d.companyName, '${d.roleTitle} · ${d.ctcOrStipend}', 'Deadline: ${d.applicationDeadline.toIso8601String().split('T')[0]}', theme, brandTheme)).toList(),
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
              title: "Couldn't load drives",
              message: e.toString(),
              isError: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicationsTab(ThemeData theme, AppBrandTheme brandTheme) {
    final appsAsync = ref.watch(studentApplicationsProvider);

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
          Text('Application Timeline', style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Live recruitment stage tracking', style: GoogleFonts.inter(fontSize: 13, color: brandTheme.textMuted)),
          const SizedBox(height: AppSpacing.sp5),
          appsAsync.when(
            data: (apps) {
              if (apps.isEmpty) {
                return StateBlockWidget(
                  icon: Icons.assignment_outlined,
                  title: 'No applications submitted',
                  message: 'When you apply to open drives, your progress timeline will appear here.',
                );
              }
              return Column(
                children: apps.map((a) => _applicationThreadCard('Drive #${a.driveId.substring(0, 6)}', 'Status: ${a.status.name}', theme, brandTheme)).toList(),
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
              title: "Couldn't load applications",
              message: e.toString(),
              isError: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileTab(String name, String dept, String roll, ThemeData theme, AppBrandTheme brandTheme) => SingleChildScrollView(
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
                  Text(name, style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600)),
                  Text('$roll · $dept', style: GoogleFonts.ibmPlexMono(fontSize: 12, color: brandTheme.textMuted)),
                  const SizedBox(height: AppSpacing.sp4),

                  GestureDetector(
                    onTap: () => _showEditProfileSheet(context, name, dept, roll, brandTheme, theme),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: brandTheme.brassPrimary),
                        borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
                      ),
                      child: Text('Edit Profile Details', style: GoogleFonts.inter(fontSize: 13, color: brandTheme.brassPrimary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sp6),
            _profileTile(Icons.school_outlined, 'Academic Details', 'CGPA: 8.5 · No Active Backlogs', theme, brandTheme),
            _profileTile(Icons.description_outlined, 'Resume / Portfolio', 'Uploaded: resume_v2.pdf', theme, brandTheme),
            _profileTile(Icons.badge_outlined, 'College ID Verification', 'Verified ✓', theme, brandTheme),
          ],
        ),
      );

  Widget _driveItem(String comp, String details, String deadline, ThemeData theme, AppBrandTheme brandTheme) => Container(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comp, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(details, style: GoogleFonts.inter(fontSize: 12, color: brandTheme.textMuted)),
                const SizedBox(height: 4),
                Text(deadline, style: GoogleFonts.ibmPlexMono(fontSize: 11, color: brandTheme.brassPrimary)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: brandTheme.brassGradient,
                borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
              ),
              child: Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: brandTheme.onBrass)),
            ),
          ],
        ),
      );

  Widget _applicationThreadCard(String company, String role, ThemeData theme, AppBrandTheme brandTheme) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sp3),
        padding: const EdgeInsets.all(AppSpacing.sp4),
        decoration: ShapeDecoration(
          color: theme.colorScheme.surface,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.radiusStandard),
            side: BorderSide(color: brandTheme.cardBorder),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: brandTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(company.substring(0, 2).toUpperCase(), style: GoogleFonts.ibmPlexMono(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(role, style: GoogleFonts.inter(fontSize: 12, color: brandTheme.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sp4),
            StatusThreadWidget(
              nodes: const [
                StatusNodeData(label: 'Applied', isDone: true),
                StatusNodeData(label: 'Shortlist', isDone: true),
                StatusNodeData(label: 'Interview', isCurrent: true),
                StatusNodeData(label: 'Offer'),
              ],
            ),
          ],
        ),
      );

  Widget _profileTile(IconData icon, String title, String subtitle, ThemeData theme, AppBrandTheme brandTheme) => Container(
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
          children: [
            Icon(icon, size: 22, color: brandTheme.brassPrimary),
            const SizedBox(width: AppSpacing.sp3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: brandTheme.textMuted)),
              ],
            ),
          ],
        ),
      );
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/tpo_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/presentation/widgets/floating_pill_nav_bar.dart';
import '../../../../shared/presentation/widgets/skeleton_loader.dart';
import '../../../../shared/presentation/widgets/state_block_widget.dart';

class TpoDashboardScreen extends ConsumerStatefulWidget {
  const TpoDashboardScreen({super.key});

  @override
  ConsumerState<TpoDashboardScreen> createState() => _TpoDashboardScreenState();
}

class _TpoDashboardScreenState extends ConsumerState<TpoDashboardScreen> {
  int _currentNavIndex = 0;

  static const _navDestinations = [
    NavDestinationItem(icon: Icons.dashboard_rounded, label: 'Overview'),
    NavDestinationItem(icon: Icons.business_center_rounded, label: 'Drives'),
    NavDestinationItem(icon: Icons.person_add_alt_rounded, label: 'Faculty'),
    NavDestinationItem(icon: Icons.assignment_turned_in_rounded, label: 'Offers'),
  ];

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
              data: (profile) => _buildTabContent(_currentNavIndex, profile?.fullName ?? 'TPO Officer', brandTheme, theme),
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

          // Floating FAB thumb ergonomic position
          Positioned(
            right: AppSpacing.sp5,
            bottom: 104,
            child: GestureDetector(
              onTap: () => context.push('/tpo/create-drive'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: brandTheme.brassGradient,
                  borderRadius: BorderRadius.circular(AppShapes.radiusFab),
                  boxShadow: brandTheme.shadow2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: brandTheme.onBrass, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'New Drive',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: brandTheme.onBrass,
                      ),
                    ),
                  ],
                ),
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

  Widget _buildTabContent(int tabIndex, String name, AppBrandTheme brandTheme, ThemeData theme) {
    switch (tabIndex) {
      case 0:
        return _overviewTab(context, ref, name, brandTheme, theme);
      case 1:
        return _drivesManagementTab(ref, brandTheme, theme);
      case 2:
        return _appointFacultyTab(ref, brandTheme, theme);
      case 3:
        return _offersAndRoundsTab(ref, brandTheme, theme);
      default:
        return _overviewTab(context, ref, name, brandTheme, theme);
    }
  }

  Widget _overviewTab(BuildContext context, WidgetRef ref, String name, AppBrandTheme brandTheme, ThemeData theme) {
    final drivesAsync = ref.watch(tpoDrivesProvider);
    final topPadding = MediaQuery.of(context).padding.top + AppSpacing.sp3;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: topPadding,
        left: AppSpacing.sp5,
        right: AppSpacing.sp5,
        bottom: 170,
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
                      '2026-27 Academic Cycle · Placement Cell',
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

          drivesAsync.when(
            data: (drives) {
              final activeDrivesCount = drives.length;
              final applicantsCount = 0; // Dynamic from provider/data
              final offersCount = 0; // Dynamic from provider/data

              return Row(
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
                                '$activeDrivesCount',
                                style: GoogleFonts.fraunces(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w600,
                                  color: brandTheme.brassPrimary,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Active Drives',
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
                                    '$applicantsCount',
                                    style: GoogleFonts.fraunces(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Applicants',
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
              );
            },
            loading: () => const SkeletonCardRow(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: AppSpacing.sp6),

          Text(
            'LIVE DRIVE STATUS OVERVIEW',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08,
              color: brandTheme.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sp3),

          drivesAsync.when(
            data: (drives) {
              if (drives.isEmpty) {
                return StateBlockWidget(
                  icon: Icons.business_center_outlined,
                  title: 'No placement drives active',
                  message: 'Create your first campus recruitment drive using the New Drive button.',
                );
              }
              return Column(
                children: drives.map((drive) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sp3),
                    child: _driveStatusCard(
                      drive.companyName,
                      '${drive.roleTitle} (${drive.ctcOrStipend})',
                      drive.status.toUpperCase(),
                      brandTheme,
                      theme,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => Column(
              children: const [
                SkeletonCardRow(),
                SkeletonCardRow(),
              ],
            ),
            error: (err, _) => StateBlockWidget(
              icon: Icons.error_outline_rounded,
              title: 'Failed to load drives',
              message: err.toString(),
              isError: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drivesManagementTab(WidgetRef ref, AppBrandTheme brandTheme, ThemeData theme) {
    final drivesAsync = ref.watch(tpoDrivesProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.sp4,
        left: AppSpacing.sp5,
        right: AppSpacing.sp5,
        bottom: 170,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Drive Management', style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Manage active recruitment drives and eligibility', style: GoogleFonts.inter(fontSize: 13, color: brandTheme.textMuted)),
          const SizedBox(height: AppSpacing.sp5),

          drivesAsync.when(
            data: (drives) {
              if (drives.isEmpty) {
                return StateBlockWidget(
                  icon: Icons.work_off_outlined,
                  title: 'No drives created',
                  message: 'Tap New Drive to configure company details and batch eligibility.',
                );
              }
              return Column(
                children: drives.map((d) => _driveStatusCard(d.companyName, '${d.roleTitle} · ${d.ctcOrStipend}', d.status, brandTheme, theme)).toList(),
              );
            },
            loading: () => const SkeletonCardRow(),
            error: (e, _) => StateBlockWidget(
              icon: Icons.error_outline_rounded,
              title: 'Error loading drives',
              message: e.toString(),
              isError: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _appointFacultyTab(WidgetRef ref, AppBrandTheme brandTheme, ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.sp4,
        left: AppSpacing.sp5,
        right: AppSpacing.sp5,
        bottom: 170,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Faculty Coordinator Appointment', style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Assign department verification leads', style: GoogleFonts.inter(fontSize: 13, color: brandTheme.textMuted)),
          const SizedBox(height: AppSpacing.sp5),
          StateBlockWidget(
            icon: Icons.person_add_alt_rounded,
            title: 'Faculty Appointments',
            message: 'Appointed department coordinators will manage student verification queues.',
          ),
        ],
      ),
    );
  }

  Widget _offersAndRoundsTab(WidgetRef ref, AppBrandTheme brandTheme, ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.sp4,
        left: AppSpacing.sp5,
        right: AppSpacing.sp5,
        bottom: 170,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Offers & Round Management', style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Upload shortlist CSVs and release offers', style: GoogleFonts.inter(fontSize: 13, color: brandTheme.textMuted)),
          const SizedBox(height: AppSpacing.sp5),
          StateBlockWidget(
            icon: Icons.assignment_turned_in_rounded,
            title: 'Offer Processing',
            message: 'Select an active drive to upload interview results or offer letters.',
          ),
        ],
      ),
    );
  }

  Widget _driveStatusCard(String company, String details, String statusText, AppBrandTheme brandTheme, ThemeData theme) => Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(company, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: brandTheme.brassSoft,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: brandTheme.brassPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(details, style: GoogleFonts.inter(fontSize: 12, color: brandTheme.textMuted)),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'drive_creation_wizard.dart';
import '../providers/tpo_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/presentation/widgets/status_thread_widget.dart';
import '../../../../shared/presentation/widgets/app_bottom_nav_bar.dart';

class TpoDashboardScreen extends ConsumerStatefulWidget {
  const TpoDashboardScreen({super.key});

  @override
  ConsumerState<TpoDashboardScreen> createState() => _TpoDashboardScreenState();
}

class _TpoDashboardScreenState extends ConsumerState<TpoDashboardScreen> {
  int _currentNavIndex = 0;

  static const _navItems = [
    NavItemData(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded, label: 'Overview'),
    NavItemData(icon: Icons.business_center_outlined, selectedIcon: Icons.business_center_rounded, label: 'Drives'),
    NavItemData(icon: Icons.person_add_alt_outlined, selectedIcon: Icons.person_add_alt_rounded, label: 'Faculty Appt'),
    NavItemData(icon: Icons.assignment_turned_in_outlined, selectedIcon: Icons.assignment_turned_in_rounded, label: 'Offers'),
  ];

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>();
    final brass = brandTheme?.brassPrimary ?? theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('TPO Command Center', style: GoogleFonts.fraunces(fontWeight: FontWeight.w600)),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => _buildTabContent(_currentNavIndex, profile?.fullName ?? 'TPO Officer', brass, brandTheme, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDriveSheet(context, brass, brandTheme, theme),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Drive'),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        items: _navItems,
      ),
    );
  }

  Widget _buildTabContent(int tabIndex, String name, Color brass, AppBrandTheme? brandTheme, ThemeData theme) {
    switch (tabIndex) {
      case 0:
        return _overviewTab(context, ref, name, brass, brandTheme, theme);
      case 1:
        return _drivesManagementTab(ref, brass, brandTheme, theme);
      case 2:
        return _appointFacultyTab(ref, brass, brandTheme, theme);
      case 3:
        return _offersAndRoundsTab(ref, brass, brandTheme, theme);
      default:
        return _overviewTab(context, ref, name, brass, brandTheme, theme);
    }
  }

  Widget _overviewTab(BuildContext context, WidgetRef ref, String name, Color brass, AppBrandTheme? brandTheme, ThemeData theme) {
    final drivesAsync = ref.watch(tpoDrivesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
                    Text('Welcome, $name',
                        style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('2026-27 Academic Cycle · All Departments',
                        style: GoogleFonts.inter(fontSize: 13, color: brandTheme?.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: brass.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('TPO Officer',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: brass)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stat Row
          drivesAsync.when(
            data: (drives) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statCard('${drives.length}', 'Active Drives', theme, brandTheme),
                  const SizedBox(width: 10),
                  _statCard('0', 'Total Applicants', theme, brandTheme),
                  const SizedBox(width: 10),
                  _statCard('0', 'Offers Uploaded', theme, brandTheme),
                  const SizedBox(width: 10),
                  _statCard('0.0%', 'Placement Rate', theme, brandTheme),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),

          Text('Live Drive Status Overview', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          drivesAsync.when(
            data: (drives) {
              if (drives.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: brandTheme?.cardBorder ?? theme.colorScheme.outline),
                  ),
                  child: Center(
                    child: Text('No active drives. Create a new drive using the button below.',
                        style: GoogleFonts.inter(color: brandTheme?.textMuted)),
                  ),
                );
              }
              return Column(
                children: drives.map((drive) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _driveStatusCard(
                      drive.companyName,
                      '${drive.roleTitle} (${drive.ctcOrStipend})',
                      drive.status.toUpperCase(),
                      PlacementStage.applied,
                      brass,
                      brandTheme,
                      theme,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error loading overview drives: $err'),
          ),
        ],
      ),
    );
  }

  Widget _drivesManagementTab(WidgetRef ref, Color brass, AppBrandTheme? brandTheme, ThemeData theme) {
    final drivesAsync = ref.watch(tpoDrivesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                    Text('Onboard Companies & Drives',
                        style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('Create drive, CTC, CGPA cutoff & rounds',
                        style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showCreateDriveSheet(context, brass, brandTheme, theme),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('New Drive', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brass,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          drivesAsync.when(
            data: (drives) {
              if (drives.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('No placement drives created yet. Tap "New Drive" to post one.',
                        style: GoogleFonts.inter(color: brandTheme?.textMuted)),
                  ),
                );
              }
              return Column(
                children: drives.map((drive) {
                  return _driveDetailItem(
                    drive.companyName,
                    drive.roleTitle,
                    drive.ctcOrStipend,
                    'CGPA >= ${drive.cgpaCutoff}',
                    drive.eligibilityBranches.join(', '),
                    drive.applicationDeadline.toString().split(' ')[0],
                    brass,
                    theme,
                    brandTheme,
                    context,
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading live drives: $err')),
          ),
        ],
      ),
    );
  }

  Widget _appointFacultyTab(WidgetRef ref, Color brass, AppBrandTheme? brandTheme, ThemeData theme) {
    final coordinatorsAsync = ref.watch(facultyCoordinatorsProvider);

    final standardDepartments = [
      'Information Science & Engineering',
      'Computer Science & Engineering',
      'Electronics & Communication',
      'Mechanical Engineering',
      'Civil Engineering',
      'Electrical Engineering',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appoint Faculty Coordinators', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600)),
          Text('Enforced constraint: Exactly 1 coordinator per department', style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
          const SizedBox(height: 20),
          coordinatorsAsync.when(
            data: (coordinators) {
              final coordMap = <String, Map<String, dynamic>>{};
              for (final c in coordinators) {
                final dept = c['department'] as String?;
                if (dept != null) coordMap[dept] = c;
              }

              return Column(
                children: standardDepartments.map((dept) {
                  final existing = coordMap[dept];
                  final profile = existing?['profile'] as Map<String, dynamic>?;
                  final name = profile?['name'] as String? ?? 'Not Appointed';
                  final email = profile?['email'] as String? ?? '—';
                  final isAssigned = existing != null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _facultyApptCard(dept, name, email, isAssigned, brass, brandTheme, theme),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading coordinators: $err')),
          ),
        ],
      ),
    );
  }

  Widget _offersAndRoundsTab(WidgetRef ref, Color brass, AppBrandTheme? brandTheme, ThemeData theme) {
    final drivesAsync = ref.watch(tpoDrivesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Round Progression & Offers', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600)),
          Text('Advance round status and upload final candidate offer letters', style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
          const SizedBox(height: 20),
          drivesAsync.when(
            data: (drives) {
              if (drives.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('No offer letters or rounds active yet.',
                        style: GoogleFonts.inter(color: brandTheme?.textMuted)),
                  ),
                );
              }
              return Column(
                children: drives.map((d) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _offerItem(
                      'Candidate Pool for ${d.roleTitle}',
                      d.companyName,
                      d.roleTitle,
                      d.ctcOrStipend,
                      'Drive ${d.status.toUpperCase()}',
                      brass,
                      theme,
                      brandTheme,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading offers: $err')),
          ),
        ],
      ),
    );
  }

  Widget _driveStatusCard(String company, String role, String roundInfo, PlacementStage stage, Color brass, AppBrandTheme? brandTheme, ThemeData theme) => Container(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: theme.brightness == Brightness.dark ? const Color(0xFF121417) : theme.colorScheme.surface,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: brandTheme?.cardBorder ?? theme.colorScheme.outline),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(company, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: brass.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(roundInfo, style: GoogleFonts.inter(fontSize: 11, color: brass, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(role, style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
            const SizedBox(height: 12),
            StatusThreadWidget(currentStage: stage),
          ],
        ),
      );

  Widget _driveDetailItem(String company, String role, String ctc, String cgpa, String branches, String deadline, Color brass, ThemeData theme, AppBrandTheme? brandTheme, BuildContext context) => InkWell(
        onTap: () => context.push('/tpo/applicant-list'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: theme.brightness == Brightness.dark ? const Color(0xFF121417) : theme.colorScheme.surface,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: brandTheme?.cardBorder ?? theme.colorScheme.outline),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(company, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                Text(ctc, style: GoogleFonts.ibmPlexMono(fontWeight: FontWeight.w600, color: brass, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Text(role, style: GoogleFonts.inter(fontSize: 13, color: brandTheme?.textMuted)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.school_outlined, size: 14, color: brandTheme?.textMuted),
                const SizedBox(width: 4),
                Text(cgpa, style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
                const SizedBox(width: 14),
                Icon(Icons.account_tree_outlined, size: 14, color: brandTheme?.textMuted),
                const SizedBox(width: 4),
                Text(branches, style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _facultyApptCard(String dept, String name, String email, bool isAppointed, Color brass, AppBrandTheme? brandTheme, ThemeData theme) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: brandTheme?.cardBorder ?? theme.colorScheme.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dept, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(isAppointed ? '$name ($email)' : 'No coordinator appointed yet',
                      style: GoogleFonts.inter(fontSize: 12, color: isAppointed ? theme.colorScheme.onSurface : brandTheme?.textMuted)),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isAppointed ? theme.colorScheme.outline : brass),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isAppointed ? 'Replace' : 'Appoint',
                  style: GoogleFonts.inter(fontSize: 12, color: isAppointed ? theme.colorScheme.onSurface : brass, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _offerItem(String student, String company, String role, String ctc, String statusLabel, Color statusColor, ThemeData theme, AppBrandTheme? brandTheme) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: brandTheme?.cardBorder ?? theme.colorScheme.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('$company · $role ($ctc)', style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(statusLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
            ),
          ],
        ),
      );

  Widget _statCard(String num, String label, ThemeData theme, AppBrandTheme? brandTheme) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: brandTheme?.cardBorder ?? theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(num, style: GoogleFonts.ibmPlexMono(fontSize: 20, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: brandTheme?.textMuted)),
          ],
        ),
      );

  void _showCreateDriveSheet(BuildContext context, Color brass, AppBrandTheme? brandTheme, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.85,
        child: const DriveCreationWizard(),
      ),
    );
  }
}

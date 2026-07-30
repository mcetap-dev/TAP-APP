import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../providers/student_drive_provider.dart';
import '../../domain/entities/application.dart';
import '../../../../shared/presentation/widgets/status_thread_widget.dart';
import '../../../../shared/presentation/widgets/app_bottom_nav_bar.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  int _currentNavIndex = 0;

  static const _navItems = [
    NavItemData(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded, label: 'Home'),
    NavItemData(icon: Icons.work_outline_rounded, selectedIcon: Icons.work_rounded, label: 'Drives'),
    NavItemData(icon: Icons.assignment_outlined, selectedIcon: Icons.assignment_rounded, label: 'Applications'),
    NavItemData(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profile'),
  ];

  void _showEditProfileSheet(BuildContext context, String currentName, String currentDept, String currentRoll, Color brass, AppBrandTheme? brandTheme, ThemeData theme) {
    final nameCtrl = TextEditingController(text: currentName);
    final deptCtrl = TextEditingController(text: currentDept.isEmpty ? 'Information Science & Engineering' : currentDept);
    final rollCtrl = TextEditingController(text: currentRoll.isEmpty ? '4MC23IS001' : currentRoll);
    final cgpaCtrl = TextEditingController(text: '8.5');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
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
              const SizedBox(height: 16),

              Text('FULL NAME', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: brandTheme?.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(hintText: 'Full Name'),
              ),
              const SizedBox(height: 14),

              Text('DEPARTMENT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: brandTheme?.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: deptCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: const InputDecoration(hintText: 'Department'),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ROLL / REG NO', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: brandTheme?.textMuted)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: rollCtrl,
                          style: GoogleFonts.ibmPlexMono(fontSize: 14),
                          decoration: const InputDecoration(hintText: '4MC23IS001'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CGPA', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: brandTheme?.textMuted)),
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
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: isSaving
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
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: brass,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Save Changes', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
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
    final brandTheme = theme.extension<AppBrandTheme>();
    final brass = brandTheme?.brassPrimary ?? theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Placement Connect', style: GoogleFonts.fraunces(fontWeight: FontWeight.w600)),
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
        data: (profile) => _buildTabContent(_currentNavIndex, profile, brass, brandTheme, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        items: _navItems,
      ),
    );
  }

  Widget _buildTabContent(int tabIndex, dynamic profile, Color brass, AppBrandTheme? brandTheme, ThemeData theme) {
    final name = profile?.fullName ?? 'Student';
    final dept = profile?.department ?? 'Information Science & Engineering';
    final roll = profile?.rollNumber ?? '4MC23IS001';

    switch (tabIndex) {
      case 0:
        return _dashboardTab(context, profile, name, brass, brandTheme, theme);
      case 1:
        return _drivesTab(theme, brandTheme, brass);
      case 2:
        return _applicationsTab(theme, brandTheme);
      case 3:
        return _profileTab(name, dept, roll, theme, brandTheme, brass);
      default:
        return _dashboardTab(context, profile, name, brass, brandTheme, theme);
    }
  }

  Widget _dashboardTab(BuildContext context, UserProfile? profile, String name, Color brass, AppBrandTheme? brandTheme, ThemeData theme) {
    final appsAsync = ref.watch(studentApplicationsProvider);

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
                      Text(
                        'Welcome, $name',
                        style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text('Batch 2027 · ISE Dept', style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: brass.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('Student', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: brass)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Faculty Coordinator Approval Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (profile?.approvalStatus == ApprovalStatus.approved)
                    ? (brandTheme?.statusShortlisted ?? Colors.green).withValues(alpha: 0.1)
                    : Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (profile?.approvalStatus == ApprovalStatus.approved)
                      ? (brandTheme?.statusShortlisted ?? Colors.green).withValues(alpha: 0.3)
                      : Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    (profile?.approvalStatus == ApprovalStatus.approved)
                        ? Icons.verified_rounded
                        : Icons.pending_actions_rounded,
                    color: (profile?.approvalStatus == ApprovalStatus.approved)
                        ? (brandTheme?.statusShortlisted ?? Colors.green)
                        : Colors.amber[700],
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (profile?.approvalStatus == ApprovalStatus.approved)
                              ? 'Approved by Faculty Coordinator'
                              : 'Pending Faculty Approval',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          (profile?.approvalStatus == ApprovalStatus.approved)
                              ? 'Your profile is verified. You can apply to eligible placement drives.'
                              : 'Your Faculty Coordinator must verify your academic details before you can apply to drives.',
                          style: GoogleFonts.inter(fontSize: 11, color: brandTheme?.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Consent Form Card
            Container(
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
                        Text('Placement Season Opt-In', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('Opting in makes you visible for campus drives.', style: GoogleFonts.inter(fontSize: 11, color: brandTheme?.textMuted)),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => context.push('/student/consent-form'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Update'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            appsAsync.when(
              data: (apps) {
                final appliedCount = apps.where((a) => a.status == ApplicationStatus.applied).length;
                final shortlistedCount = apps.where((a) => a.status == ApplicationStatus.shortlisted).length;
                final interviewCount = apps.where((a) => a.status == ApplicationStatus.interview).length;
                final offersCount = apps.where((a) => a.status == ApplicationStatus.selected).length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _statCard('$appliedCount', 'Applied', theme, brandTheme),
                          const SizedBox(width: 10),
                          _statCard('$shortlistedCount', 'Shortlisted', theme, brandTheme),
                          const SizedBox(width: 10),
                          _statCard('$interviewCount', 'Interview', theme, brandTheme),
                          const SizedBox(width: 10),
                          _statCard('$offersCount', 'Offers', theme, brandTheme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Your Active Drives', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    if (apps.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('No active drive applications yet.',
                            style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
                      )
                    else
                      ...apps.map((a) => _applicationThreadCard(
                            'Drive #${a.driveId.length > 6 ? a.driveId.substring(0, 6) : a.driveId}',
                            'Status: ${a.status.name}',
                            PlacementStage.applied,
                            theme,
                            brandTheme,
                          )),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      );
  }

  Widget _drivesTab(ThemeData theme, AppBrandTheme? brandTheme, Color brass) {
    final drivesAsync = ref.watch(studentEligibleDrivesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Campus Placement Drives', style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Drives open for your batch & CGPA eligibility', style: GoogleFonts.inter(fontSize: 13, color: brandTheme?.textMuted)),
          const SizedBox(height: 16),
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
                    child: Column(
                      children: [
                        Icon(Icons.work_off_outlined, size: 36, color: brandTheme?.textMuted),
                        const SizedBox(height: 10),
                        Text('No Drives Available Right Now', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('Once approved by your Faculty Coordinator, open eligible drives will appear here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: drives.map((d) => _driveItem(d.companyName, '${d.roleTitle} · ${d.ctcOrStipend}', 'Deadline: ${d.applicationDeadline.toIso8601String().split('T')[0]}', brass, theme, brandTheme)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading drives: $e')),
          ),
        ],
      ),
    );
  }

  Widget _applicationsTab(ThemeData theme, AppBrandTheme? brandTheme) {
    final appsAsync = ref.watch(studentApplicationsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Application History', style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Track live status across recruitment stages', style: GoogleFonts.inter(fontSize: 13, color: brandTheme?.textMuted)),
          const SizedBox(height: 16),
          appsAsync.when(
            data: (apps) {
              if (apps.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: brandTheme?.cardBorder ?? theme.colorScheme.outline),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.assignment_outlined, size: 36, color: brandTheme?.textMuted),
                        const SizedBox(height: 10),
                        Text('No Applications Yet', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('When you apply to active placement drives, your progress tracker will appear here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: apps.map((a) => _applicationThreadCard('Drive application #${a.driveId.substring(0, 6)}', 'Status: ${a.status.name}', PlacementStage.applied, theme, brandTheme)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading applications: $e')),
          ),
        ],
      ),
    );
  }

  Widget _profileTab(String name, String dept, String roll, ThemeData theme, AppBrandTheme? brandTheme, Color brass) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: brass.withValues(alpha: 0.15),
                    child: Text(name.substring(0, 1).toUpperCase(), style: GoogleFonts.fraunces(fontSize: 28, color: brass, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600)),
                  Text('$roll · $dept', style: GoogleFonts.ibmPlexMono(fontSize: 12, color: brandTheme?.textMuted)),
                  const SizedBox(height: 14),

                  OutlinedButton.icon(
                    onPressed: () => _showEditProfileSheet(context, name, dept, roll, brass, brandTheme, theme),
                    icon: Icon(Icons.edit_outlined, size: 16, color: brass),
                    label: Text('Edit Profile Details', style: GoogleFonts.inter(fontSize: 13, color: brass, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: brass),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Complete Profile Setup Button
                  OutlinedButton.icon(
                    onPressed: () => context.push('/student/profile-setup'),
                    icon: Icon(Icons.check_circle_outline, size: 16, color: brass),
                    label: Text('Complete Full Profile (Wizard)', style: GoogleFonts.inter(fontSize: 13, color: brass, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: brass),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _profileTile(Icons.school_outlined, 'Academic Details', 'CGPA: 8.5 · No Active Backlogs', theme, brandTheme),
            _profileTile(Icons.description_outlined, 'Resume / Portfolio', 'Uploaded: resume_v2.pdf', theme, brandTheme),
            _profileTile(Icons.badge_outlined, 'College ID Verification', 'Verified ✓', theme, brandTheme),
          ],
        ),
      );

  Widget _statCard(String num, String label, ThemeData theme, AppBrandTheme? brandTheme) => Container(
        width: 100,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: brandTheme?.cardBorder ?? theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(num, style: GoogleFonts.ibmPlexMono(fontSize: 22, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: brandTheme?.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  Widget _driveItem(String comp, String details, String deadline, Color brass, ThemeData theme, AppBrandTheme? brandTheme) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: brandTheme?.cardBorder ?? theme.colorScheme.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comp, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                Text(details, style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
                const SizedBox(height: 4),
                Text(deadline, style: GoogleFonts.ibmPlexMono(fontSize: 11, color: brass)),
              ],
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: brass,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      );

  Widget _applicationThreadCard(String company, String role, PlacementStage stage, ThemeData theme, AppBrandTheme? brandTheme) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: brandTheme?.cardBorder ?? theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: brandTheme?.surfaceAlt ?? theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(company.substring(0, 2).toUpperCase(), style: GoogleFonts.ibmPlexMono(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(role, style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StatusThreadWidget(currentStage: stage),
          ],
        ),
      );

  Widget _profileTile(IconData icon, String title, String subtitle, ThemeData theme, AppBrandTheme? brandTheme) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: brandTheme?.cardBorder ?? theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
              ],
            ),
          ],
        ),
      );
}
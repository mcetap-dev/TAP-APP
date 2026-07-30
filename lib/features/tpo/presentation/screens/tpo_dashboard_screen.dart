import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
        return _overviewTab(context, name, brass, brandTheme, theme);
      case 1:
        return _drivesManagementTab(brass, brandTheme, theme);
      case 2:
        return _appointFacultyTab(brass, brandTheme, theme);
      case 3:
        return _offersAndRoundsTab(brass, brandTheme, theme);
      default:
        return _overviewTab(context, name, brass, brandTheme, theme);
    }
  }

  Widget _overviewTab(BuildContext context, String name, Color brass, AppBrandTheme? brandTheme, ThemeData theme) => SingleChildScrollView(
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _statCard('312', 'Total Applicants', theme, brandTheme),
                  const SizedBox(width: 10),
                  _statCard('6', 'Active Drives', theme, brandTheme),
                  const SizedBox(width: 10),
                  _statCard('41', 'Offers Uploaded', theme, brandTheme),
                  const SizedBox(width: 10),
                  _statCard('13.1%', 'Placement Rate', theme, brandTheme),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Live Drive Status Overview', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            _driveStatusCard('Google India', 'SDE-1 (₹24 LPA)', 'Technical Round 2', PlacementStage.interview, brass, brandTheme, theme),
            const SizedBox(height: 10),
            _driveStatusCard('Microsoft', 'Software Engineer (₹28 LPA)', 'Shortlisted Candidates', PlacementStage.shortlisted, brass, brandTheme, theme),
            const SizedBox(height: 10),
            _driveStatusCard('Razorpay', 'SDE Intern (₹80k/mo)', 'Applications Open', PlacementStage.applied, brass, brandTheme, theme),
          ],
        ),
      );

  Widget _drivesManagementTab(Color brass, AppBrandTheme? brandTheme, ThemeData theme) => SingleChildScrollView(
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
                  onPressed: () => context.push('/tpo/create-drive'),
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
            _driveDetailItem('Google India', 'SDE-1', '24.0 LPA', 'CGPA >= 8.0', 'CS, ISE, ECE', 'Aug 15, 2026', brass, theme, brandTheme, context),
            _driveDetailItem('Microsoft', 'Software Engineer', '28.0 LPA', 'CGPA >= 8.5', 'All Branches', 'Aug 18, 2026', brass, theme, brandTheme, context),
            _driveDetailItem('Amazon AWS', 'Cloud Dev Intern', '80,000/mo', 'CGPA >= 7.5', 'CS, ISE', 'Aug 22, 2026', brass, theme, brandTheme, context),
          ],
        ),
      );

  Widget _appointFacultyTab(Color brass, AppBrandTheme? brandTheme, ThemeData theme) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appoint Faculty Coordinators', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600)),
            Text('Enforced constraint: Exactly 1 coordinator per department', style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
            const SizedBox(height: 20),

            _facultyApptCard('Information Science & Engineering', 'Dr. Ramesh Kumar', 'ramesh.ise@college.edu', true, brass, brandTheme, theme),
            const SizedBox(height: 10),
            _facultyApptCard('Computer Science & Engineering', 'Prof. Sunita Sharma', 'sunita.cs@college.edu', true, brass, brandTheme, theme),
            const SizedBox(height: 10),
            _facultyApptCard('Electronics & Communication', 'Not Appointed', '—', false, brass, brandTheme, theme),
            const SizedBox(height: 10),
            _facultyApptCard('Mechanical Engineering', 'Not Appointed', '—', false, brass, brandTheme, theme),
          ],
        ),
      );

  Widget _offersAndRoundsTab(Color brass, AppBrandTheme? brandTheme, ThemeData theme) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Round Progression & Offers', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600)),
            Text('Advance round status and upload final candidate offer letters', style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
            const SizedBox(height: 20),

            _offerItem('Sumukha R (4MC23IS001)', 'Google India', 'SDE-1', '24.0 LPA', 'Offer Uploaded', Colors.green, theme, brandTheme),
            _offerItem('Anagha K S (4MC23IS088)', 'Microsoft', 'Software Engineer', '28.0 LPA', 'Pending Offer Letter', Colors.amber[700]!, theme, brandTheme),
            _offerItem('Priya Sharma (4MC23CS012)', 'Razorpay', 'Backend Intern', '12.0 LPA', 'Accepted by Student', Colors.green, theme, brandTheme),
          ],
        ),
      );

  Widget _driveStatusCard(String company, String role, String roundInfo, PlacementStage stage, Color brass, AppBrandTheme? brandTheme, ThemeData theme) => Container(
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
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
      builder: (ctx) => Padding(
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
            Text('Create Placement Drive', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(decoration: const InputDecoration(labelText: 'Company Name (e.g. Google India)')),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(labelText: 'Role Title (e.g. SDE-1)')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(decoration: const InputDecoration(labelText: 'CTC / Stipend'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(decoration: const InputDecoration(labelText: 'CGPA Cutoff (e.g. 8.0)'))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brass,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Create Drive & Set Rounds', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../providers/faculty_provider.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/presentation/widgets/app_bottom_nav_bar.dart';

class StudentVerificationItem {
  final String id;
  final String name;
  final String regNo;
  final String cgpa;
  final String dept;
  bool isVerified;

  StudentVerificationItem({
    required this.id,
    required this.name,
    required this.regNo,
    required this.cgpa,
    required this.dept,
    this.isVerified = false,
  });
}

class FacultyDashboardScreen extends ConsumerStatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  ConsumerState<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends ConsumerState<FacultyDashboardScreen> {
  int _currentNavIndex = 0;

  static const _navItems = [
    NavItemData(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded, label: 'Overview'),
    NavItemData(icon: Icons.verified_user_outlined, selectedIcon: Icons.verified_user_rounded, label: 'Verify Students'),
    NavItemData(icon: Icons.analytics_outlined, selectedIcon: Icons.analytics_rounded, label: 'Analytics'),
    NavItemData(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'Profile'),
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
    final brandTheme = theme.extension<AppBrandTheme>();
    final successColor = brandTheme?.statusShortlisted ?? const Color(0xFF2F6B4F);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Faculty Dashboard', style: GoogleFonts.fraunces(fontWeight: FontWeight.w600)),
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
        data: (profile) => _buildTabContent(_currentNavIndex, profile?.fullName ?? 'Faculty Advisor', successColor, brandTheme, theme),
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

  Widget _buildTabContent(int tabIndex, String facultyName, Color successColor, AppBrandTheme? brandTheme, ThemeData theme) {
    switch (tabIndex) {
      case 0:
        return _overviewTab(facultyName, successColor, brandTheme, theme);
      case 1:
        return _verificationTab(facultyName, theme, brandTheme, successColor);
      case 2:
        return _analyticsTab(theme, brandTheme, successColor);
      case 3:
        return _profileTab(facultyName, theme, brandTheme, successColor);
      default:
        return _overviewTab(facultyName, successColor, brandTheme, theme);
    }
  }

  Widget _overviewTab(String name, Color successColor, AppBrandTheme? brandTheme, ThemeData theme) {
    final pendingStudentsAsync = ref.watch(pendingStudentsProvider);

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
                    Text('Welcome, $name',
                        style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('Department Faculty Advisor',
                        style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: successColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('Faculty Advisor', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: successColor)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          pendingStudentsAsync.when(
            data: (students) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statCard('${students.length}', 'Pending Verification', theme, brandTheme),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Pending Verification Requests', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (students.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('No pending student verification requests in your department.',
                          style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
                    )
                  else
                    ...students.map((s) => _verificationCard(s, name, theme, brandTheme, successColor)),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading pending students: $e'),
          ),
        ],
      ),
    );
  }

  Widget _verificationTab(String facultyName, ThemeData theme, AppBrandTheme? brandTheme, Color successColor) {
    final pendingStudentsAsync = ref.watch(pendingStudentsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Department Student Verification', style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Verify academic details & CGPA before drive application', style: GoogleFonts.inter(fontSize: 13, color: brandTheme?.textMuted)),
          const SizedBox(height: 16),
          pendingStudentsAsync.when(
            data: (students) {
              if (students.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('No students awaiting verification.', style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
                );
              }
              return Column(
                children: students.map((s) => _verificationCard(s, facultyName, theme, brandTheme, successColor)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error loading verification list: $e'),
          ),
        ],
      ),
    );
  }

  Widget _verificationCard(UserProfile s, String facultyName, ThemeData theme, AppBrandTheme? brandTheme, Color successColor) =>
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text('${s.usn} · ${s.department}', style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: s.approvalStatus == ApprovalStatus.approved ? successColor.withValues(alpha: 0.12) : Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s.approvalStatus == ApprovalStatus.approved ? 'Verified' : 'Pending',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: s.approvalStatus == ApprovalStatus.approved ? successColor : Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: brandTheme?.surfaceAlt ?? theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Submitted CGPA', style: GoogleFonts.inter(fontSize: 12, color: brandTheme?.textMuted)),
                  Text(s.cgpa?.toStringAsFixed(2) ?? 'N/A', style: GoogleFonts.ibmPlexMono(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleVerify(s, facultyName),
                    icon: Icon(s.approvalStatus == ApprovalStatus.approved ? Icons.cancel_outlined : Icons.check_circle_outline, size: 16, color: s.approvalStatus == ApprovalStatus.approved ? Colors.red : successColor),
                    label: Text(
                      s.approvalStatus == ApprovalStatus.approved ? 'Revoke Verification' : 'Verify & Approve',
                      style: GoogleFonts.inter(fontSize: 13, color: s.approvalStatus == ApprovalStatus.approved ? Colors.red : successColor, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: s.approvalStatus == ApprovalStatus.approved ? Colors.red : successColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _analyticsTab(ThemeData theme, AppBrandTheme? brandTheme, Color successColor) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Placement Analytics', style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('2026-27 Department Performance Metrics', style: GoogleFonts.inter(fontSize: 13, color: brandTheme?.textMuted)),
            const SizedBox(height: 20),
            _metricCard('Placement Rate', '28.1%', successColor, theme, brandTheme),
            _metricCard('Highest Package', '₹28 LPA', theme.colorScheme.primary, theme, brandTheme),
            _metricCard('Average Package', '₹8.4 LPA', theme.colorScheme.secondary, theme, brandTheme),
          ],
        ),
      );

  Widget _profileTab(String name, ThemeData theme, AppBrandTheme? brandTheme, Color successColor) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: successColor.withValues(alpha: 0.15),
                    child: Text(name.substring(0, 1), style: GoogleFonts.fraunces(fontSize: 28, color: successColor, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600)),
                  Text('Department Placement Advisor', style: GoogleFonts.inter(fontSize: 13, color: brandTheme?.textMuted)),
                ],
              ),
            ),
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

  Widget _metricCard(String label, String value, Color accent, ThemeData theme, AppBrandTheme? brandTheme) => Container(
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
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
            Text(value, style: GoogleFonts.ibmPlexMono(fontSize: 20, fontWeight: FontWeight.w600, color: accent)),
          ],
        ),
      );
}

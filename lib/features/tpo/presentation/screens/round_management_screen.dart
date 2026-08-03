import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../student/domain/entities/drive.dart';
import '../../../student/domain/entities/application.dart';
import '../providers/tpo_provider.dart';
import '../../../../core/services/email_notification_service.dart';

class RoundManagementScreen extends ConsumerStatefulWidget {
  final Drive drive;
  const RoundManagementScreen({required this.drive, super.key});

  @override
  ConsumerState<RoundManagementScreen> createState() =>
      _RoundManagementScreenState();
}

class _RoundManagementScreenState
    extends ConsumerState<RoundManagementScreen> {
  int? _selectedRoundIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>()!;
    final roundsAsync = ref.watch(driveRoundsProvider(widget.drive.id));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Manage Recruitment',
            style: GoogleFonts.fraunces(fontWeight: FontWeight.w600)),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: roundsAsync.when(
        data: (rounds) {
          if (rounds.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_empty_rounded,
                      size: 48, color: brandTheme.textMuted),
                  const SizedBox(height: 12),
                  Text('No recruitment rounds configured',
                      style: GoogleFonts.inter(
                          fontSize: 16, color: brandTheme.textMuted)),
                  const SizedBox(height: 8),
                  Text(
                    'Edit this drive to add recruitment rounds.\nStudents will progress through each round you configure.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: brandTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header info
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(
                    AppSpacing.sp5, 0, AppSpacing.sp5, AppSpacing.sp3),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: brandTheme.brassPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          brandTheme.brassPrimary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: brandTheme.brassPrimary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select a round to view and manage students.',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: brandTheme.textMuted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Shortlist, reject, mark absent, or add remarks from here.',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: brandTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Rounds list
              Expanded(
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sp5),
                  itemCount: rounds.length,
                  itemBuilder: (_, i) {
                    final round = rounds[i];
                    final isSelected = _selectedRoundIndex == i;
                    final isLastRound = i == rounds.length - 1;
                    final statusLower =
                        widget.drive.status.toLowerCase();
                    final isActive = statusLower == 'active' ||
                        statusLower == 'ongoing';
                    final isCompleted = statusLower == 'completed' ||
                        statusLower == 'closed';

                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: AppSpacing.sp3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? brandTheme.brassPrimary
                              : brandTheme.cardBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() => _selectedRoundIndex =
                                  isSelected ? null : i);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? brandTheme.brassPrimary
                                              .withValues(alpha: 0.15)
                                          : isCompleted
                                              ? brandTheme
                                                  .statusShortlisted
                                                  .withValues(alpha: 0.15)
                                              : brandTheme.cardBorder,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${round.roundNumber}',
                                        style: GoogleFonts.fraunces(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isActive
                                              ? brandTheme.brassPrimary
                                              : isCompleted
                                                  ? brandTheme
                                                      .statusShortlisted
                                                  : brandTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          round.roundName,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (round.scheduledDate !=
                                            null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '${round.scheduledDate!.day}/${round.scheduledDate!.month}/${round.scheduledDate!.year}',
                                            style:
                                                GoogleFonts.ibmPlexMono(
                                                    fontSize: 12,
                                                    color: brandTheme
                                                        .textMuted),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: isSelected ? 0.5 : 0,
                                    duration: const Duration(
                                        milliseconds: 200),
                                    child: Icon(
                                      Icons
                                          .keyboard_arrow_down_rounded,
                                      color: brandTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isSelected) ...[
                            const Divider(height: 1),
                            _RoundExpandedSection(
                              drive: widget.drive,
                              roundNumber: round.roundNumber,
                              roundName: round.roundName,
                              isLastRound: isLastRound,
                              totalRounds: rounds.length,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// =============================================================================
// Expanded Section — Stats + Search/Filter + Student List
// =============================================================================

class _RoundExpandedSection extends ConsumerStatefulWidget {
  final Drive drive;
  final int roundNumber;
  final String roundName;
  final bool isLastRound;
  final int totalRounds;

  const _RoundExpandedSection({
    required this.drive,
    required this.roundNumber,
    required this.roundName,
    required this.isLastRound,
    required this.totalRounds,
  });

  @override
  ConsumerState<_RoundExpandedSection> createState() =>
      _RoundExpandedSectionState();
}

class _RoundExpandedSectionState
    extends ConsumerState<_RoundExpandedSection> {
  final Set<String> _selectedIds = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>()!;
    final params = (
      driveId: widget.drive.id,
      roundNumber: widget.roundNumber,
    );
    final studentsAsync = ref.watch(roundStudentsProvider(params));

    return studentsAsync.when(
      data: (students) {
        // Compute stats
        final total = students.length;
        final shortlisted =
            students.where((s) => s['status'] == 'shortlisted').length;
        final rejected =
            students.where((s) => s['status'] == 'rejected').length;
        final absentCount = students
            .where((s) => s['attendance_status'] == 'absent')
            .length;
        final pending = total - shortlisted - rejected - absentCount;
        final progress =
            total > 0 ? ((shortlisted / total) * 100).round() : 0;

        // Apply filters
        final filtered = students.where((s) {
          final student =
              s['student'] as Map<String, dynamic>? ?? {};
          final name =
              (student['name'] as String? ?? '').toLowerCase();
          final usn =
              (student['usn'] as String? ?? '').toLowerCase();
          final matchesSearch = _searchQuery.isEmpty ||
              name.contains(_searchQuery.toLowerCase()) ||
              usn.contains(_searchQuery.toLowerCase());

          bool matchesFilter = true;
          if (_filterStatus == 'pending') {
            matchesFilter = s['status'] == 'applied';
          } else if (_filterStatus == 'shortlisted') {
            matchesFilter = s['status'] == 'shortlisted';
          } else if (_filterStatus == 'rejected') {
            matchesFilter = s['status'] == 'rejected';
          } else if (_filterStatus == 'absent') {
            matchesFilter = s['attendance_status'] == 'absent';
          }

          return matchesSearch && matchesFilter;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats Bar ──────────────────────────────────────────
            if (total > 0)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: brandTheme.surfaceAlt.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: brandTheme.cardBorder),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _statBadge('Total', '$total', brandTheme.textMuted),
                      const SizedBox(width: 12),
                      _statBadge('Pending', '$pending', Colors.orange.shade300),
                      const SizedBox(width: 12),
                      _statBadge('Shortlisted', '$shortlisted', brandTheme.statusShortlisted),
                      const SizedBox(width: 12),
                      _statBadge('Rejected', '$rejected', brandTheme.statusRejected),
                      const SizedBox(width: 12),
                      _statBadge('Absent', '$absentCount', brandTheme.statusPending),
                      const SizedBox(width: 12),
                      _statBadge('Progress', '$progress%', brandTheme.brassPrimary),
                    ],
                  ),
                ),
              ),

            // ── Search & Filter ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name or USN...',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13, color: brandTheme.textMuted),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 18, color: brandTheme.textMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: brandTheme.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: brandTheme.cardBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('All', 'all', brandTheme),
                        const SizedBox(width: 6),
                        _filterChip('Pending', 'pending', brandTheme),
                        const SizedBox(width: 6),
                        _filterChip(
                            'Shortlisted', 'shortlisted', brandTheme),
                        const SizedBox(width: 6),
                        _filterChip(
                            'Rejected', 'rejected', brandTheme),
                        const SizedBox(width: 6),
                        _filterChip(
                            'Absent', 'absent', brandTheme),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Bulk Actions ───────────────────────────────────────
            if (_selectedIds.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      brandTheme.brassPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      '${_selectedIds.length} sel',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: brandTheme.brassPrimary),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _bulkAction(
                                'Next',
                                Icons.arrow_forward_rounded,
                                brandTheme.statusShortlisted,
                                _bulkMoveNext),
                            const SizedBox(width: 4),
                            _bulkAction(
                                'Reject',
                                Icons.close_rounded,
                                brandTheme.statusRejected,
                                _bulkReject),
                            const SizedBox(width: 4),
                            _bulkAction(
                                'Absent',
                                Icons.event_busy_rounded,
                                brandTheme.statusPending,
                                _bulkAbsent),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Student List ───────────────────────────────────────
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    students.isEmpty
                        ? 'No students available in this round.'
                        : 'No students match your filter.',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: brandTheme.textMuted),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    _buildStudentCard(filtered[index], theme, brandTheme),
              ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text('Error: $e')),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stat badge
  // ---------------------------------------------------------------------------
  Widget _statBadge(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.fraunces(
              fontSize: 13, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 9, color: color.withValues(alpha: 0.7)),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Filter chip
  // ---------------------------------------------------------------------------
  Widget _filterChip(String label, String value, AppBrandTheme brandTheme) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? brandTheme.brassPrimary.withValues(alpha: 0.15)
              : brandTheme.cardBorder.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? brandTheme.brassPrimary
                : brandTheme.textMuted,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bulk action button
  // ---------------------------------------------------------------------------
  Widget _bulkAction(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Student Card
  // ---------------------------------------------------------------------------
  Widget _buildStudentCard(
      Map<String, dynamic> app, ThemeData theme, AppBrandTheme brandTheme) {
    final student = app['student'] as Map<String, dynamic>? ?? {};
    final name = student['name'] as String? ?? 'Student';
    final usn = student['usn'] as String? ?? '';
    final dept = student['department'] as String? ?? '';
    final photoUrl = student['photo_url'] as String?;
    final appId = app['id'] as String;
    final isSelected = _selectedIds.contains(appId);
    final status = app['status'] as String? ?? 'applied';
    final attendedAt = app['attended_at'] as String?;
    final attendanceStatus = app['attendance_status'] as String?;

    // Status chip color
    Color chipColor;
    String chipLabel;
    switch (status) {
      case 'selected':
      case 'offered':
        chipColor = brandTheme.statusShortlisted;
        chipLabel = 'Offered';
        break;
      case 'shortlisted':
        chipColor = brandTheme.statusShortlisted;
        chipLabel = widget.isLastRound ? 'Offered' : 'Shortlisted';
        break;
      case 'rejected':
        chipColor = brandTheme.statusRejected;
        chipLabel = 'Rejected';
        break;
      default:
        if (attendanceStatus == 'absent') {
          chipColor = brandTheme.statusPending;
          chipLabel = 'Absent';
        } else {
          chipColor = brandTheme.statusApplied;
          chipLabel = 'Pending';
        }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? brandTheme.brassPrimary.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? brandTheme.brassPrimary.withValues(alpha: 0.3)
              : brandTheme.cardBorder,
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: isSelected,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedIds.add(appId);
                } else {
                  _selectedIds.remove(appId);
                }
              });
            },
            activeColor: brandTheme.brassPrimary,
          ),

          // Photo or Initial
          _buildAvatar(photoUrl, name, brandTheme),
          const SizedBox(width: 8),

          // Name + USN + Dept + Attendance time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  [if (usn.isNotEmpty) usn, if (dept.isNotEmpty) dept]
                      .join(' · '),
                  style: GoogleFonts.inter(
                      fontSize: 11, color: brandTheme.textMuted),
                ),
                if (attendedAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Scanned at ${_formatTime(attendedAt)}',
                    style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        color: brandTheme.brassPrimary.withValues(alpha: 0.7)),
                  ),
                ],
              ],
            ),
          ),

          // Status chip + Actions
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Status chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    chipLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: chipColor),
                  ),
                ),
                const SizedBox(height: 6),

              // Actions popup
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    size: 18, color: brandTheme.textMuted),
                onSelected: (action) => _handleAction(action, app),
                itemBuilder: (_) {
                  final items = <PopupMenuItem<String>>[
                    PopupMenuItem(
                        value: 'remarks',
                        child: Text('Add Remarks',
                            style: GoogleFonts.inter(fontSize: 13))),
                  ];

                  if (!widget.isLastRound) {
                    items.insert(
                      0,
                      PopupMenuItem(
                          value: 'move',
                          child: Text('Move to Next Round',
                              style: GoogleFonts.inter(fontSize: 13))),
                    );
                  } else {
                    items.insert(
                      0,
                      PopupMenuItem(
                          value: 'offer',
                          child: Text('Offer Selected',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: brandTheme.statusShortlisted))),
                    );
                  }

                  items.addAll([
                    PopupMenuItem(
                        value: 'reject',
                        child: Text('Reject',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: brandTheme.statusRejected))),
                    PopupMenuItem(
                        value: 'absent',
                        child: Text('Mark Absent',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: brandTheme.statusPending))),
                  ]);

                  return items;
                },
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Avatar
  // ---------------------------------------------------------------------------
  Widget _buildAvatar(
      String? photoUrl, String name, AppBrandTheme brandTheme) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: brandTheme.brassSoft,
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: brandTheme.brassSoft,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
        style: GoogleFonts.fraunces(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: brandTheme.brassPrimary),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Format ISO timestamp → "5:18 PM"
  // ---------------------------------------------------------------------------
  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    } catch (_) {
      return isoString;
    }
  }

  // ---------------------------------------------------------------------------
  // Action handlers
  // ---------------------------------------------------------------------------
  void _handleAction(String action, Map<String, dynamic> app) {
    switch (action) {
      case 'move':
        _moveToNextRound([app['id']]);
        break;
      case 'offer':
        _offerSelected([app['id']]);
        break;
      case 'reject':
        _rejectStudents([app['id']]);
        break;
      case 'absent':
        _markAbsent([app['id']]);
        break;
      case 'remarks':
        _showRemarksDialog(app['id']);
        break;
    }
  }

  Future<void> _bulkMoveNext() async {
    await _moveToNextRound(_selectedIds.toList());
    setState(() => _selectedIds.clear());
  }

  Future<void> _bulkReject() async {
    await _rejectStudents(_selectedIds.toList());
    setState(() => _selectedIds.clear());
  }

  Future<void> _bulkAbsent() async {
    await _markAbsent(_selectedIds.toList());
    setState(() => _selectedIds.clear());
  }

  Future<void> _moveToNextRound(List<String> appIds) async {
    final repo = ref.read(tpoRepositoryProvider);
    final user = Supabase.instance.client.auth.currentUser;
    await repo.moveStudentsToNextRound(
      driveId: widget.drive.id,
      currentRoundNumber: widget.roundNumber,
      applicationIds: appIds,
      performedBy: user?.id ?? '',
    );
    if (!mounted) return;
    ref.invalidate(roundStudentsProvider(
        (driveId: widget.drive.id, roundNumber: widget.roundNumber)));
    // Also invalidate next round so it picks up promoted students
    ref.invalidate(roundStudentsProvider(
        (driveId: widget.drive.id, roundNumber: widget.roundNumber + 1)));
    // Dispatch Round Qualified Emails & Push Notifications to promoted students
    try {
      final emailService = ref.read(emailNotificationServiceProvider);
      for (final appId in appIds) {
        final appData = await Supabase.instance.client
            .from('applications')
            .select('student_id, current_round, student:profiles(email, name)')
            .eq('id', appId)
            .maybeSingle();
        if (appData != null && (appData['current_round'] as int? ?? 0) == widget.roundNumber + 1) {
          final studentId = appData['student_id'] as String?;
          final student = appData['student'] as Map<String, dynamic>?;
          final email = student?['email'] as String?;
          final name = (student?['name'] as String?) ?? 'Student';

          if (email != null && email.contains('@')) {
            emailService.sendRoundQualifiedEmail(
              recipientEmail: email,
              studentName: name,
              companyName: widget.drive.companyName,
              qualifiedRound: widget.roundName,
              nextRoundName: 'Round ${widget.roundNumber + 1}',
            );
          }

          if (studentId != null && studentId.isNotEmpty) {
            repo.sendNotification(
              userId: studentId,
              title: 'Congratulations! You Cleared ${widget.roundName}',
              body: 'You cleared ${widget.roundName} for ${widget.drive.companyName} and qualified for Round ${widget.roundNumber + 1}!',
              type: 'round_clear',
              driveId: widget.drive.id,
              applicationId: appId,
            );
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${appIds.length} student(s) moved to next round')),
      );
    }
  }

  Future<void> _offerSelected(List<String> appIds) async {
    final repo = ref.read(tpoRepositoryProvider);
    final user = Supabase.instance.client.auth.currentUser;
    for (final appId in appIds) {
      await repo.updateApplicationStatus(
        applicationId: appId,
        status: ApplicationStatus.selected,
      );
      // Update round status
      final roundData = await ref.read(tpoRepositoryProvider).getDriveRounds(widget.drive.id);
      final currentRound = roundData.where((r) => r.roundNumber == widget.roundNumber);
      if (currentRound.isNotEmpty) {
        await repo.addRoundRemarks(
          applicationId: appId,
          roundId: currentRound.first.id,
          remarks: 'Offer selected',
          performedBy: user?.id ?? '',
        );
      }
    }
    ref.invalidate(roundStudentsProvider(
        (driveId: widget.drive.id, roundNumber: widget.roundNumber)));
    // Dispatch Offer Emails
    try {
      final emailService = ref.read(emailNotificationServiceProvider);
      for (final appId in appIds) {
        final appData = await Supabase.instance.client
            .from('applications')
            .select('student_id, student:profiles(email, name)')
            .eq('id', appId)
            .maybeSingle();
        if (appData != null && appData['student'] != null) {
          final student = appData['student'] as Map<String, dynamic>;
          final email = student['email'] as String?;
          final name = (student['name'] as String?) ?? 'Student';
          if (email != null && email.contains('@')) {
            emailService.sendOfferReleasedEmail(
              recipientEmail: email,
              studentName: name,
              companyName: widget.drive.companyName,
              roleTitle: widget.drive.roleTitle,
              package: widget.drive.ctcOrStipend,
            );
          }
          // Push notification to the offered student
          try {
            await Supabase.instance.client.functions.invoke('send-fcm-push', body: {
              'user_ids': [appData['student_id']],
              'drive_id': widget.drive.id,
              'application_id': appId,
              'title': 'Offer Released',
              'body': 'Congratulations! You have been offered for ${widget.drive.companyName} - ${widget.drive.roleTitle}. Check your offers.',
            });
          } catch (pushErr) {
            debugPrint('[RoundManagement] Offer push warning: $pushErr');
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${appIds.length} student(s) offered selection')),
      );
    }
  }

  Future<void> _rejectStudents(List<String> appIds) async {
    final repo = ref.read(tpoRepositoryProvider);
    final user = Supabase.instance.client.auth.currentUser;
    await repo.rejectStudents(
      driveId: widget.drive.id,
      currentRoundNumber: widget.roundNumber,
      applicationIds: appIds,
      performedBy: user?.id ?? '',
    );
    ref.invalidate(roundStudentsProvider(
        (driveId: widget.drive.id, roundNumber: widget.roundNumber)));
    // Dispatch Rejection Emails
    try {
      final emailService = ref.read(emailNotificationServiceProvider);
      for (final appId in appIds) {
        final appData = await Supabase.instance.client
            .from('applications')
            .select('student_id, student:profiles(email, name)')
            .eq('id', appId)
            .maybeSingle();
        if (appData != null && appData['student'] != null) {
          final student = appData['student'] as Map<String, dynamic>;
          final email = student['email'] as String?;
          final name = (student['name'] as String?) ?? 'Student';
          if (email != null && email.contains('@')) {
            emailService.sendRoundRejectedEmail(
              recipientEmail: email,
              studentName: name,
              companyName: widget.drive.companyName,
              rejectedRound: widget.roundName,
            );
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${appIds.length} student(s) rejected')),
      );
    }
  }

  Future<void> _markAbsent(List<String> appIds) async {
    final repo = ref.read(tpoRepositoryProvider);
    final user = Supabase.instance.client.auth.currentUser;
    await repo.markStudentsAbsent(
      driveId: widget.drive.id,
      currentRoundNumber: widget.roundNumber,
      applicationIds: appIds,
      performedBy: user?.id ?? '',
    );
    ref.invalidate(roundStudentsProvider(
        (driveId: widget.drive.id, roundNumber: widget.roundNumber)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${appIds.length} student(s) marked absent')),
      );
    }
  }

  void _showRemarksDialog(String applicationId) {
    final remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Remarks',
            style:
                GoogleFonts.fraunces(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: remarksController,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: 'Enter remarks...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(tpoRepositoryProvider);
              final user =
                  Supabase.instance.client.auth.currentUser;
              final roundData = await ref
                  .read(tpoRepositoryProvider)
                  .getDriveRounds(widget.drive.id);
              final currentRound = roundData.firstWhere(
                  (r) => r.roundNumber == widget.roundNumber);
              await repo.addRoundRemarks(
                applicationId: applicationId,
                roundId: currentRound.id,
                remarks: remarksController.text.trim(),
                performedBy: user?.id ?? '',
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

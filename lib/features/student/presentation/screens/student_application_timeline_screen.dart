import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/file_name_extractor.dart';
import '../providers/student_timeline_provider.dart';

class StudentApplicationTimelineScreen extends ConsumerWidget {
  const StudentApplicationTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>()!;
    final timelineAsync = ref.watch(studentTimelineProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: timelineAsync.when(
        data: (applications) {
          if (applications.isEmpty) {
            return _emptyState(context, theme, brandTheme, topPadding);
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topPadding + AppSpacing.sp4,
                    left: AppSpacing.sp5,
                    right: AppSpacing.sp5,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Application Timeline',
                          style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Live recruitment stage tracking',
                          style: GoogleFonts.inter(fontSize: 13, color: brandTheme.textMuted)),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.sp5, AppSpacing.sp4, AppSpacing.sp5, 110,
                ),
                sliver: SliverList.separated(
                  itemCount: applications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sp4),
                  itemBuilder: (_, i) => _ApplicationTimelineCard(data: applications[i]),
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: Padding(
            padding: EdgeInsets.only(top: topPadding + 100),
            child: const CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.only(top: topPadding + 100),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: brandTheme.statusRejected),
                const SizedBox(height: 12),
                Text('Failed to load timeline', style: GoogleFonts.inter(fontSize: 14)),
                const SizedBox(height: 8),
                Text(e.toString(), style: GoogleFonts.inter(fontSize: 12, color: brandTheme.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, ThemeData theme, AppBrandTheme brandTheme, double topPadding) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: topPadding + 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: brandTheme.brassSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timeline_rounded, size: 40, color: brandTheme.brassPrimary),
            ),
            const SizedBox(height: AppSpacing.sp4),
            Text('No applications yet',
                style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'When you apply to drives, your recruitment\njourney will appear here.',
              style: GoogleFonts.inter(fontSize: 13, color: brandTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sp5),
            GestureDetector(
              onTap: () {
                // Navigate to drives tab (index 1)
                final navigator = context.findAncestorStateOfType<State>();
                if (navigator != null && navigator.mounted) {
                  // Use go_router to pop to student dashboard, then switch tab
                  context.go('/student');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: brandTheme.brassGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Explore Drives',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// APPLICATION TIMELINE CARD
// ──────────────────────────────────────────────────────────────────────────────

class _ApplicationTimelineCard extends ConsumerWidget {
  final ApplicationTimelineData data;
  const _ApplicationTimelineCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandTheme = theme.extension<AppBrandTheme>()!;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusBanner(brandTheme, theme),
          _applicationHeader(brandTheme, theme),
          _progressSection(brandTheme, theme),
          _verticalTimeline(brandTheme, theme),
          _currentRoundCard(brandTheme, theme),
          _applicationSummary(brandTheme, theme),
          _documentsSection(brandTheme, theme),
          _notificationsSection(brandTheme, theme, ref),
        ],
      ),
    );
  }

  // ── Status Banner ────────────────────────────────────────────────────────
  Widget _statusBanner(AppBrandTheme brandTheme, ThemeData theme) {
    final (color, icon, title, subtitle) = _getBannerInfo(brandTheme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: brandTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String, String) _getBannerInfo(AppBrandTheme brandTheme) {
    final status = data.status.toLowerCase();
    if (status == 'rejected' || status == 'not_selected') {
      return (
        const Color(0xFFEF5350),
        Icons.cancel_rounded,
        'Application Closed',
        'You were not selected for this drive.',
      );
    }
    if (status == 'selected') {
      return (
        const Color(0xFF42A5F5),
        Icons.celebration_rounded,
        'Congratulations!',
        'Offer Released — Check your email for details.',
      );
    }
    if (data.currentRound > 0 && data.currentRound <= data.totalRounds) {
      final currentRound = data.rounds[data.currentRound - 1];
    final roundName = currentRound['round_name'] as String? ?? 'Round ${currentRound['round_number'] ?? data.currentRound}';
      return (
        brandTheme.brassPrimary,
        Icons.play_circle_outline_rounded,
        roundName,
        'Round ${data.currentRound} of ${data.totalRounds} — In Progress',
      );
    }
    return (
      brandTheme.statusShortlisted,
      Icons.check_circle_outline_rounded,
      'Application Submitted',
      'Waiting for recruitment process to begin.',
    );
  }

  // ── Application Header ───────────────────────────────────────────────────
  Widget _applicationHeader(AppBrandTheme brandTheme, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: brandTheme.brassSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                data.companyName.isNotEmpty
                    ? data.companyName.substring(0, 1).toUpperCase()
                    : '?',
                style: GoogleFonts.fraunces(
                    fontSize: 20, fontWeight: FontWeight.w700, color: brandTheme.brassPrimary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.companyName,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(data.roleTitle,
                    style: GoogleFonts.inter(fontSize: 13, color: brandTheme.textMuted)),
                if (data.ctcDisplay.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(data.ctcDisplay,
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 12, fontWeight: FontWeight.w600, color: brandTheme.brassPrimary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress Bar ─────────────────────────────────────────────────────────
  Widget _progressSection(AppBrandTheme brandTheme, ThemeData theme) {
    final percent = data.progressPercent;
    final percentLabel = '${(percent * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600, color: brandTheme.textMuted)),
              Text('$percentLabel · ${data.completedRounds}/${data.totalRounds} rounds',
                  style: GoogleFonts.ibmPlexMono(
                      fontSize: 11, fontWeight: FontWeight.w600, color: brandTheme.brassPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: brandTheme.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(brandTheme.brassPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Applied ${DateFormat('dd MMM yyyy').format(data.appliedAt)}',
                style: GoogleFonts.ibmPlexMono(fontSize: 10, color: brandTheme.textMuted),
              ),
              Text(
                'Deadline ${DateFormat('dd MMM yyyy').format(data.applicationDeadline)}',
                style: GoogleFonts.ibmPlexMono(fontSize: 10, color: brandTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Vertical Timeline ────────────────────────────────────────────────────
  Widget _verticalTimeline(AppBrandTheme brandTheme, ThemeData theme) {
    if (data.rounds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'No rounds configured yet. The TPO will add recruitment rounds soon.',
          style: GoogleFonts.inter(fontSize: 12, color: brandTheme.textMuted),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recruitment Stages',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          ...List.generate(data.rounds.length, (i) {
            final round = data.rounds[i];
            final roundId = round['id'] as String? ?? '';
            final roundName = round['round_name'] as String? ?? 'Round ${round['round_number'] ?? (i + 1)}';
            final progress = data.progressForRound(roundId);
            final isLast = i == data.rounds.length - 1;

            return _timelineNode(
              roundName: roundName,
              roundNumber: round['round_number'] as int? ?? (i + 1),
              progress: progress,
              isCurrent: (i + 1) == data.currentRound,
              isCompleted: progress != null && (progress['result'] == 'cleared' ||
                  progress['result'] == 'selected' || progress['result'] == 'passed'),
              isRejected: progress != null && (progress['result'] == 'rejected' ||
                  progress['result'] == 'not_selected' || progress['result'] == 'failed'),
              isAbsent: progress != null && progress['attended'] == false &&
                  progress['result'] == 'rejected',
              isLast: isLast,
              brandTheme: brandTheme,
              theme: theme,
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _timelineNode({
    required String roundName,
    required int roundNumber,
    Map<String, dynamic>? progress,
    required bool isCurrent,
    required bool isCompleted,
    required bool isRejected,
    required bool isAbsent,
    required bool isLast,
    required AppBrandTheme brandTheme,
    required ThemeData theme,
  }) {
    final (dotColor, dotIcon) = _getDotStyle(isCompleted, isCurrent, isRejected, isAbsent, brandTheme);
    final attended = progress?['attended'] as bool? ?? false;
    final result = progress?['result'] as String? ?? 'pending';
    final remarks = progress?['remarks'] as String?;
    final updatedAt = progress?['updated_at'] as String?;
    final scheduledDate = progress?['scheduled_date'] as String? ??
        (progress?['round'] is Map ? (progress?['round'] as Map)['scheduled_date'] as String? : null);
    final instructions = progress?['instructions'] as String? ??
        (progress?['round'] is Map ? (progress?['round'] as Map)['instructions'] as String? : null);
    final venueOrLink = progress?['venue_or_link'] as String? ??
        (progress?['round'] is Map ? (progress?['round'] as Map)['venue_or_link'] as String? : null);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + dot
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: brandTheme.brassPrimary, width: 2)
                        : null,
                    boxShadow: isCurrent
                        ? [BoxShadow(color: brandTheme.brassSoft, blurRadius: 0, spreadRadius: 3)]
                        : null,
                  ),
                  child: Center(
                    child: dotIcon ??
                        Text('$roundNumber',
                            style: GoogleFonts.ibmPlexMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? brandTheme.brassPrimary.withValues(alpha: 0.4)
                          : brandTheme.cardBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent
                    ? brandTheme.brassPrimary.withValues(alpha: 0.06)
                    : isRejected
                        ? brandTheme.statusRejected.withValues(alpha: 0.04)
                        : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent
                      ? brandTheme.brassPrimary.withValues(alpha: 0.3)
                      : isRejected
                          ? brandTheme.statusRejected.withValues(alpha: 0.2)
                          : brandTheme.cardBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(roundName,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface)),
                      ),
                      _resultChip(result, attended, brandTheme),
                    ],
                  ),
                  if (isCurrent && scheduledDate != null) ...[
                    const SizedBox(height: 8),
                    _detailRow(Icons.event_rounded, 'Scheduled', _formatDate(scheduledDate), brandTheme),
                  ],
                  if (isCurrent && venueOrLink != null && venueOrLink.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _detailRow(Icons.location_on_outlined, 'Venue', venueOrLink, brandTheme),
                  ],
                  if (isCurrent && instructions != null && instructions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: brandTheme.statusPending.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: brandTheme.statusPending),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(instructions,
                                style: GoogleFonts.inter(fontSize: 11, color: brandTheme.textMuted)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isCompleted && updatedAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Completed ${_formatDate(updatedAt)}',
                      style: GoogleFonts.ibmPlexMono(fontSize: 10, color: brandTheme.statusShortlisted),
                    ),
                  ],
                  if (remarks != null && remarks.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: brandTheme.statusPending.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.note_rounded, size: 12, color: brandTheme.statusPending),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(remarks,
                                style: GoogleFonts.inter(fontSize: 11, color: brandTheme.textMuted)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Widget?) _getDotStyle(bool isCompleted, bool isCurrent, bool isRejected, bool isAbsent, AppBrandTheme brandTheme) {
    if (isAbsent) {
      return (
        const Color(0xFFFF9800),
        const Icon(Icons.event_busy_rounded, size: 12, color: Colors.white),
      );
    }
    if (isRejected) {
      return (
        brandTheme.statusRejected,
        const Icon(Icons.close_rounded, size: 12, color: Colors.white),
      );
    }
    if (isCompleted) {
      return (
        brandTheme.statusShortlisted,
        const Icon(Icons.check_rounded, size: 12, color: Colors.white),
      );
    }
    if (isCurrent) {
      return (
        brandTheme.surfaceAlt,
        null,
      );
    }
    return (brandTheme.cardBorder, null);
  }

  Widget _resultChip(String result, bool attended, AppBrandTheme brandTheme) {
    final (color, label) = switch (result.toLowerCase()) {
      'cleared' || 'passed' || 'selected' => (brandTheme.statusShortlisted, 'Passed'),
      'rejected' || 'failed' || 'not_selected' => (brandTheme.statusRejected, 'Rejected'),
      _ when !attended => (brandTheme.statusPending, 'Pending'),
      _ => (brandTheme.statusPending, 'Awaiting'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  // ── Current Round Card ───────────────────────────────────────────────────
  Widget _currentRoundCard(AppBrandTheme brandTheme, ThemeData theme) {
    if (data.currentRound <= 0 || data.currentRound > data.totalRounds) {
      return const SizedBox.shrink();
    }

    final currentRound = data.rounds[data.currentRound - 1];
    final roundName = currentRound['round_name'] as String? ?? 'Round ${data.currentRound}';
    final scheduledDate = currentRound['scheduled_date'] as String?;
    final instructions = currentRound['instructions'] as String?;
    final venueOrLink = currentRound['venue_or_link'] as String?;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            brandTheme.brassPrimary.withValues(alpha: 0.08),
            brandTheme.brassPrimary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brandTheme.brassPrimary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle_fill_rounded, size: 18, color: brandTheme.brassPrimary),
              const SizedBox(width: 8),
              Text('Current Round',
                  style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w700, color: brandTheme.brassPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(roundName,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          if (scheduledDate != null) ...[
            const SizedBox(height: 6),
            _detailRow(Icons.calendar_today_rounded, 'Date', _formatDate(scheduledDate), brandTheme),
          ],
          if (venueOrLink != null && venueOrLink.isNotEmpty) ...[
            const SizedBox(height: 4),
            _detailRow(Icons.location_on_outlined, 'Venue', venueOrLink, brandTheme),
          ],
          if (instructions != null && instructions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(instructions,
                style: GoogleFonts.inter(fontSize: 12, color: brandTheme.textMuted)),
          ],
        ],
      ),
    );
  }

  // ── Application Summary ──────────────────────────────────────────────────
  Widget _applicationSummary(AppBrandTheme brandTheme, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brandTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Application Summary',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 10),
          _summaryRow('Application Date', DateFormat('dd MMM yyyy').format(data.appliedAt), brandTheme),
          _summaryRow('Drive Status', data.driveStatus.toUpperCase(), brandTheme),
          _summaryRow('Current Round', data.currentRound > 0 && data.currentRound <= data.totalRounds
              ? data.rounds[data.currentRound - 1]['round_name'] as String? ?? 'Round ${data.currentRound}'
              : '—', brandTheme),
          _summaryRow('Eligible', 'Yes', brandTheme),
          _summaryRow('Last Updated', DateFormat('dd MMM yyyy').format(DateTime.now()), brandTheme),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, AppBrandTheme brandTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: brandTheme.textMuted)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: brandTheme.textMuted)),
        ],
      ),
    );
  }

  // ── Documents Section ────────────────────────────────────────────────────
  Widget _documentsSection(AppBrandTheme brandTheme, ThemeData theme) {
    final hasResume = data.resumeUrl.isNotEmpty;
    final fileName = hasResume ? FileNameExtractor.extract(data.resumeUrl) : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brandTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Documents',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: brandTheme.brassPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resume', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    if (hasResume)
                      Text(fileName ?? 'Resume',
                          style: GoogleFonts.inter(fontSize: 11, color: brandTheme.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasResume
                      ? brandTheme.statusShortlisted.withValues(alpha: 0.12)
                      : brandTheme.statusPending.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  hasResume ? 'Uploaded' : 'Not Uploaded',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: hasResume ? brandTheme.statusShortlisted : brandTheme.statusPending),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Notifications Section ────────────────────────────────────────────────
  Widget _notificationsSection(AppBrandTheme brandTheme, ThemeData theme, WidgetRef ref) {
    final notifsAsync = ref.watch(studentNotificationsProvider);

    return notifsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) return const SizedBox.shrink();

        // Filter to notifications related to this application
        final relevant = notifications.where((n) =>
            n['application_id'] == data.applicationId ||
            n['drive_id'] == data.driveId).toList();

        if (relevant.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: brandTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notifications',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 10),
              ...relevant.take(3).map((n) {
                final type = n['type'] as String? ?? 'info';
                final color = switch (type) {
                  'success' => brandTheme.statusShortlisted,
                  'warning' => brandTheme.statusPending,
                  'error' => brandTheme.statusRejected,
                  _ => brandTheme.brassPrimary,
                };
                final icon = switch (type) {
                  'success' => Icons.check_circle_outline_rounded,
                  'warning' => Icons.warning_amber_rounded,
                  'error' => Icons.error_outline_rounded,
                  _ => Icons.info_outline_rounded,
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['title'] as String? ?? '',
                                style: GoogleFonts.inter(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(n['body'] as String? ?? '',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: brandTheme.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Widget _detailRow(IconData icon, String label, String value, AppBrandTheme brandTheme) {
    return Row(
      children: [
        Icon(icon, size: 14, color: brandTheme.textMuted),
        const SizedBox(width: 6),
        Text('$label: ', style: GoogleFonts.ibmPlexMono(fontSize: 11, color: brandTheme.textMuted)),
        Expanded(
          child: Text(value,
              style: GoogleFonts.ibmPlexMono(
                  fontSize: 11, fontWeight: FontWeight.w600, color: brandTheme.textMuted)),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }
}

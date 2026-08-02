import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Full application data with rounds and round progress for the timeline.
class ApplicationTimelineData {
  final String applicationId;
  final String driveId;
  final String status;
  final int currentRound;
  final DateTime appliedAt;
  final String companyName;
  final String roleTitle;
  final String ctcDisplay;
  final DateTime applicationDeadline;
  final String driveStatus;
  final String resumeUrl;
  final List<Map<String, dynamic>> rounds;
  final List<Map<String, dynamic>> roundProgress;

  ApplicationTimelineData({
    required this.applicationId,
    required this.driveId,
    required this.status,
    required this.currentRound,
    required this.appliedAt,
    required this.companyName,
    required this.roleTitle,
    required this.ctcDisplay,
    required this.applicationDeadline,
    required this.driveStatus,
    required this.resumeUrl,
    required this.rounds,
    required this.roundProgress,
  });

  int get totalRounds => rounds.length;
  int get completedRounds => roundProgress.where((r) =>
      r['result'] == 'cleared' || r['result'] == 'selected' || r['result'] == 'passed').length;
  double get progressPercent => totalRounds > 0 ? completedRounds / totalRounds : 0;

  /// Get the round_id that the student is currently on.
  String? get currentRoundId {
    if (currentRound <= 0 || currentRound > rounds.length) return null;
    return rounds[currentRound - 1]['id'] as String?;
  }

  /// Get progress for a specific round.
  Map<String, dynamic>? progressForRound(String roundId) {
    try {
      return roundProgress.firstWhere((p) => p['round_id'] == roundId);
    } catch (_) {
      return null;
    }
  }
}

/// Fetches full timeline data for all of the current student's applications.
final studentTimelineProvider = FutureProvider<List<ApplicationTimelineData>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  // Execute independent parallel queries for instantaneous data fetching
  final results = await Future.wait([
    // [0] Fetch applications with nested drive + company + rounds
    Supabase.instance.client
        .from('applications')
        .select('''
          id, drive_id, status, current_round, resume_version_url, applied_at, updated_at,
          drive:drives(
            id, role, package_lpa,
            end_date,
            company:companies(name),
            drive_rounds(id, round_number, round_name, instructions, scheduled_date, round_date, round_time, venue_or_link)
          )
        ''')
        .eq('student_id', user.id)
        .order('applied_at', ascending: false),

    // [1] Fetch profile for resume
    Supabase.instance.client
        .from('profiles')
        .select('resume_url')
        .eq('id', user.id)
        .maybeSingle(),
  ]);

  final apps = (results[0] as List).cast<Map<String, dynamic>>();
  final profileResponse = results[1] as Map<String, dynamic>?;
  final resumeUrl = profileResponse?['resume_url'] as String? ?? '';

  if (apps.isEmpty) return [];

  // Fetch round progress for all applications in parallel
  final appIds = apps.map((a) => a['id'] as String).toList();
  List<Map<String, dynamic>> allProgress = [];
  try {
    final progressResponse = await Supabase.instance.client
        .from('application_round_status')
        .select('*, round:drive_rounds(round_number, round_name)')
        .inFilter('application_id', appIds);
    allProgress = (progressResponse as List).cast<Map<String, dynamic>>();
  } catch (_) {}

  // Map into ApplicationTimelineData
  return apps.map((app) {
    final drive = app['drive'] as Map<String, dynamic>? ?? {};
    final company = drive['company'] as Map<String, dynamic>? ?? {};
    final rounds = (drive['drive_rounds'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Sort rounds by round_number
    rounds.sort((a, b) => (a['round_number'] as int? ?? 0).compareTo(b['round_number'] as int? ?? 0));

    // Get progress for this application
    final appProgress = allProgress.where((p) => p['application_id'] == app['id']).toList();

    String ctcDisplay = 'Disclosed on selection';
    if (drive['ctc_or_stipend'] != null) {
      ctcDisplay = drive['ctc_or_stipend'].toString();
    } else if (drive['package_lpa'] != null) {
      ctcDisplay = '₹${drive['package_lpa']} LPA';
    }

    final deadlineStr = drive['end_date'] as String? ?? drive['application_deadline'] as String? ?? '';
    final deadline = DateTime.tryParse(deadlineStr) ?? DateTime.now().add(const Duration(days: 14));

    final appResumeUrl = app['resume_version_url'] as String?;
    final finalResumeUrl = (appResumeUrl != null && appResumeUrl.isNotEmpty) ? appResumeUrl : resumeUrl;

    return ApplicationTimelineData(
      applicationId: app['id'] as String,
      driveId: app['drive_id'] as String,
      status: app['status'] as String? ?? 'applied',
      currentRound: app['current_round'] as int? ?? 0,
      appliedAt: DateTime.tryParse(app['applied_at'] as String? ?? '') ?? DateTime.now(),
      companyName: company['name'] as String? ?? 'Company',
      roleTitle: drive['role_title'] as String? ?? drive['role'] as String? ?? 'Role',
      ctcDisplay: ctcDisplay,
      applicationDeadline: deadline,
      driveStatus: drive['drive_status'] as String? ?? drive['status'] as String? ?? 'upcoming',
      resumeUrl: finalResumeUrl,
      rounds: rounds,
      roundProgress: appProgress,
    );
  }).toList();
});

/// Latest notifications for the student.
final studentNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  final response = await Supabase.instance.client
      .from('notifications')
      .select('id, title, body, type, read, created_at, drive_id, application_id')
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(20);

  return (response as List).cast<Map<String, dynamic>>();
});

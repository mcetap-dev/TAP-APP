enum ApplicationStatus {
  applied,
  shortlisted,
  interview,
  rejected,
  selected;

  static ApplicationStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'shortlisted':
        return ApplicationStatus.shortlisted;
      case 'interview':
        return ApplicationStatus.interview;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'selected':
        return ApplicationStatus.selected;
      default:
        return ApplicationStatus.applied;
    }
  }
}

class Application {
  final String id;
  final String driveId;
  final String studentId;
  final ApplicationStatus status;
  final int currentRound;
  final DateTime appliedAt;

  Application({
    required this.id,
    required this.driveId,
    required this.studentId,
    required this.status,
    required this.currentRound,
    required this.appliedAt,
  });

  factory Application.fromMap(Map<String, dynamic> map) {
    return Application(
      id: map['id'] as String? ?? '',
      driveId: map['drive_id'] as String? ?? '',
      studentId: map['student_id'] as String? ?? '',
      status: ApplicationStatus.fromString(map['status'] as String?),
      currentRound: map['current_round'] as int? ?? 0,
      appliedAt: DateTime.tryParse(map['applied_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
class Drive {
  final String id;
  final String companyId;
  final String companyName;
  final String roleTitle;
  final String ctcOrStipend;
  final String jobDescription;
  final List<String> eligibilityBranches;
  final double cgpaCutoff;
  final int backlogLimit;
  final DateTime applicationDeadline;
  final String status;

  Drive({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.roleTitle,
    required this.ctcOrStipend,
    required this.jobDescription,
    required this.eligibilityBranches,
    required this.cgpaCutoff,
    required this.backlogLimit,
    required this.applicationDeadline,
    required this.status,
  });

  factory Drive.fromMap(Map<String, dynamic> map) {
    return Drive(
      id: map['id'] as String? ?? '',
      companyId: map['company_id'] as String? ?? '',
      companyName: map['company'] != null ? (map['company']['name'] as String? ?? 'Company') : 'Company',
      roleTitle: map['role_title'] as String? ?? 'Job Role',
      ctcOrStipend: map['ctc_or_stipend'] as String? ?? 'Disclosed on selection',
      jobDescription: map['job_description'] as String? ?? '',
      eligibilityBranches: List<String>.from(map['eligibility_branches'] ?? []),
      cgpaCutoff: (map['cgpa_cutoff'] as num?)?.toDouble() ?? 0.0,
      backlogLimit: map['backlog_limit'] as int? ?? 0,
      applicationDeadline: DateTime.tryParse(map['application_deadline'] as String? ?? '') ?? DateTime.now().add(const Duration(days: 7)),
      status: map['status'] as String? ?? 'draft',
    );
  }
}
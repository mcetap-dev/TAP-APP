enum UserRole {
  admin,
  tpo,
  facultyCoordinator,
  student;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'tpo':
        return UserRole.tpo;
      case 'faculty_coordinator':
      case 'faculty':
        return UserRole.facultyCoordinator;
      case 'student':
        return UserRole.student;
      default:
        // Never silently fall back to student — surface the bad role value
        throw ArgumentError('Unknown role value: "$value". Check the profiles table.');
    }
  }

  String get dbValue {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.tpo:
        return 'tpo';
      case UserRole.facultyCoordinator:
        return 'faculty_coordinator';
      case UserRole.student:
        return 'student';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.tpo:
        return 'TPO Officer';
      case UserRole.facultyCoordinator:
        return 'Faculty Coordinator';
      case UserRole.student:
        return 'Student';
    }
  }
}

enum ApprovalStatus {
  pending,
  approved,
  rejected;

  static ApprovalStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Pending Verification';
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.rejected:
        return 'Rejected';
    }
  }
}

enum ConsentStatus {
  notSet,
  optedIn,
  optedOut;

  static ConsentStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'opted_in':
        return ConsentStatus.optedIn;
      case 'opted_out':
        return ConsentStatus.optedOut;
      default:
        return ConsentStatus.notSet;
    }
  }
}

/// Represents a user's profile from the `profiles` table in Supabase.
class UserProfile {
  final String id;
  final UserRole role;
  final String name;
  final String email;
  final String? phone;

  // Student specific
  final String? usn;
  final String? department;
  final String? batch;
  final double? tenthPercent;
  final double? twelfthOrDiplomaPercent;
  final double? cgpa;
  final int activeBacklogs;
  final String? resumeUrl;
  final String? photoUrl;
  final String? idProofUrl;
  final List<String> skills;

  final ConsentStatus consentStatus;
  final String? consentReason;

  // Approval gate: student blocked from applying until approved by Faculty Coordinator
  final ApprovalStatus approvalStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.phone,
    this.usn,
    this.department,
    this.batch,
    this.tenthPercent,
    this.twelfthOrDiplomaPercent,
    this.cgpa,
    this.activeBacklogs = 0,
    this.resumeUrl,
    this.photoUrl,
    this.idProofUrl,
    this.skills = const [],
    this.consentStatus = ConsentStatus.notSet,
    this.consentReason,
    this.approvalStatus = ApprovalStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper alias for existing UI code compatibility
  String get fullName => name;
  bool get emailVerified => true;
  String? get rollNumber => usn;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      role: UserRole.fromString(map['role'] as String? ?? 'student'),
      name: map['name'] as String? ?? map['full_name'] as String? ?? 'User',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      usn: map['usn'] as String? ?? map['roll_number'] as String?,
      department: map['department'] as String?,
      batch: map['batch'] as String?,
      tenthPercent: (map['tenth_percent'] as num?)?.toDouble(),
      twelfthOrDiplomaPercent: (map['twelfth_or_diploma_percent'] as num?)?.toDouble(),
      cgpa: (map['cgpa'] as num?)?.toDouble(),
      activeBacklogs: map['active_backlogs'] as int? ?? 0,
      resumeUrl: map['resume_url'] as String?,
      photoUrl: map['photo_url'] as String?,
      idProofUrl: map['id_proof_url'] as String?,
      skills: (map['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      consentStatus: ConsentStatus.fromString(map['consent_status'] as String?),
      consentReason: map['consent_reason'] as String?,
      approvalStatus: ApprovalStatus.fromString(map['approval_status'] as String?),
      approvedBy: map['approved_by'] as String?,
      approvedAt: map['approved_at'] != null ? DateTime.parse(map['approved_at'] as String) : null,
      rejectionReason: map['rejection_reason'] as String?,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role.dbValue,
        'name': name,
        'email': email,
        'phone': phone,
        'usn': usn,
        'department': department,
        'batch': batch,
        'tenth_percent': tenthPercent,
        'twelfth_or_diploma_percent': twelfthOrDiplomaPercent,
        'cgpa': cgpa,
        'active_backlogs': activeBacklogs,
        'resume_url': resumeUrl,
        'photo_url': photoUrl,
        'id_proof_url': idProofUrl,
        'skills': skills,
        'consent_status': consentStatus.name,
        'consent_reason': consentReason,
        'approval_status': approvalStatus.name,
        'approved_by': approvedBy,
        'approved_at': approvedAt?.toIso8601String(),
        'rejection_reason': rejectionReason,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

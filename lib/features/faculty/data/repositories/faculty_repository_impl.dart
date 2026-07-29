import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/repositories/faculty_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/paginated_response.dart';

import '../../../audit/domain/entities/audit_log_entry.dart';
import '../../../audit/domain/repositories/audit_log_repository.dart';

class FacultyRepositoryImpl implements FacultyRepository {
  final SupabaseClient _supabase;
  final AuditLogRepository _auditLogRepo;

  FacultyRepositoryImpl(this._supabase, this._auditLogRepo);

  @override
  Future<({PaginatedResponse<UserProfile>? data, Failure? failure})> getDepartmentStudents({
    required String department,
    required int page,
    required int limit,
  }) async {
    // Mock implementation for UI wiring
    return (data: PaginatedResponse<UserProfile>(items: [], totalCount: 0), failure: null);
  }

  @override
  Future<List<UserProfile>> getPendingStudents({required String department}) async {
    // Returning mock data so the UI can be tested without needing a populated Supabase database
    return [
      UserProfile(
        id: 'mock-1',
        role: UserRole.student,
        name: 'John Doe',
        email: 'johndoe@student.com',
        usn: '4MC23IS001',
        department: department,
        cgpa: 8.5,
        approvalStatus: ApprovalStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      UserProfile(
        id: 'mock-2',
        role: UserRole.student,
        name: 'Jane Smith',
        email: 'janesmith@student.com',
        usn: '4MC23IS002',
        department: department,
        cgpa: 9.2,
        approvalStatus: ApprovalStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<void> reviewStudentApproval({
    required String studentId,
    required ApprovalStatus status,
    required String approvedBy,
    String? rejectionReason,
  }) async {
    await _supabase.from('profiles').update({
      'approval_status': status.name,
      'approved_by': status == ApprovalStatus.approved ? approvedBy : null,
      'approved_at': status == ApprovalStatus.approved ? DateTime.now().toIso8601String() : null,
      'rejection_reason': rejectionReason,
    }).eq('id', studentId);
    
    await _auditLogRepo.logAction(
      action: status == ApprovalStatus.approved ? AuditAction.verification : AuditAction.rejection,
      description: status == ApprovalStatus.approved 
          ? 'Verified student profile ($studentId).'
          : 'Rejected student profile ($studentId). Reason: $rejectionReason',
      targetId: studentId,
      targetTable: 'profiles',
    );
  }

  @override
  Future<Map<String, dynamic>> getDepartmentPlacementStats({required String department}) async {
    final response = await _supabase
        .from('department_placement_stats')
        .select('*')
        .eq('department', department)
        .maybeSingle();

    return response ?? {
      'department': department,
      'total_students': 0,
      'total_placed': 0,
      'total_attended_any_drive': 0,
    };
  }

  @override
  Future<void> submitInterviewFeedback({
    required String applicationId,
    required String roundId,
    required String facultyId,
    required int rating,
    required String remarks,
    required bool recommend,
  }) async {
    await _supabase.from('interview_feedback').insert({
      'application_id': applicationId,
      'round_id': roundId,
      'faculty_id': facultyId,
      'rating': rating,
      'remarks': remarks,
      'recommend': recommend,
    });
  }
}
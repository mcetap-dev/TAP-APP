import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/repositories/faculty_repository.dart';

class FacultyRepositoryImpl implements FacultyRepository {
  final SupabaseClient _supabase;

  FacultyRepositoryImpl(this._supabase);

  @override
  Future<List<UserProfile>> getPendingStudents({required String department}) async {
    final response = await _supabase
        .from('profiles')
        .select('*')
        .eq('role', 'student')
        .eq('department', department)
        .eq('approval_status', 'pending');

    return (response as List).map((map) => UserProfile.fromMap(map)).toList();
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
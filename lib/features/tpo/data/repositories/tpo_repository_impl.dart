import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/domain/entities/company.dart';
import '../../../student/domain/entities/drive.dart';
import '../../../student/domain/entities/application.dart';
import '../../domain/repositories/tpo_repository.dart';

import '../../../audit/domain/entities/audit_log_entry.dart';
import '../../../audit/domain/repositories/audit_log_repository.dart';

class TpoRepositoryImpl implements TpoRepository {
  final SupabaseClient _supabase;
  final AuditLogRepository _auditLogRepo;

  TpoRepositoryImpl(this._supabase, this._auditLogRepo);

  @override
  Future<void> appointFacultyCoordinator({
    required String profileId,
    required String department,
    required String appointedBy,
  }) async {
    // Check existing coordinator to prevent duplicate department appointment
    final existing = await _supabase
        .from('faculty_coordinators')
        .select('id')
        .eq('department', department)
        .maybeSingle();

    if (existing != null) {
      await _supabase.from('faculty_coordinators').update({
        'profile_id': profileId,
        'appointed_by': appointedBy,
      }).eq('department', department);
    } else {
      await _supabase.from('faculty_coordinators').insert({
        'profile_id': profileId,
        'department': department,
        'appointed_by': appointedBy,
      });
    }

    // Update role on profile
    await _supabase
        .from('profiles')
        .update({'role': 'faculty_coordinator'}).eq('id', profileId);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchFacultyCoordinators() async {
    final response = await _supabase
        .from('faculty_coordinators')
        .select('*, profile:profiles!faculty_coordinators_profile_id_fkey(name, email, phone)');
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> createCompany({
    required String name,
    String? industry,
    String? hrContactName,
    String? hrContactEmail,
    String? hrContactPhone,
    required String createdBy,
  }) async {
    await _supabase.from('companies').insert({
      'name': name,
      'industry': industry,
      'hr_contact_name': hrContactName,
      'hr_contact_email': hrContactEmail,
      'hr_contact_phone': hrContactPhone,
      'created_by': createdBy,
    });
  }

  @override
  Future<List<Company>> getCompanies() async {
    final response = await _supabase.from('companies').select('*');
    return (response as List).map((map) => Company.fromMap(map)).toList();
  }

  @override
  Future<void> createDrive({
    required String companyId,
    required String roleTitle,
    String? ctcOrStipend,
    String? jobDescription,
    List<String>? eligibilityBranches,
    double? cgpaCutoff,
    int? backlogLimit,
    required String status,
    required String createdBy,
  }) async {
    final response = await _supabase.from('drives').insert({
      'company_id': companyId,
      'role_title': roleTitle,
      'ctc_or_stipend': ctcOrStipend,
      'job_description': jobDescription,
      'eligibility_branches': eligibilityBranches ?? [],
      'cgpa_cutoff': cgpaCutoff,
      'backlog_limit': backlogLimit ?? 0,
      'status': status,
      'created_by': createdBy,
    }).select('id').single();
    
    await _auditLogRepo.logAction(
      action: AuditAction.driveCreated,
      description: 'Created new placement drive: $roleTitle',
      targetId: response['id'] as String?,
      targetTable: 'drives',
    );
  }

  @override
  Future<List<Drive>> getDrives() async {
    final response = await _supabase
        .from('drives')
        .select('*, company:companies(name)');
    return (response as List).map((map) => Drive.fromMap(map)).toList();
  }

  @override
  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async {
    await _supabase
        .from('applications')
        .update({'status': status.name}).eq('id', applicationId);
  }

  @override
  Future<void> bulkUpdateShortlist({
    required String driveId,
    required List<String> studentIds,
    required ApplicationStatus status,
  }) async {
    for (final studentId in studentIds) {
      await _supabase
          .from('applications')
          .update({'status': status.name})
          .eq('drive_id', driveId)
          .eq('student_id', studentId);
    }
  }

  @override
  Future<void> uploadOffer({
    required String applicationId,
    required double ctc,
    required String offerLetterUrl,
    required DateTime joiningDate,
  }) async {
    await _supabase.from('offers').insert({
      'application_id': applicationId,
      'ctc_offered': ctc,
      'offer_letter_url': offerLetterUrl,
      'joining_date': joiningDate.toIso8601String(),
      'status': 'offered',
    });
    await _supabase
        .from('applications')
        .update({'status': 'selected'}).eq('id', applicationId);
  }
}
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
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    // Check if company already exists to avoid duplicate inserts
    final existing = await _supabase
        .from('companies')
        .select('id')
        .ilike('name', cleanName)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('companies').insert({
        'name': cleanName,
        if (industry != null) 'industry': industry,
        if (hrContactName != null) 'hr_contact_name': hrContactName,
        if (hrContactEmail != null) 'hr_contact_email': hrContactEmail,
        if (hrContactPhone != null) 'hr_contact_phone': hrContactPhone,
      });
    }
  }

  @override
  Future<void> updateCompany({
    required String companyId,
    required String name,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty || companyId.isEmpty) return;
    await _supabase
        .from('companies')
        .update({'name': cleanName})
        .eq('id', companyId);
  }

  @override
  Future<List<Company>> getCompanies() async {
    final response = await _supabase.from('companies').select('*');
    return (response as List).map((map) => Company.fromMap(map)).toList();
  }

  final List<Drive> _localDriveCache = [];

  @override
  Future<void> createDrive({
    required String companyId,
    required String roleTitle,
    String? ctcOrStipend,
    String? jobDescription,
    List<String>? eligibilityBranches,
    double? cgpaCutoff,
    int? backlogLimit,
    DateTime? applicationDeadline,
    required String status,
    required String createdBy,
  }) async {
    // Parse numerical package if provided (e.g. "20LPA" or "12" -> 20.0 or 12.0)
    double? packageLpa;
    if (ctcOrStipend != null && ctcOrStipend.isNotEmpty) {
      final numericStr = ctcOrStipend.replaceAll(RegExp(r'[^0-9.]'), '');
      packageLpa = double.tryParse(numericStr);
    }

    final payload = <String, dynamic>{
      'company_id': companyId.isNotEmpty ? companyId : null,
      'role': roleTitle,
      'role_title': roleTitle,
      'description': jobDescription,
      if (packageLpa != null) 'package_lpa': packageLpa,
      'eligibility_cgpa': cgpaCutoff ?? 0.0,
      'eligibility_branches': eligibilityBranches ?? [],
      'backlog_limit': backlogLimit ?? 0,
      if (applicationDeadline != null) 'end_date': applicationDeadline.toIso8601String(),
      'status': status == 'active' ? 'upcoming' : status,
    };

    // ignore: avoid_print
    print('🚀 [TpoRepository] Submitting drive insert payload to Supabase: $payload');

    try {
      final response = await _supabase
          .from('drives')
          .insert(payload)
          .select('*, company:companies(*)')
          .maybeSingle();

      if (response != null) {
        final drive = Drive.fromMap(response);
        _localDriveCache.removeWhere((d) => d.id == drive.id);
        _localDriveCache.insert(0, drive);

        try {
          await _auditLogRepo.logAction(
            action: AuditAction.driveCreated,
            description: 'Created new placement drive: $roleTitle',
            targetId: drive.id,
            targetTable: 'drives',
          );
        } catch (_) {}
      }
    } catch (e, stack) {
      // ignore: avoid_print
      print('❌ [TpoRepository] Supabase insert error: $e\n$stack');
      rethrow;
    }
  }

  @override
  Future<void> updateDriveStatus({
    required String driveId,
    required String status,
  }) async {
    final validStatus = status.toLowerCase() == 'ongoing'
        ? 'active'
        : (status.toLowerCase() == 'closed' ? 'completed' : status.toLowerCase());

    // 1. Update in local memory cache immediately
    final index = _localDriveCache.indexWhere((d) => d.id == driveId);
    if (index != -1) {
      final old = _localDriveCache[index];
      _localDriveCache[index] = Drive(
        id: old.id,
        companyId: old.companyId,
        companyName: old.companyName,
        roleTitle: old.roleTitle,
        ctcOrStipend: old.ctcOrStipend,
        jobDescription: old.jobDescription,
        eligibilityBranches: old.eligibilityBranches,
        cgpaCutoff: old.cgpaCutoff,
        backlogLimit: old.backlogLimit,
        applicationDeadline: old.applicationDeadline,
        status: validStatus,
      );
    }

    // 2. Persist to Supabase database
    try {
      // ignore: avoid_print
      print('🚀 [TpoRepository] Updating Supabase drive $driveId status -> $validStatus');
      
      await _supabase
          .from('drives')
          .update({'status': validStatus})
          .eq('id', driveId);
          
      // ignore: avoid_print
      print('✅ [TpoRepository] Supabase update successful for status: $validStatus');
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [TpoRepository] First update attempt failed: $e. Retrying with fallback status...');
      try {
        // Fallback for custom DB enums where 'active' is named 'ongoing'
        final fallbackStatus = validStatus == 'active' ? 'ongoing' : (validStatus == 'completed' ? 'closed' : validStatus);
        await _supabase
            .from('drives')
            .update({'status': fallbackStatus})
            .eq('id', driveId);
            
      } catch (err) {
        // ignore: avoid_print
        print('❌ [TpoRepository] Supabase drive status update completely failed: $err');
      }
    }
  }

  @override
  Future<void> updateDrive({
    required String driveId,
    String? companyId,
    required String roleTitle,
    String? ctcOrStipend,
    String? jobDescription,
    List<String>? eligibilityBranches,
    double? cgpaCutoff,
    int? backlogLimit,
    DateTime? applicationDeadline,
  }) async {
    double? packageLpa;
    if (ctcOrStipend != null && ctcOrStipend.isNotEmpty) {
      final numericStr = ctcOrStipend.replaceAll(RegExp(r'[^0-9.]'), '');
      packageLpa = double.tryParse(numericStr);
    }

    final payload = <String, dynamic>{
      if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
      'role': roleTitle,
      'role_title': roleTitle,
      if (jobDescription != null) 'description': jobDescription,
      if (packageLpa != null) 'package_lpa': packageLpa,
      if (cgpaCutoff != null) 'eligibility_cgpa': cgpaCutoff,
      if (eligibilityBranches != null) 'eligibility_branches': eligibilityBranches,
      if (backlogLimit != null) 'backlog_limit': backlogLimit,
      if (applicationDeadline != null) 'end_date': applicationDeadline.toIso8601String(),
    };

    // ignore: avoid_print
    print('🚀 [TpoRepository] Updating drive $driveId in Supabase: $payload');

    final response = await _supabase
        .from('drives')
        .update(payload)
        .eq('id', driveId)
        .select('*, company:companies(*)')
        .maybeSingle();

    if (response != null) {
      final updatedDrive = Drive.fromMap(response);
      final idx = _localDriveCache.indexWhere((d) => d.id == driveId);
      if (idx != -1) {
        _localDriveCache[idx] = updatedDrive;
      }
    }
  }

  @override
  Future<List<Drive>> getDrives() async {
    try {
      final response = await _supabase
          .from('drives')
          .select('*, company:companies(*)')
          .order('created_at', ascending: false);
      return (response as List).map((map) => Drive.fromMap(map)).toList();
    } catch (e) {
      return _localDriveCache;
    }
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

  @override
  Future<List<Map<String, dynamic>>> fetchDriveAttendance(String driveId) async {
    final response = await _supabase
        .from('drive_attendance')
        .select('*, profile:profiles!drive_attendance_student_id_fkey(name, email, usn, department)')
        .eq('drive_id', driveId)
        .order('scanned_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
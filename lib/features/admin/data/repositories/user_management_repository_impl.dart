import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/repositories/user_management_repository.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  final SupabaseClient _supabase;

  UserManagementRepositoryImpl(this._supabase);

  @override
  Future<void> appointTpo({
    required String profileId,
    required String appointedBy,
  }) async {
    await _supabase.from('tpo_appointments').insert({
      'profile_id': profileId,
      'appointed_by': appointedBy,
    });
    await _supabase
        .from('profiles')
        .update({'role': 'tpo'}).eq('id', profileId);
  }

  @override
  Future<List<UserProfile>> getTpoList() async {
    final response = await _supabase
        .from('tpo_appointments')
        .select('*, profile:profiles(*)');

    return (response as List)
        .map((map) => UserProfile.fromMap(map['profile']))
        .toList();
  }

  @override
  Future<void> createAcademicCycle({
    required String academicYear,
    required String eligibleBatch,
    required List<String> branches,
    required String createdBy,
  }) async {
    await _supabase.from('academic_cycles').insert({
      'academic_year': academicYear,
      'eligible_batch': eligibleBatch,
      'branches': branches,
      'created_by': createdBy,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getAcademicCycles() async {
    final response = await _supabase.from('academic_cycles').select('*');
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getNaacInstitutionReport() async {
    final response = await _supabase
        .from('department_placement_stats')
        .select('*');
    return List<Map<String, dynamic>>.from(response);
  }
}
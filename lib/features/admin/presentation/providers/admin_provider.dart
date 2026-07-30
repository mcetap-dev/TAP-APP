import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/user_management_repository_impl.dart';
import '../../domain/repositories/user_management_repository.dart';
import '../../../audit/domain/repositories/audit_log_repository.dart';

final userManagementRepositoryProvider = Provider<UserManagementRepository>((ref) {
  return UserManagementRepositoryImpl(
    Supabase.instance.client,
    ref.watch(auditLogRepositoryProvider),
  );
});

/// Fetches all faculty/staff profiles (non-student, non-tpo, non-admin)
/// so the admin can pick one from a dropdown when appointing a TPO.
final facultyListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await Supabase.instance.client
      .from('profiles')
      .select('id, name, email, department, role')
      .inFilter('role', ['faculty', 'faculty_coordinator'])
      .order('name', ascending: true);
  return List<Map<String, dynamic>>.from(response);
});

/// Fetches real-time counts from Supabase for Users, Companies, and Audit Logs.
final adminStatsProvider = FutureProvider<({int userCount, int companyCount, int auditLogCount})>((ref) async {
  final client = Supabase.instance.client;

  final usersRes = await client.from('profiles').select('id');
  final companiesRes = await client.from('companies').select('id');
  final auditRes = await client.from('audit_logs').select('id');

  return (
    userCount: (usersRes as List).length,
    companyCount: (companiesRes as List).length,
    auditLogCount: (auditRes as List).length,
  );
});


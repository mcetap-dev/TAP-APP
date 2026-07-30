import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/faculty_repository_impl.dart';
import '../../domain/repositories/faculty_repository.dart';
import '../../../audit/domain/repositories/audit_log_repository.dart';

final facultyRepositoryProvider = Provider<FacultyRepository>((ref) {
  final auditRepo = ref.watch(auditLogRepositoryProvider);
  return FacultyRepositoryImpl(Supabase.instance.client, auditRepo);
});

final pendingStudentsProvider = FutureProvider<List<UserProfile>>((ref) async {
  final userProfile = ref.watch(authNotifierProvider).value;
  final department = userProfile?.department ?? '';
  if (department.isEmpty) return [];

  final repo = ref.watch(facultyRepositoryProvider);
  return repo.getPendingStudents(department: department);
});

final deptPlacementStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userProfile = ref.watch(authNotifierProvider).value;
  final department = userProfile?.department ?? '';
  if (department.isEmpty) return {'total_students': 0, 'total_placed': 0};

  final repo = ref.watch(facultyRepositoryProvider);
  return repo.getDepartmentPlacementStats(department: department);
});
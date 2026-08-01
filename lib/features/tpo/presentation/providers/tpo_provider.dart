import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/domain/entities/company.dart';
import '../../../student/domain/entities/drive.dart';
import '../../data/repositories/tpo_repository_impl.dart';
import '../../domain/repositories/tpo_repository.dart';
import '../../../audit/domain/repositories/audit_log_repository.dart';

final tpoRepositoryProvider = Provider<TpoRepository>((ref) {
  final auditRepo = ref.watch(auditLogRepositoryProvider);
  return TpoRepositoryImpl(Supabase.instance.client, auditRepo);
});

final tpoDrivesProvider = FutureProvider<List<Drive>>((ref) async {
  final timer = Stream.periodic(const Duration(milliseconds: 1500)).listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final repo = ref.watch(tpoRepositoryProvider);
  return repo.getDrives();
});

final tpoCompaniesProvider = FutureProvider<List<Company>>((ref) async {
  final timer = Stream.periodic(const Duration(milliseconds: 2000)).listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final repo = ref.watch(tpoRepositoryProvider);
  return repo.getCompanies();
});

final facultyCoordinatorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final timer = Stream.periodic(const Duration(milliseconds: 1500)).listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final repo = ref.watch(tpoRepositoryProvider);
  return repo.fetchFacultyCoordinators();
});

final driveAttendanceProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, driveId) async {
  final timer = Stream.periodic(const Duration(seconds: 3)).listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final repo = ref.watch(tpoRepositoryProvider);
  return repo.fetchDriveAttendance(driveId);
});
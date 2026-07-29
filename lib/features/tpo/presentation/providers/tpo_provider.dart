import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/domain/entities/company.dart';
import '../../../student/domain/entities/drive.dart';
import '../../data/repositories/tpo_repository_impl.dart';
import '../../domain/repositories/tpo_repository.dart';

final tpoRepositoryProvider = Provider<TpoRepository>((ref) {
  return TpoRepositoryImpl(Supabase.instance.client);
});

final tpoDrivesProvider = FutureProvider<List<Drive>>((ref) async {
  final repo = ref.watch(tpoRepositoryProvider);
  return repo.getDrives();
});

final tpoCompaniesProvider = FutureProvider<List<Company>>((ref) async {
  final repo = ref.watch(tpoRepositoryProvider);
  return repo.getCompanies();
});

final facultyCoordinatorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(tpoRepositoryProvider);
  return repo.fetchFacultyCoordinators();
});
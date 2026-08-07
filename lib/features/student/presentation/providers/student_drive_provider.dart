import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/drive.dart';
import '../../domain/entities/application.dart';
import '../../data/repositories/student_drive_repository_impl.dart';
import '../../data/datasources/student_drive_remote_datasource.dart';

final studentDriveRepositoryProvider = Provider((ref) {
  final dataSource = StudentDriveRemoteDataSourceImpl(Supabase.instance.client);
  return StudentDriveRepositoryImpl(remoteDataSource: dataSource);
});

final studentEligibleDrivesProvider = FutureProvider<List<Drive>>((ref) async {
  final timer = Stream.periodic(const Duration(milliseconds: 1500)).listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final repo = ref.watch(studentDriveRepositoryProvider);
  return repo.getEligibleDrives();
});

final studentApplicationsProvider = FutureProvider<List<Application>>((ref) async {
  final timer = Stream.periodic(const Duration(milliseconds: 1500)).listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  final response = await Supabase.instance.client
      .from('applications')
      .select('*, drive:drives(*, company:companies(*))')
      .eq('student_id', user.id);

  return (response as List).map((map) => Application.fromMap(map)).toList();
});

/// Set of drive IDs the current student has applied to.
/// Source of truth: Supabase `applications` table.
/// Uses Realtime subscription so the UI updates instantly on apply/withdraw.
final studentAppliedDriveIdsProvider = Provider<Set<String>>((ref) {
  final appsAsync = ref.watch(studentApplicationsProvider);
  return appsAsync.valueOrNull?.map((app) => app.driveId).toSet() ?? const {};
});

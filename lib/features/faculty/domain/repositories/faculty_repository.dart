import '../../../../core/errors/failures.dart';
import '../../../../shared/models/paginated_response.dart';
import '../../../auth/domain/entities/user_profile.dart';

abstract class FacultyRepository {
  /// Fetches students that belong to the same department as the faculty member
  Future<({PaginatedResponse<UserProfile>? data, Failure? failure})> getDepartmentStudents({
    required String department,
    required int page,
    required int limit,
  });
}
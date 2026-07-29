import '../../../../shared/domain/entities/company.dart';
import '../../../student/domain/entities/drive.dart';
import '../../../student/domain/entities/application.dart';

abstract class TpoRepository {
  Future<void> appointFacultyCoordinator({
    required String profileId,
    required String department,
    required String appointedBy,
  });

  Future<List<Map<String, dynamic>>> fetchFacultyCoordinators();

  Future<void> createCompany({
    required String name,
    String? industry,
    String? hrContactName,
    String? hrContactEmail,
    String? hrContactPhone,
    required String createdBy,
  });

  Future<List<Company>> getCompanies();

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
  });

  Future<List<Drive>> getDrives();

  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  });

  Future<void> bulkUpdateShortlist({
    required String driveId,
    required List<String> studentIds,
    required ApplicationStatus status,
  });

  Future<void> uploadOffer({
    required String applicationId,
    required double ctc,
    required String offerLetterUrl,
    required DateTime joiningDate,
  });
}
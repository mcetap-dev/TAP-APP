import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user_profile.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

@freezed
class UserProfileModel with _$UserProfileModel {
  const UserProfileModel._();

  const factory UserProfileModel({
    required String id,
    required String email,
    required UserRole role,
    required String full_name,
    String? department,
    double? cgpa, // ADDED
    String? avatar_url,
    @JsonKey(name: 'is_email_verified') required bool isEmailVerified,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  UserProfile toDomain() {
    return UserProfile(
      id: id,
      email: email,
      role: role,
      fullName: full_name,
      department: department,
      cgpa: cgpa,
      avatarUrl: avatar_url,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.role,
    super.profileImage,
    super.mobileNumber,
    super.enrolledCourseIds,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'student',
      profileImage: json['profileImage'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      enrolledCourseIds:
          (json['enrolledCourseIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'profileImage': profileImage,
      'mobileNumber': mobileNumber,
      'enrolledCourseIds': enrolledCourseIds,
    };
  }
}

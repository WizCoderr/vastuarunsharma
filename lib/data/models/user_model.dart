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
    String asString(dynamic value, [String fallback = '']) {
      if (value == null) return fallback;
      final text = value.toString().trim();
      return text.isEmpty ? fallback : text;
    }

    List<String> asStringList(dynamic value) {
      if (value is! List) return const [];
      return value.map((e) => e.toString()).toList();
    }

    return UserModel(
      id: asString(json['id'] ?? json['_id']),
      email: asString(json['email']),
      name: asString(json['name'], 'Student'),
      role: asString(json['role'], 'student'),
      profileImage: json['profileImage'] as String?,
      mobileNumber: () {
        final phone = asString(json['phoneNumber'] ?? json['mobileNumber']);
        return phone.isEmpty ? null : phone;
      }(),
      enrolledCourseIds: asStringList(json['enrolledCourseIds']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'profileImage': profileImage,
      'phoneNumber': mobileNumber,
      'enrolledCourseIds': enrolledCourseIds,
    };
  }
}

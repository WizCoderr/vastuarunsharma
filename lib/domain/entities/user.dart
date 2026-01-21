class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? profileImage;
  final String? mobileNumber;
  final List<String> enrolledCourseIds;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'student',
    this.profileImage,
    this.mobileNumber,
    this.enrolledCourseIds = const [],
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  bool isEnrolled(String courseId) => enrolledCourseIds.contains(courseId);
}

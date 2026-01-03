class ApiEndpoints {
  static const String baseUrl = "https://api.vastuarunsharma.com";
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/api/student/logout';
  //Public API
  static const String publicCourses = '/api/public/courses';
    static String publiccourseDetails(String id) => '/api/public/courses/$id';

  // Courses (Student)
  static const String courses = '/api/student/courses';
  static const String enrolledCourses = '/api/student/enrolled-courses';
  static String courseDetails(String id) => '/api/student/courses/$id';
  static String courseCurriculum(String id) =>
      '/api/student/courses/$id/curriculum';

  // Progress
  static const String updateProgress = '/api/student/progress/update';

  // Lectures
  static String lectureStreamUrl(String lectureId) =>'/api/student/lectures/$lectureId/stream-url';

  // Payments 
  static const String createrazorpayorder ='/api/payments/razorpay/order';
  static const String verifyPayment ='/api/payments/razorpay/verify';
}

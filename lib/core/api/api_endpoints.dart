class ApiEndpoints {
  static const String baseUrl = "https://api.vastuarunsharma.com";
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/api/student/logout';
  static const String profile = '/api/student/profile';
  //Public API
  static const String publicCourses = '/api/public/courses';
  static String publiccourseDetails(String id) => '/api/public/courses/$id';

  // Courses (Student)
  static const String courses = '/api/student/courses';
  static const String enrolledCourses = '/api/student/enrolled-courses';
  static String courseDetails(String id) => '/api/student/courses/$id';
  static String courseCurriculum(String id) =>
      '/api/student/courses/$id/curriculum';

  // Live Classes
  static const String todayLiveClasses = '/api/student/live-classes/today';
  static const String upcomingLiveClasses =
      '/api/student/live-classes/upcoming';
  static String courseRecordings(String courseId) =>
      '/api/student/course/$courseId/recordings';

  // Notifications
  static const String deviceToken = '/api/student/device-token';

  // Progress
  static const String updateProgress = '/api/student/progress/update';

  // Lectures
  static String lectureStreamUrl(String lectureId) =>
      '/api/student/lectures/$lectureId/stream-url';

  // Payments
  static String coursePaymentPlan(String courseId) =>
      '/api/payments/course/$courseId/plan';
  static const String courseOrder = '/api/payments/course/order';
  static const String courseVerify = '/api/payments/course/verify';
  static String studentCoursePayments(String courseId) =>
      '/api/payments/course/$courseId/my-payments';
  static String payInstallment(String paymentId) =>
      '/api/payments/course/installment/$paymentId/pay';
  static String enrollInCourse(String courseId) =>
      '/api/payments/course/$courseId/enroll';
  static const String remediesOrder = '/api/payments/remidies/order';
  static const String remediesVerify = '/api/payments/remidies/verify';
  static const String freeEnroll = '/api/payments/free-enroll';

  // Remidies (Vastu Store)
  static const String remidiesCategories = '/api/student/remidies/categories';
  static const String remidiesProducts = '/api/student/remidies/products';
  static const String remidiesCart = '/api/student/remidies/cart';
  static const String remidiesOrders = '/api/student/remidies/orders';
  static String remidiesCartItem(String productId) =>
      '/api/student/remidies/cart/$productId';
}

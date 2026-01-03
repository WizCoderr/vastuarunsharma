class RouteConstants {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String dashboard = '/dashboard';
  static const String login = '/login';
  static const String register = '/register';
  static const String courses = '/courses';
  static const String myCourses = '/my-courses';
  static const String profile = '/profile';
  static const String stats = '/stats';
  static const String payment = 'payment';

  // Routes with parameters
  static const String courseDetails = 'course-details';
  static const String enrollment = 'enrollment';
  static const String videoPlayer = 'video-player';

  // Full paths for internal navigation
  static String courseDetailsPath(String id) => '/course/$id';
  static String enrollmentPath(String id) => '/enrollment/$id';
  static String videoPlayerPath(String id) => '/video/$id';
  static String paymentPath(String id) => '/payment/$id';
}

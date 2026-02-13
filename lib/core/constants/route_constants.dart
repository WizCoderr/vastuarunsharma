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
  static const String compass = '/compass';
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
  static const String compassResult = '/compass-result';
  static const String compassNormal = '/compass/normal';
  static const String compassSixteen = '/compass/16-zone';
  static const String compassThirtyTwo = '/compass/32-zone';
  static const String compassChakra = '/compass/advancedvastucakra';
  static const String compassVastu = '/compass/vastu';
}

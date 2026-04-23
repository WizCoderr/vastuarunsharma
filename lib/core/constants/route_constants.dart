class RouteConstants {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String dashboard = '/dashboard';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String courses = '/courses';
  static const String myCourses = '/my-courses';
  static const String profile = '/profile';
  static const String stats = '/stats';
  static const String compass = '/compass';
  static const String remidies = '/remidies';
  static const String payment = 'payment';
  static const String checkoutPath = '/checkout';
  static const String remediesPaymentPath = '/remedies-payment';
  static const String ordersPath = '/remidies/orders';

  // Routes with parameters
  static const String courseDetails = 'course-details';
  static const String enrollment = 'enrollment';
  static const String videoPlayer = 'video-player';
  static const String paymentProgress = 'payment-progress';

  // Full paths for internal navigation
  static String courseDetailsPath(String id) => '/course/$id';
  static String enrollmentPath(String id) => '/enrollment/$id';
  static String videoPlayerPath(String id, {String? lectureId, String? recordingId}) {
    final path = '/video/$id';
    final queryParams = <String, String>{};
    if (lectureId != null) queryParams['lectureId'] = lectureId;
    if (recordingId != null) queryParams['recordingId'] = recordingId;

    if (queryParams.isEmpty) return path;

    return Uri(path: path, queryParameters: queryParams).toString();
  }
  static String paymentPath(String id) => '/payment/$id';
  static String paymentProgressPath(String id) => '/payment-progress/$id';
  static String resetPasswordPath({String? token}) {
    if (token == null || token.trim().isEmpty) {
      return resetPassword;
    }

    return Uri(
      path: resetPassword,
      queryParameters: {'token': token.trim()},
    ).toString();
  }

  static const String compassResult = '/compass-result';
  static const String compassNormal = '/compass/normal';
  static const String compassSixteen = '/compass/16-zone';
  static const String compassThirtyTwo = '/compass/32-zone';
  static const String compassChakra = '/compass/advancedvastucakra';
  static const String compassVastu = '/compass/vastu';

  // Admin Remidies
  static const String adminRemidiesCoupons = '/admin/remidies/coupons';
  static const String adminRemidiesBulkTiers = '/admin/remidies/bulk-tiers';
}

// Helper utility for logging
// This is implied by the core/utils/logger.dart in requirements list but wasn't critical
// Creating a simple implementaton to ensure full requirement coverage

import 'package:flutter/foundation.dart';

class Logger {
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[DEBUG] $message');
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('Stack: $stackTrace');
    }
  }

  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('Stack: $stackTrace');
    }
  }
}

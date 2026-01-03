import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/errors/exceptions.dart';

class StorageService {
  final SharedPreferences _prefs;

  // Public constructor
  StorageService(this._prefs);

  // Private named constructor
  StorageService._(this._prefs);

  static Future<StorageService> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  Future<void> saveAuthToken(String token) async {
    final ok = await _prefs.setString('auth_token', token);
    if (!ok) throw StorageException('Failed to save auth token');
  }

  String? getAuthToken() => _prefs.getString('auth_token');

  Future<void> clearAuth() async {
    await _prefs.remove('auth_token');
    await _prefs.remove('user_data');
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final ok = await _prefs.setString('user_data', jsonEncode(user));
    if (!ok) throw StorageException('Failed to save user');
  }

  Map<String, dynamic>? getUser() {
    final s = _prefs.getString('user_data');
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  Future<void> saveEnrolledCourses(List<String> ids) async {
    final ok = await _prefs.setStringList('enrolled_courses', ids);
    if (!ok) throw StorageException('Failed to save enrolled courses');
  }

  List<String> getEnrolledCourses() =>
      _prefs.getStringList('enrolled_courses') ?? [];

  Future<void> saveVideoProgress(String courseId, int seconds) async {
    final ok = await _prefs.setInt('video_progress_$courseId', seconds);
    if (!ok) throw StorageException('Failed to save video progress');
  }

  int getVideoProgress(String courseId) =>
      _prefs.getInt('video_progress_$courseId') ?? 0;
}

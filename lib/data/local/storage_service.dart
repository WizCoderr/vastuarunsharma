import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../../domain/entities/user.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _onboardingKey = 'has_seen_onboarding';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Auth Token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<void> deleteToken() async {
    await _prefs.remove(_tokenKey);
  }

  bool get hasToken => _prefs.containsKey(_tokenKey);

  // User Data
  Future<void> saveUser(UserModel user) async {
    try {
      final String userJson = jsonEncode(user.toJson());
      await _prefs.setString(_userKey, userJson);
    } catch (e) {
      throw CacheException('Failed to save user data');
    }
  }

  User? getUser() {
    try {
      final String? userJson = _prefs.getString(_userKey);
      if (userJson == null) {
        print('StorageService: No user data found in storage');
        return null;
      }
      print('StorageService: Found user data: $userJson');

      final Map<String, dynamic> map = jsonDecode(userJson);
      final user = UserModel.fromJson(map);
      print('StorageService: Successfully parsed user: ${user.email}');
      return user;
    } catch (e, st) {
      print('StorageService: Failed to parse user data: $e');
      print(st);
      return null;
    }
  }

  Future<void> deleteUser() async {
    await _prefs.remove(_userKey);
  }

  // Onboarding/Landing
  Future<void> setHasSeenLanding() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  bool get hasSeenLanding => _prefs.getBool(_onboardingKey) ?? false;

  // Clear all auth related data
  Future<void> clearAuth() async {
    await Future.wait([deleteToken(), deleteUser()]);
  }
}

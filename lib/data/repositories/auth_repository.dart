import '../local/storage_service.dart';
import '../models/user_model.dart';

import '../datasources/remote/auth_remote_datasource.dart';

class AuthRepository {
  final StorageService _storageService;
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepository(this._storageService, this._remoteDataSource);

  //  Login
  Future<UserModel> login(
    String email,
    String password, [
    String? mobileNumber,
  ]) async {
    final response = await _remoteDataSource.login(
      email,
      password,
      mobileNumber,
    );

    // Persist
    await _storageService.saveToken(response.token);
    await _storageService.saveUser(response.user);

    return response.user;
  }

  // Register
  Future<UserModel> register(
    String email,
    String password,
    String name,
    String mobileNumber,
  ) async {
    final response = await _remoteDataSource.register(
      email,
      password,
      name,
      mobileNumber,
    );

    // Persist
    await _storageService.saveToken(response.token);
    await _storageService.saveUser(response.user);

    return response.user;
  }

  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Ignore remote logout failure, ensure local cleanup happens
    }
    await _storageService.clearAuth();
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final updatedUser = await _remoteDataSource.updateProfile(data);
    await _storageService.saveUser(updatedUser);
    return updatedUser;
  }

  Future<bool> checkAuthStatus() async {
    return _storageService.hasToken;
  }

  UserModel? getCurrentUser() {
    return _storageService.getUser() as UserModel?;
  }
}

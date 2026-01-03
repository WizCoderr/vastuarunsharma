import '../local/storage_service.dart';
import '../models/user_model.dart';

import '../datasources/remote/auth_remote_datasource.dart';

class AuthRepository {
  final StorageService _storageService;
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepository(this._storageService, this._remoteDataSource);

  //  Login
  Future<UserModel> login(String email, String password) async {
    final response = await _remoteDataSource.login(email, password);

    // Persist
    await _storageService.saveToken(response.token);
    await _storageService.saveUser(response.user);

    return response.user;
  }

  // Register
  Future<UserModel> register(String email, String password, String name) async {
    final response = await _remoteDataSource.register(email, password, name);

    // Persist
    await _storageService.saveToken(response.token);
    await _storageService.saveUser(response.user);

    return response.user;
  }

  Future<void> logout() async {
    await _storageService.clearAuth();
  }

  Future<bool> checkAuthStatus() async {
    return _storageService.hasToken;
  }

  UserModel? getCurrentUser() {
    return _storageService.getUser() as UserModel?;
  }
}

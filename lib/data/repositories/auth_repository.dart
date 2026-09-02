import '../datasources/remote/auth_remote_datasource.dart';
import '../local/storage_service.dart';
import '../../core/errors/exceptions.dart';
import '../models/request/forgot_password_request.dart';
import '../models/request/reset_password_request.dart';
import '../models/request/verify_reset_otp_request.dart';
import '../models/response/auth_action_response.dart';
import '../models/response/verify_reset_otp_response.dart';
import '../models/user_model.dart';

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

  Future<UserModel?> fetchCurrentUser() async {
    final token = _storageService.getToken();
    if (token == null || token.trim().isEmpty) {
      return null;
    }

    try {
      final user = await _remoteDataSource.getCurrentUser(token);
      await _storageService.saveUser(user);
      return user;
    } on AuthException {
      await _storageService.clearAuth();
      return null;
    }
  }

  Future<AuthActionResponse> forgotPassword(ForgotPasswordRequest request) {
    return _remoteDataSource.forgotPassword(request);
  }

  Future<VerifyResetOtpResponse> verifyResetOtp(VerifyResetOtpRequest request) {
    return _remoteDataSource.verifyResetOtp(request);
  }

  Future<AuthActionResponse> resetPassword(ResetPasswordRequest request) {
    return _remoteDataSource.resetPassword(request);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final updatedUser = await _remoteDataSource.updateProfile(data);
    await _storageService.saveUser(updatedUser);
    return updatedUser;
  }

  Future<bool> checkAuthStatus() async {
    if (!_storageService.hasToken) {
      return false;
    }

    final user = await fetchCurrentUser();
    return user != null;
  }

  bool get hasToken => _storageService.hasToken;

  UserModel? getCurrentUser() {
    return _storageService.getUser() as UserModel?;
  }
}

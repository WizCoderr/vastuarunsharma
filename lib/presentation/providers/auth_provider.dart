import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../data/local/storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../domain/entities/user.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/services/notification_service.dart';

// Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // Override in main.dart
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs);
});

final _authDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ),
  );
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => debugPrint(o.toString()),
    ),
  );
  return dio;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(_authDioProvider);
  return AuthRemoteDataSource(dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final remote = ref.watch(authRemoteDataSourceProvider);
  return AuthRepository(storage, remote);
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      final notificationService = ref.watch(notificationServiceProvider);
      return AuthNotifier(repository, notificationService);
    });

// State Notifier
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;
  final NotificationService _notificationService;

  AuthNotifier(this._repository, this._notificationService)
    : super(const AsyncValue.loading()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    debugPrint('AuthNotifier: Initializing...');
    try {
      final isLoggedIn = await _repository.checkAuthStatus();
      debugPrint('AuthNotifier: checkAuthStatus result: $isLoggedIn');

      if (isLoggedIn) {
        final user = _repository.getCurrentUser();

        if (user != null) {
          state = AsyncValue.data(user);
          debugPrint('AuthNotifier: State updated to authenticated user');
          _notificationService.syncToken();
        } else {
          debugPrint(
            'AuthNotifier: User data is null despite token existence. Clearing auth.',
          );
          await _repository.logout();
          state = const AsyncValue.data(null);
        }
      } else {
        debugPrint('AuthNotifier: Not logged in');
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      debugPrint('AuthNotifier: Init failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(email, password);
      state = AsyncValue.data(user);
      await _notificationService.syncToken();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register(
    String email,
    String password,
    String name,
    String mobileNumber,
  ) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.register(
        email,
        password,
        name,
        mobileNumber,
      );
      state = AsyncValue.data(user);
      await _notificationService.syncToken();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _notificationService.removeToken();
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}

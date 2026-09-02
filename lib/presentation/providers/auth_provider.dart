import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../data/local/storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';
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
    : super(_restoreSession(_repository)) {
    if (state.asData?.value != null) {
      _notificationService.syncToken();
    }
    _bootstrapSession();
  }

  static AsyncValue<User?> _restoreSession(AuthRepository repository) {
    try {
      if (!repository.hasToken) {
        return const AsyncValue.data(null);
      }
      final user = repository.getCurrentUser();
      if (user != null) {
        return AsyncValue.data(user);
      }
      // Token is still valid locally; keep the session instead of logging out.
      return AsyncValue.data(
        const UserModel(
          id: 'cached',
          email: '',
          name: 'Student',
        ),
      );
    } catch (e, st) {
      debugPrint('AuthNotifier: Failed to restore session: $e');
      return AsyncValue.error(e, st);
    }
  }

  Future<void> _bootstrapSession() async {
    if (!_repository.hasToken) {
      return;
    }

    try {
      final user = await _repository.fetchCurrentUser();
      if (!mounted) return;

      if (user != null) {
        state = AsyncValue.data(user);
        await _notificationService.syncToken();
      } else if (!_repository.hasToken) {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      debugPrint('AuthNotifier: Session bootstrap failed: $e');
      if (!mounted) return;
      if (!_repository.hasToken) {
        state = const AsyncValue.data(null);
      } else if (state.asData?.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> checkAuthStatus() async {
    debugPrint('AuthNotifier: Initializing...');
    try {
      if (!_repository.hasToken) {
        state = const AsyncValue.data(null);
        return;
      }

      final user = await _repository.fetchCurrentUser();
      if (!mounted) return;

      if (user != null) {
        state = AsyncValue.data(user);
        await _notificationService.syncToken();
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      debugPrint('AuthNotifier: Init failed: $e');
      if (!mounted) return;
      if (!_repository.hasToken) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(e, st);
      }
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

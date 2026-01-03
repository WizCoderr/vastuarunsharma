import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/course_provider.dart';

/// State for a download task
class DownloadState {
  final String lectureId;
  final double progress;
  final bool isDownloading;
  final bool isCompleted;
  final String? error;
  final String? localPath;

  DownloadState({
    required this.lectureId,
    this.progress = 0.0,
    this.isDownloading = false,
    this.isCompleted = false,
    this.error,
    this.localPath,
  });

  DownloadState copyWith({
    String? lectureId,
    double? progress,
    bool? isDownloading,
    bool? isCompleted,
    String? error,
    String? localPath,
  }) {
    return DownloadState(
      lectureId: lectureId ?? this.lectureId,
      progress: progress ?? this.progress,
      isDownloading: isDownloading ?? this.isDownloading,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error,
      localPath: localPath ?? this.localPath,
    );
  }
}

/// Service to handle video caching/downloading
class VideoCacheService {
  final Dio _dio;
  final SharedPreferences _prefs;

  static const String _cacheKeyPrefix = 'video_cache_';
  static const String _cacheDirName = 'video_cache';

  VideoCacheService(this._dio, this._prefs);

  /// Get the cache directory path
  Future<String> get _cacheDirPath async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/$_cacheDirName');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir.path;
  }

  /// Check if a video is cached
  Future<bool> isCached(String lectureId) async {
    final localPath = _prefs.getString('$_cacheKeyPrefix$lectureId');
    if (localPath == null) return false;

    final file = File(localPath);
    return await file.exists();
  }

  /// Get cached video path
  Future<String?> getCachedPath(String lectureId) async {
    final localPath = _prefs.getString('$_cacheKeyPrefix$lectureId');
    if (localPath == null) return null;

    final file = File(localPath);
    if (await file.exists()) {
      return localPath;
    }

    // Cache entry exists but file doesn't - clean up
    await _prefs.remove('$_cacheKeyPrefix$lectureId');
    return null;
  }

  /// Download a video for offline viewing
  Future<DownloadState> downloadVideo(
    String lectureId,
    String videoUrl, {
    Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final cachePath = await _cacheDirPath;
      final fileName = '${lectureId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = '$cachePath/$fileName';

      await _dio.download(
        videoUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress?.call(progress);
          }
        },
      );

      // Save to preferences
      await _prefs.setString('$_cacheKeyPrefix$lectureId', filePath);

      return DownloadState(
        lectureId: lectureId,
        progress: 1.0,
        isDownloading: false,
        isCompleted: true,
        localPath: filePath,
      );
    } catch (e) {
      return DownloadState(
        lectureId: lectureId,
        isDownloading: false,
        isCompleted: false,
        error: e.toString(),
      );
    }
  }

  /// Delete a cached video
  Future<bool> deleteCachedVideo(String lectureId) async {
    final localPath = _prefs.getString('$_cacheKeyPrefix$lectureId');
    if (localPath == null) return true;

    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
      await _prefs.remove('$_cacheKeyPrefix$lectureId');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get total cache size in bytes
  Future<int> getCacheSize() async {
    final cachePath = await _cacheDirPath;
    final cacheDir = Directory(cachePath);

    if (!await cacheDir.exists()) return 0;

    int totalSize = 0;
    await for (final entity in cacheDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }

  /// Clear all cached videos
  Future<void> clearCache() async {
    final cachePath = await _cacheDirPath;
    final cacheDir = Directory(cachePath);

    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }

    // Clear all cache entries from preferences
    final keys = _prefs.getKeys().where((key) => key.startsWith(_cacheKeyPrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}

/// Provider for video cache service
final videoCacheServiceProvider = Provider<VideoCacheService>((ref) {
  final dio = ref.watch(publicDioProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return VideoCacheService(dio, prefs);
});

/// State notifier for managing active downloads
class DownloadManagerNotifier extends Notifier<Map<String, DownloadState>> {
  final Map<String, CancelToken> _cancelTokens = {};

  @override
  Map<String, DownloadState> build() {
    return {};
  }

  /// Start downloading a video
  Future<void> startDownload(String lectureId, String videoUrl) async {
    // Check if already downloading
    if (state[lectureId]?.isDownloading ?? false) return;

    final cacheService = ref.read(videoCacheServiceProvider);

    // Create cancel token
    final cancelToken = CancelToken();
    _cancelTokens[lectureId] = cancelToken;

    // Update state to downloading
    state = {
      ...state,
      lectureId: DownloadState(
        lectureId: lectureId,
        isDownloading: true,
        progress: 0.0,
      ),
    };

    // Start download
    final result = await cacheService.downloadVideo(
      lectureId,
      videoUrl,
      cancelToken: cancelToken,
      onProgress: (progress) {
        state = {
          ...state,
          lectureId: state[lectureId]!.copyWith(progress: progress),
        };
      },
    );

    // Update final state
    state = {...state, lectureId: result};
    _cancelTokens.remove(lectureId);
  }

  /// Cancel an ongoing download
  void cancelDownload(String lectureId) {
    _cancelTokens[lectureId]?.cancel();
    _cancelTokens.remove(lectureId);
    state = {
      ...state,
      lectureId: DownloadState(
        lectureId: lectureId,
        isDownloading: false,
        isCompleted: false,
        error: 'Cancelled',
      ),
    };
  }

  /// Remove a download from state
  void removeDownload(String lectureId) {
    final newState = Map<String, DownloadState>.from(state);
    newState.remove(lectureId);
    state = newState;
  }
}

/// Provider for download manager
final downloadManagerProvider =
    NotifierProvider<DownloadManagerNotifier, Map<String, DownloadState>>(() {
  return DownloadManagerNotifier();
});

/// Provider to check if a specific lecture is cached
final isLectureCachedProvider = FutureProvider.family<bool, String>((ref, lectureId) async {
  final cacheService = ref.watch(videoCacheServiceProvider);
  return await cacheService.isCached(lectureId);
});

/// Provider to get cached path for a lecture
final cachedVideoPathProvider = FutureProvider.family<String?, String>((ref, lectureId) async {
  final cacheService = ref.watch(videoCacheServiceProvider);
  return await cacheService.getCachedPath(lectureId);
});

/// Provider to get total cache size
final cacheSizeProvider = FutureProvider<int>((ref) async {
  final cacheService = ref.watch(videoCacheServiceProvider);
  return await cacheService.getCacheSize();
});

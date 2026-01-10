import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/live_class.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/live_class_repository.dart';
import '../../data/repositories/live_class_repository_impl.dart';
import '../../data/datasources/remote/live_class_remote_datasource.dart';
import '../providers/course_provider.dart'; // To access dioClientProvider

// Repository Provider
final liveClassRepositoryProvider = Provider<LiveClassRepository>((ref) {
  final dioClientAsync = ref.watch(dioClientProvider);
  
  // We throw if not ready because this provider should only be accessed when authenticated
  // (which usually implies dioClient is ready)
  return dioClientAsync.when(
    data: (dioClient) {
      return LiveClassRepositoryImpl(
        LiveClassRemoteDataSourceImpl(dioClient),
      );
    },
    loading: () => throw Exception('Dio Client not initialized'),
    error: (e, s) => throw Exception('Dio Client failed: $e'),
  );
});

// Today Live Classes Provider
final todayLiveClassesProvider = FutureProvider.autoDispose<List<LiveClass>>((ref) async {
  final repository = ref.watch(liveClassRepositoryProvider);
  return await repository.getTodayLiveClasses();
});

// Upcoming Live Classes Provider
final upcomingLiveClassesProvider = FutureProvider.autoDispose<List<LiveClass>>((ref) async {
  final repository = ref.watch(liveClassRepositoryProvider);
  return await repository.getUpcomingLiveClasses();
});

// Course Recordings Provider
final courseRecordingsProvider = FutureProvider.autoDispose.family<List<Recording>, String>((ref, courseId) async {
  final repository = ref.watch(liveClassRepositoryProvider);
  return await repository.getCourseRecordings(courseId);
});

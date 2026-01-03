import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/course.dart';
import '../../data/repositories/course_repository_impl.dart';
import '../../data/datasources/remote/course_remote_datasource.dart';
import '../../data/datasources/remote/public_course_datasource.dart';
import '../../core/api/dio_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/services/data_freshness_manager.dart';
import '../../data/models/response/course_response.dart';
import 'auth_provider.dart';

// Public Dio Client (no auth required)
final publicDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
});

// Public Course DataSource Provider
final publicCourseDataSourceProvider = Provider<PublicCourseDataSource>((ref) {
  final dio = ref.watch(publicDioProvider);
  return PublicCourseDataSource(dio);
});

// DioClient Provider (async initialization - requires auth)
final dioClientProvider = FutureProvider<DioClient>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return await DioClient.create(storage);
});

// Authenticated Course Repository Provider
final courseRepositoryProvider = Provider<CourseRepositoryImpl>((ref) {
  final dioClientAsync = ref.watch(dioClientProvider);

  return dioClientAsync.when(
    data: (dioClient) {
      final remoteDataSource = CourseRemoteDataSource(dioClient);
      return CourseRepositoryImpl(remoteDataSource);
    },
    loading: () => throw Exception('DioClient is still loading'),
    error: (error, stack) =>
        throw Exception('Failed to initialize DioClient: $error'),
  );
});

// All Courses Provider - uses public API if not logged in, student API if logged in
final allCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final isLoggedIn = authState.value != null;

  List<Course> courses;
  if (isLoggedIn) {
    // Use authenticated student API
    final repository = ref.watch(courseRepositoryProvider);
    final result = await repository.getAllCourses();

    courses = result.fold(
      (failure) => throw Exception(failure.message),
      (courses) => courses,
    );
  } else {
    // Use public API
    final publicDataSource = ref.watch(publicCourseDataSourceProvider);
    final responses = await publicDataSource.fetchPublicCourses();

    // Map to domain entities
    courses = responses
        .map(
          (r) => Course(
            id: r.id,
            title: r.title,
            description: r.description,
            thumbnail: r.thumbnail,
            price: r.price,
            published: r.published,
            instructorId: r.instructorId,
            mediaType: r.mediaType ?? 'image',
            enrolled: r.enrolled,
            sections: r.sections
                .map(
                  (s) => Section(
                    id: s.id,
                    title: s.title,
                    lectures: s.lectures
                        .map(
                          (l) => Lecture(
                            id: l.id,
                            title: l.title,
                            videoUrl: l.videoUrl,
                            videoProvider: l.videoProvider,
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
            resources: r.resources
                .map(
                  (res) => Resource(
                    id: res.id,
                    title: res.title,
                    type: res.type,
                    url: res.url,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  // Record successful fetch for freshness tracking
  ref.read(freshnessManagerProvider.notifier).recordFetch(ProviderKeys.allCourses);

  return courses;
});

// Enrolled Courses Provider - requires authentication
final enrolledCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  final result = await repository.getEnrolledCourses();

  final courses = result.fold(
    (failure) => throw Exception(failure.message),
    (courses) => courses,
  );

  // Record successful fetch for freshness tracking
  ref.read(freshnessManagerProvider.notifier).recordFetch(ProviderKeys.enrolledCourses);

  return courses;
});

// Single Course Details Provider
final courseDetailsProvider = FutureProvider.family<Course, String>((
  ref,
  courseId,
) async {
  final authState = ref.watch(authStateProvider);
  final isLoggedIn = authState.value != null;

  Course course;
  if (isLoggedIn) {
    final repository = ref.watch(courseRepositoryProvider);
    final result = await repository.getCourseDetails(courseId);

    course = result.fold(
      (failure) => throw Exception(failure.message),
      (course) => course,
    );
  } else {
    final publicDataSource = ref.watch(publicCourseDataSourceProvider);
    final response = await publicDataSource.fetchPublicCourseDetails(courseId);
    course = _mapFromResponse(response);
  }

  // Record successful fetch for freshness tracking
  ref.read(freshnessManagerProvider.notifier).recordFetch(
    ProviderKeys.courseDetailsKey(courseId),
  );

  return course;
});

Course _mapFromResponse(CourseResponse r) {
  return Course(
    id: r.id,
    title: r.title,
    description: r.description,
    thumbnail: r.thumbnail,
    price: r.price,
    published: r.published,
    instructorId: r.instructorId,
    mediaType: r.mediaType ?? 'image',
    enrolled: r.enrolled,
    sections: r.sections
        .map(
          (s) => Section(
            id: s.id,
            title: s.title,
            lectures: s.lectures
                .map(
                  (l) => Lecture(
                    id: l.id,
                    title: l.title,
                    videoUrl: l.videoUrl,
                    videoProvider: l.videoProvider,
                  ),
                )
                .toList(),
          ),
        )
        .toList(),
    resources: r.resources
        .map(
          (res) => Resource(
            id: res.id,
            title: res.title,
            type: res.type,
            url: res.url,
          ),
        )
        .toList(),
  );
}

// Course Curriculum Provider
final courseCurriculumProvider = FutureProvider.family<dynamic, String>((
  ref,
  courseId,
) async {
  final repository = ref.watch(courseRepositoryProvider);
  final result = await repository.getCourseCurriculum(courseId);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (curriculum) => curriculum,
  );
});

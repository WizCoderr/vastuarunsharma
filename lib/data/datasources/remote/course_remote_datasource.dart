import '../../models/response/api_response.dart';
import '../../models/response/course_response.dart';
import '../../models/response/curriculum_response.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_endpoints.dart';

class CourseRemoteDataSource {
  final DioClient client;
  CourseRemoteDataSource(this.client);

  Future<List<CourseResponse>> fetchAllCourses() async {
    final resp = await client.get(ApiEndpoints.courses);
    final api = ApiResponse<List<dynamic>>.fromJson(
      resp.data as Map<String, dynamic>,
      (j) => j as List<dynamic>,
    );
    if (api.success && api.data != null) {
      return api.data!
          .map((e) => CourseResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(api.message ?? 'Failed to fetch courses');
  }

  Future<List<CourseResponse>> fetchEnrolledCourses() async {
    final resp = await client.get(ApiEndpoints.enrolledCourses);
    final api = ApiResponse<List<dynamic>>.fromJson(
      resp.data as Map<String, dynamic>,
      (j) => j as List<dynamic>,
    );
    if (api.success && api.data != null) {
      return api.data!
          .map((e) => CourseResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(api.message ?? 'Failed to fetch enrolled courses');
  }

  Future<CourseResponse> fetchCourseDetails(String id) async {
    final resp = await client.get(ApiEndpoints.courseDetails(id));
    final api = ApiResponse<Map<String, dynamic>>.fromJson(
      resp.data as Map<String, dynamic>,
      (j) => j as Map<String, dynamic>,
    );
    if (api.success && api.data != null) {
      return CourseResponse.fromJson(api.data!);
    }
    throw Exception(api.message ?? 'Failed to fetch course details');
  }

  Future<CurriculumResponse> fetchCourseCurriculum(String id) async {
    final resp = await client.get(ApiEndpoints.courseCurriculum(id));
    final api = ApiResponse<Map<String, dynamic>>.fromJson(
      resp.data as Map<String, dynamic>,
      (j) => j as Map<String, dynamic>,
    );
    if (api.success && api.data != null) {
      return CurriculumResponse.fromJson(api.data!);
    }
    throw Exception(api.message ?? 'Failed to fetch curriculum');
  }
}

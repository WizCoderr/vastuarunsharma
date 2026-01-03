import 'package:dio/dio.dart';
import '../../models/response/api_response.dart';
import '../../models/response/course_response.dart';
import '../../../core/api/api_endpoints.dart';

/// Public course datasource - doesn't require authentication
class PublicCourseDataSource {
  final Dio _dio;

  PublicCourseDataSource(this._dio);

  Future<List<CourseResponse>> fetchPublicCourses() async {
    final resp = await _dio.get(
      '${ApiEndpoints.baseUrl}${ApiEndpoints.publicCourses}',
    );

    final api = ApiResponse<List<dynamic>>.fromJson(
      resp.data as Map<String, dynamic>,
      (j) => j as List<dynamic>,
    );

    if (api.success && api.data != null) {
      return api.data!
          .map((e) => CourseResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(api.message ?? 'Failed to fetch public courses');
  }

  Future<CourseResponse> fetchPublicCourseDetails(String id) async {
    final resp = await _dio.get(
      '${ApiEndpoints.baseUrl}${ApiEndpoints.publiccourseDetails(id)}',
    );

    final api = ApiResponse<Map<String, dynamic>>.fromJson(
      resp.data as Map<String, dynamic>,
      (j) => j as Map<String, dynamic>,
    );

    if (api.success && api.data != null) {
      return CourseResponse.fromJson(api.data!);
    }
    throw Exception(api.message ?? 'Failed to fetch public course details');
  }
}

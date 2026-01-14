import 'package:dio/dio.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../models/request/progress_update_request.dart';
import '../../models/response/api_response.dart';

class ProgressRemoteDataSource {
  final DioClient client;
  ProgressRemoteDataSource(this.client);

  Future<void> updateProgress(ProgressUpdateRequest req) async {
    try {
      final resp = await client.post(
        ApiEndpoints.updateProgress,
        data: req.toJson(),
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        resp.data as Map<String, dynamic>,
        (j) => j as Map<String, dynamic>,
      );
      if (!api.success) {
        throw Exception(api.message ?? 'Failed to update progress');
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        // Log the actual server response for debugging
        throw Exception(
          'Server Error: ${e.response?.statusCode} - ${e.response?.data}',
        );
      }
      rethrow;
    }
  }
}

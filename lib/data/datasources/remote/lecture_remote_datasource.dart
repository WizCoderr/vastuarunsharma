import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../models/response/api_response.dart';
import '../../models/response/stream_url_response.dart';

class LectureRemoteDataSource {
  final DioClient client;
  LectureRemoteDataSource(this.client);

  Future<StreamUrlResponse> getStreamUrl(String lectureId) async {
    final resp = await client.get(ApiEndpoints.lectureStreamUrl(lectureId));
    final api = ApiResponse<Map<String, dynamic>>.fromJson(
      resp.data as Map<String, dynamic>,
      (j) => j as Map<String, dynamic>,
    );
    if (api.success && api.data != null) {
      return StreamUrlResponse.fromJson(api.data!);
    }
    throw Exception(api.message ?? 'Failed to fetch stream url');
  }
}

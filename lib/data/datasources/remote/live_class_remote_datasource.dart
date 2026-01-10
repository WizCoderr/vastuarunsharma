import '../../../core/api/api_endpoints.dart';
import '../../models/live_class_model.dart';
import '../../models/recording_model.dart';
import '../../../core/api/dio_client.dart';

abstract class LiveClassRemoteDataSource {
  Future<List<LiveClassModel>> getTodayLiveClasses();
  Future<List<LiveClassModel>> getUpcomingLiveClasses();
  Future<List<RecordingModel>> getCourseRecordings(String courseId);
  Future<void> registerDeviceToken(String token);
  Future<void> unregisterDeviceToken();
}

class LiveClassRemoteDataSourceImpl implements LiveClassRemoteDataSource {
  final DioClient _client;

  LiveClassRemoteDataSourceImpl(this._client);

  @override
  Future<List<LiveClassModel>> getTodayLiveClasses() async {
    try {
      // response.data is dynamic, standard Dio response
      final response = await _client.get(ApiEndpoints.todayLiveClasses);
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((e) => LiveClassModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<LiveClassModel>> getUpcomingLiveClasses() async {
     try {
      final response = await _client.get(ApiEndpoints.upcomingLiveClasses);
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((e) => LiveClassModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<RecordingModel>> getCourseRecordings(String courseId) async {
     try {
      final response = await _client.get(ApiEndpoints.courseRecordings(courseId));
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((e) => RecordingModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> registerDeviceToken(String token) async {
     try {
      await _client.post(
        ApiEndpoints.deviceToken,
        data: {'token': token},
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> unregisterDeviceToken() async {
    try {
      await _client.delete(ApiEndpoints.deviceToken);
    } catch (e) {
      rethrow;
    }
  }
}

import '../../domain/entities/live_class.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/live_class_repository.dart';
import '../datasources/remote/live_class_remote_datasource.dart';

class LiveClassRepositoryImpl implements LiveClassRepository {
  final LiveClassRemoteDataSource _remoteDataSource;

  LiveClassRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<LiveClass>> getTodayLiveClasses() async {
    return await _remoteDataSource.getTodayLiveClasses();
  }

  @override
  Future<List<LiveClass>> getUpcomingLiveClasses() async {
    return await _remoteDataSource.getUpcomingLiveClasses();
  }

  @override
  Future<List<Recording>> getCourseRecordings(String courseId) async {
    return await _remoteDataSource.getCourseRecordings(courseId);
  }

  @override
  Future<void> registerDeviceToken(String token) async {
    await _remoteDataSource.registerDeviceToken(token);
  }

  @override
  Future<void> unregisterDeviceToken() async {
    await _remoteDataSource.unregisterDeviceToken();
  }
}

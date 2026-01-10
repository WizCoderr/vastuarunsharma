import '../entities/live_class.dart';
import '../entities/recording.dart';

abstract class LiveClassRepository {
  Future<List<LiveClass>> getTodayLiveClasses();
  Future<List<LiveClass>> getUpcomingLiveClasses();
  Future<List<Recording>> getCourseRecordings(String courseId);
  Future<void> registerDeviceToken(String token);
  Future<void> unregisterDeviceToken();
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_endpoints.dart';
import '../../data/models/response/stream_url_response.dart';
import 'course_provider.dart';

/// Provider to fetch stream URL for a lecture
final streamUrlProvider =
    FutureProvider.family<StreamUrlResponse, String>((ref, lectureId) async {
  final dioClientAsync = ref.watch(dioClientProvider);

  return dioClientAsync.when(
    data: (dioClient) async {
      final response = await dioClient.get(
        ApiEndpoints.lectureStreamUrl(lectureId),
      );

      if (response.statusCode == 200) {
        return StreamUrlResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch stream URL');
      }
    },
    loading: () => throw Exception('Client is loading'),
    error: (error, stack) => throw Exception('Failed to initialize client: $error'),
  );
});

/// Provider to cache stream URLs to avoid repeated API calls
class StreamUrlCache extends Notifier<Map<String, StreamUrlResponse>> {
  @override
  Map<String, StreamUrlResponse> build() {
    return {};
  }

  void cacheUrl(String lectureId, StreamUrlResponse response) {
    state = {...state, lectureId: response};
  }

  StreamUrlResponse? getUrl(String lectureId) {
    return state[lectureId];
  }

  void clearCache() {
    state = {};
  }
}

final streamUrlCacheProvider =
    NotifierProvider<StreamUrlCache, Map<String, StreamUrlResponse>>(() {
  return StreamUrlCache();
});

/// Combined provider that checks cache first, then fetches if needed
final cachedStreamUrlProvider =
    FutureProvider.family<StreamUrlResponse, String>((ref, lectureId) async {
  final cache = ref.read(streamUrlCacheProvider.notifier);

  // Check cache first
  final cached = cache.getUrl(lectureId);
  if (cached != null) {
    return cached;
  }

  // Fetch from API
  final response = await ref.read(streamUrlProvider(lectureId).future);

  // Cache the result
  cache.cacheUrl(lectureId, response);

  return response;
});

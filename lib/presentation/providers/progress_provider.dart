import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/progress_remote_datasource.dart';
import 'course_provider.dart';

final progressRemoteDataSourceProvider = Provider<ProgressRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(dioClientProvider);
  return dio.when(
    data: (client) => ProgressRemoteDataSource(client),
    loading: () => throw Exception('Dio client not initialized'),
    error: (e, s) => throw Exception('Dio client error: $e'),
  );
});

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/dio_client.dart';
import '../../models/wallet/google_wallet_issue_result.dart';

class WalletRemoteDataSource {
  final DioClient client;

  WalletRemoteDataSource(this.client);

  Future<GoogleWalletIssueResult> issueForOrder(String orderId) async {
    final resp = await client.post(ApiEndpoints.walletIssueForOrder(orderId));
    final body = resp.data;
    if (body is Map<String, dynamic>) {
      if (body['success'] == false) {
        final err = body['error'];
        if (err is Map && err['message'] is String) {
          throw Exception(err['message'] as String);
        }
        throw Exception(err?.toString() ?? 'Google Wallet request failed');
      }
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return GoogleWalletIssueResult.fromJson(data);
      }
      return GoogleWalletIssueResult.fromJson(body);
    }
    throw Exception('Unexpected Google Wallet response');
  }
}

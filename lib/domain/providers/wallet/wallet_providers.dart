import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vastuarunsharma/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:vastuarunsharma/presentation/providers/course_provider.dart';

final walletRemoteDataSourceProvider =
    FutureProvider<WalletRemoteDataSource>((ref) async {
  final client = await ref.watch(dioClientProvider.future);
  return WalletRemoteDataSource(client);
});

class WalletController {
  WalletController(this._ref);

  final Ref _ref;

  Future<void> addOrderReceiptToGoogleWallet(String orderId) async {
    final ds = await _ref.read(walletRemoteDataSourceProvider.future);
    final result = await ds.issueForOrder(orderId);
    if (result.saveUrl.isEmpty) {
      throw Exception('Google Wallet save link was empty');
    }
    final uri = Uri.parse(result.saveUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw Exception(
        'Could not open Google Wallet. Install Google Wallet or try again from a browser.',
      );
    }
  }
}

final walletControllerProvider = Provider<WalletController>((ref) {
  return WalletController(ref);
});

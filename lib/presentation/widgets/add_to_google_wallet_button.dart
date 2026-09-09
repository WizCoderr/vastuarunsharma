import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vastuarunsharma/domain/providers/wallet/wallet_providers.dart';

class AddToGoogleWalletButton extends ConsumerStatefulWidget {
  final String orderId;

  const AddToGoogleWalletButton({super.key, required this.orderId});

  @override
  ConsumerState<AddToGoogleWalletButton> createState() =>
      _AddToGoogleWalletButtonState();
}

class _AddToGoogleWalletButtonState
    extends ConsumerState<AddToGoogleWalletButton> {
  bool _loading = false;

  Future<void> _onPressed() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(walletControllerProvider)
          .addOrderReceiptToGoogleWallet(widget.orderId);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: 'Add to Google Wallet',
          child: InkWell(
            onTap: _loading ? null : _onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Opacity(
              opacity: _loading ? 0.6 : 1,
              child: Image.network(
                'https://developers.google.com/static/wallet/images/add-to-google-wallet-button.png',
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => ElevatedButton.icon(
                  onPressed: _loading ? null : _onPressed,
                  icon: const Icon(Icons.account_balance_wallet),
                  label: Text(
                    _loading ? 'Preparing…' : 'Add to Google Wallet',
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}

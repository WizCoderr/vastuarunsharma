/// Formats a rupee amount for display (e.g. ₹1,499.00).
String formatInr(double amount, {bool showDecimals = true}) {
  final isNegative = amount < 0;
  final absolute = amount.abs();
  final fixed = showDecimals
      ? absolute.toStringAsFixed(2)
      : absolute.round().toString();
  final parts = fixed.split('.');
  final intPart = parts[0];
  final fracPart = parts.length > 1 ? parts[1] : '00';

  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(intPart[i]);
  }

  final formatted = showDecimals ? '${buffer.toString()}.$fracPart' : buffer.toString();
  return isNegative ? '-₹$formatted' : '₹$formatted';
}

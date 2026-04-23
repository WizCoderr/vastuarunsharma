enum PaymentStatus { pending, success, failed, refunded }

extension PaymentStatusWire on PaymentStatus {
  String get wireName => name.toUpperCase();
}

class Payment {
  final PaymentStatus status;

  Payment({required this.status});

  factory Payment.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'PENDING').toUpperCase();
    final status = PaymentStatus.values.firstWhere(
      (e) => e.wireName == statusStr,
      orElse: () => PaymentStatus.pending,
    );
    return Payment(status: status);
  }

  Map<String, dynamic> toJson() => {'status': status.wireName};
}

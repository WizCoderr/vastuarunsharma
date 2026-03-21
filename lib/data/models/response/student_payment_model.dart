enum PaymentStatus { PAID, PENDING, OVERDUE }

class StudentPaymentModel {
  final String id;
  final String courseId;
  final String title;
  final double amount;
  final DateTime dueDate;
  final PaymentStatus status;

  StudentPaymentModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  factory StudentPaymentModel.fromJson(Map<String, dynamic> json) {
    return StudentPaymentModel(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: DateTime.tryParse(json['dueDate'] as String? ?? '') ?? DateTime.now(),
      status: _parseStatus(json['status'] as String? ?? 'PENDING'),
    );
  }

  static PaymentStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return PaymentStatus.PAID;
      case 'OVERDUE':
        return PaymentStatus.OVERDUE;
      case 'PENDING':
      default:
        return PaymentStatus.PENDING;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
    };
  }
}

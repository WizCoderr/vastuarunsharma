class OrderResponse {
  final String id;
  final String entity;
  final int amount;
  final int amountPaid;
  final int amountDue;
  final String currency;
  final String receipt;
  final String status;
  final int attempts;
  final int createdAt;
  final String? key; // Sometimes sent from backend for convenience

  OrderResponse({
    required this.id,
    required this.entity,
    required this.amount,
    required this.amountPaid,
    required this.amountDue,
    required this.currency,
    required this.receipt,
    required this.status,
    required this.attempts,
    required this.createdAt,
    this.key,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) => OrderResponse(
    id: json['id'] as String? ?? '',
    entity: json['entity'] as String? ?? 'order',
    amount: json['amount'] as int? ?? 0,
    amountPaid: json['amount_paid'] as int? ?? 0,
    amountDue: json['amount_due'] as int? ?? 0,
    currency: json['currency'] as String? ?? 'INR',
    receipt: json['receipt'] as String? ?? '',
    status: json['status'] as String? ?? 'created',
    attempts: json['attempts'] as int? ?? 0,
    createdAt: json['created_at'] as int? ?? 0,
    key: json['key'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'entity': entity,
    'amount': amount,
    'amount_paid': amountPaid,
    'amount_due': amountDue,
    'currency': currency,
    'receipt': receipt,
    'status': status,
    'attempts': attempts,
    'created_at': createdAt,
    if (key != null) 'key': key,
  };
}

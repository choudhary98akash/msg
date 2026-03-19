class PaymentModel {
  int? id;
  int bookingId;
  String paymentType;
  double amount;
  DateTime paymentDate;
  String paymentMode;
  String? bankName;
  String? chequeNumber;
  String? transactionId;
  String? receiptNumber;
  String status;
  String? remarks;
  DateTime createdAt;

  PaymentModel({
    this.id,
    required this.bookingId,
    required this.paymentType,
    required this.amount,
    required this.paymentDate,
    required this.paymentMode,
    this.bankName,
    this.chequeNumber,
    this.transactionId,
    this.receiptNumber,
    this.status = 'completed',
    this.remarks,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'payment_type': paymentType,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_mode': paymentMode,
      'bank_name': bankName,
      'cheque_number': chequeNumber,
      'transaction_id': transactionId,
      'receipt_number': receiptNumber,
      'status': status,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as int?,
      bookingId: map['booking_id'] as int,
      paymentType: map['payment_type'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      paymentMode: map['payment_mode'] as String,
      bankName: map['bank_name'] as String?,
      chequeNumber: map['cheque_number'] as String?,
      transactionId: map['transaction_id'] as String?,
      receiptNumber: map['receipt_number'] as String?,
      status: map['status'] as String? ?? 'completed',
      remarks: map['remarks'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  PaymentModel copyWith({
    int? id,
    int? bookingId,
    String? paymentType,
    double? amount,
    DateTime? paymentDate,
    String? paymentMode,
    String? bankName,
    String? chequeNumber,
    String? transactionId,
    String? receiptNumber,
    String? status,
    String? remarks,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      paymentType: paymentType ?? this.paymentType,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMode: paymentMode ?? this.paymentMode,
      bankName: bankName ?? this.bankName,
      chequeNumber: chequeNumber ?? this.chequeNumber,
      transactionId: transactionId ?? this.transactionId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

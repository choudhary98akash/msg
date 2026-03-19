class QuotationModel {
  int? id;
  int? customerId;
  String customerName;
  String? phone;
  String plotNumber;
  String? block;
  String? sector;
  String? location;
  double length;
  double breadth;
  double totalArea;
  double ratePerGaj;
  double totalPrice;
  double downPaymentPercent;
  double downPaymentAmount;
  int emiMonths;
  double emiAmount;
  int validityDays;
  DateTime? validUntil;
  String? remarks;
  String status;
  DateTime createdAt;
  DateTime? updatedAt;

  QuotationModel({
    this.id,
    this.customerId,
    required this.customerName,
    this.phone,
    required this.plotNumber,
    this.block,
    this.sector,
    this.location,
    required this.length,
    required this.breadth,
    required this.totalArea,
    required this.ratePerGaj,
    required this.totalPrice,
    required this.downPaymentPercent,
    required this.downPaymentAmount,
    required this.emiMonths,
    required this.emiAmount,
    this.validityDays = 30,
    this.validUntil,
    this.remarks,
    this.status = 'pending',
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'phone': phone,
      'plot_number': plotNumber,
      'block': block,
      'sector': sector,
      'location': location,
      'length': length,
      'breadth': breadth,
      'total_area': totalArea,
      'rate_per_gaj': ratePerGaj,
      'total_price': totalPrice,
      'down_payment_percent': downPaymentPercent,
      'down_payment_amount': downPaymentAmount,
      'emi_months': emiMonths,
      'emi_amount': emiAmount,
      'validity_days': validityDays,
      'valid_until': validUntil?.toIso8601String(),
      'remarks': remarks,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory QuotationModel.fromMap(Map<String, dynamic> map) {
    return QuotationModel(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String,
      phone: map['phone'] as String?,
      plotNumber: map['plot_number'] as String,
      block: map['block'] as String?,
      sector: map['sector'] as String?,
      location: map['location'] as String?,
      length: (map['length'] as num).toDouble(),
      breadth: (map['breadth'] as num).toDouble(),
      totalArea: (map['total_area'] as num).toDouble(),
      ratePerGaj: (map['rate_per_gaj'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      downPaymentPercent: (map['down_payment_percent'] as num).toDouble(),
      downPaymentAmount: (map['down_payment_amount'] as num).toDouble(),
      emiMonths: map['emi_months'] as int,
      emiAmount: (map['emi_amount'] as num).toDouble(),
      validityDays: map['validity_days'] as int? ?? 30,
      validUntil: map['valid_until'] != null
          ? DateTime.parse(map['valid_until'] as String)
          : null,
      remarks: map['remarks'] as String?,
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  QuotationModel copyWith({
    int? id,
    int? customerId,
    String? customerName,
    String? phone,
    String? plotNumber,
    String? block,
    String? sector,
    String? location,
    double? length,
    double? breadth,
    double? totalArea,
    double? ratePerGaj,
    double? totalPrice,
    double? downPaymentPercent,
    double? downPaymentAmount,
    int? emiMonths,
    double? emiAmount,
    int? validityDays,
    DateTime? validUntil,
    String? remarks,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuotationModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      plotNumber: plotNumber ?? this.plotNumber,
      block: block ?? this.block,
      sector: sector ?? this.sector,
      location: location ?? this.location,
      length: length ?? this.length,
      breadth: breadth ?? this.breadth,
      totalArea: totalArea ?? this.totalArea,
      ratePerGaj: ratePerGaj ?? this.ratePerGaj,
      totalPrice: totalPrice ?? this.totalPrice,
      downPaymentPercent: downPaymentPercent ?? this.downPaymentPercent,
      downPaymentAmount: downPaymentAmount ?? this.downPaymentAmount,
      emiMonths: emiMonths ?? this.emiMonths,
      emiAmount: emiAmount ?? this.emiAmount,
      validityDays: validityDays ?? this.validityDays,
      validUntil: validUntil ?? this.validUntil,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isExpired {
    if (validUntil == null) return false;
    return DateTime.now().isAfter(validUntil!);
  }
}

class BookingModel {
  int? id;
  int customerId;
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
  DateTime? tokenDate;
  double tokenAmount;
  DateTime bookingDate;
  String? remarks;
  String status;
  DateTime createdAt;
  DateTime? updatedAt;

  BookingModel({
    this.id,
    required this.customerId,
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
    this.tokenDate,
    required this.tokenAmount,
    DateTime? bookingDate,
    this.remarks,
    this.status = 'active',
    DateTime? createdAt,
    this.updatedAt,
  }) : bookingDate = bookingDate ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
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
      'token_date': tokenDate?.toIso8601String(),
      'token_amount': tokenAmount,
      'booking_date': bookingDate.toIso8601String(),
      'remarks': remarks,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
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
      tokenDate: map['token_date'] != null
          ? DateTime.parse(map['token_date'] as String)
          : null,
      tokenAmount: (map['token_amount'] as num).toDouble(),
      bookingDate: DateTime.parse(map['booking_date'] as String),
      remarks: map['remarks'] as String?,
      status: map['status'] as String? ?? 'active',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  BookingModel copyWith({
    int? id,
    int? customerId,
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
    DateTime? tokenDate,
    double? tokenAmount,
    DateTime? bookingDate,
    String? remarks,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
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
      tokenDate: tokenDate ?? this.tokenDate,
      tokenAmount: tokenAmount ?? this.tokenAmount,
      bookingDate: bookingDate ?? this.bookingDate,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

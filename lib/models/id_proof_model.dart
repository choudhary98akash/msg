class IdProofModel {
  int? id;
  int customerId;
  String type;
  String number;
  String? imagePath;
  DateTime createdAt;

  IdProofModel({
    this.id,
    required this.customerId,
    required this.type,
    required this.number,
    this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'type': type,
      'number': number,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory IdProofModel.fromMap(Map<String, dynamic> map) {
    return IdProofModel(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      type: map['type'] as String,
      number: map['number'] as String,
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  IdProofModel copyWith({
    int? id,
    int? customerId,
    String? type,
    String? number,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return IdProofModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      type: type ?? this.type,
      number: number ?? this.number,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

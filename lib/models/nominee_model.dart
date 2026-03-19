class NomineeModel {
  int? id;
  int customerId;
  String name;
  String? phone;
  String? relation;
  String? aadhar;
  DateTime createdAt;

  NomineeModel({
    this.id,
    required this.customerId,
    required this.name,
    this.phone,
    this.relation,
    this.aadhar,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'name': name,
      'phone': phone,
      'relation': relation,
      'aadhar': aadhar,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NomineeModel.fromMap(Map<String, dynamic> map) {
    return NomineeModel(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      relation: map['relation'] as String?,
      aadhar: map['aadhar'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  NomineeModel copyWith({
    int? id,
    int? customerId,
    String? name,
    String? phone,
    String? relation,
    String? aadhar,
    DateTime? createdAt,
  }) {
    return NomineeModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relation: relation ?? this.relation,
      aadhar: aadhar ?? this.aadhar,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

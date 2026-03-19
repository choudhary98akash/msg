class CustomerModel {
  int? id;
  String name;
  String? phone;
  String? email;
  String? address;
  DateTime? dob;
  String? occupation;
  String? relationName;
  String? relationType;
  DateTime createdAt;
  DateTime? updatedAt;

  CustomerModel({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.dob,
    this.occupation,
    this.relationName,
    this.relationType,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'dob': dob?.toIso8601String(),
      'occupation': occupation,
      'relation_name': relationName,
      'relation_type': relationType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      dob: map['dob'] != null ? DateTime.parse(map['dob'] as String) : null,
      occupation: map['occupation'] as String?,
      relationName: map['relation_name'] as String?,
      relationType: map['relation_type'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  CustomerModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    DateTime? dob,
    String? occupation,
    String? relationName,
    String? relationType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      dob: dob ?? this.dob,
      occupation: occupation ?? this.occupation,
      relationName: relationName ?? this.relationName,
      relationType: relationType ?? this.relationType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

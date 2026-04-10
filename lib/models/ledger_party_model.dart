class LedgerParty {
  int? id;
  String name;
  String? phone;
  String partyType;
  double openingBalance;
  String? notes;
  DateTime createdAt;

  LedgerParty({
    this.id,
    required this.name,
    this.phone,
    required this.partyType,
    this.openingBalance = 0,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static const String typeDebtor = 'debtor';
  static const String typeCreditor = 'creditor';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'party_type': partyType,
      'opening_balance': openingBalance,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LedgerParty.fromMap(Map<String, dynamic> map) {
    return LedgerParty(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      partyType: map['party_type'] as String,
      openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  LedgerParty copyWith({
    int? id,
    String? name,
    String? phone,
    String? partyType,
    double? openingBalance,
    String? notes,
    DateTime? createdAt,
  }) {
    return LedgerParty(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      partyType: partyType ?? this.partyType,
      openingBalance: openingBalance ?? this.openingBalance,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isDebtor => partyType == typeDebtor;
  bool get isCreditor => partyType == typeCreditor;
}

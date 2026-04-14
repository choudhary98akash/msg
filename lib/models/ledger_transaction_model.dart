import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'ledger_party_model.dart';

class LedgerTransaction {
  int? id;
  int partyId;
  String type;
  double amount;
  DateTime date;
  String? remark;
  List<String>? proofImages;
  DateTime createdAt;

  static const int maxProofImages = 4;

  LedgerTransaction({
    this.id,
    required this.partyId,
    required this.type,
    required this.amount,
    DateTime? date,
    this.remark,
    this.proofImages,
    DateTime? createdAt,
  })  : date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  static const String typeGive = 'give';
  static const String typeTake = 'take';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'party_id': partyId,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'remark': remark,
      'proof_images': proofImages != null ? jsonEncode(proofImages) : null,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LedgerTransaction.fromMap(Map<String, dynamic> map) {
    List<String>? images;
    final proofImagesData = map['proof_images'];
    if (proofImagesData != null &&
        proofImagesData.toString().trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(proofImagesData as String);
        if (decoded is List) {
          images = decoded
              .whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .toSet()
              .toList();
        }
      } catch (e) {
        debugPrint('Failed to decode images JSON: $e');
        images = [];
      }
    }

    return LedgerTransaction(
      id: map['id'] as int?,
      partyId: map['party_id'] as int,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      remark: map['remark'] as String?,
      proofImages: images,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  LedgerTransaction copyWith({
    int? id,
    int? partyId,
    String? type,
    double? amount,
    DateTime? date,
    String? remark,
    List<String>? proofImages,
    DateTime? createdAt,
  }) {
    return LedgerTransaction(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      remark: remark ?? this.remark,
      proofImages: proofImages ?? this.proofImages,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isGive => type == typeGive;
  bool get isTake => type == typeTake;

  bool get canAddProofImage => (proofImages?.length ?? 0) < maxProofImages;
  int get proofImageCount => proofImages?.length ?? 0;

  bool addProofImage(String path) {
    if (!canAddProofImage) return false;
    proofImages ??= [];
    proofImages!.add(path);
    return true;
  }

  bool removeProofImage(String path) {
    if (proofImages == null || proofImages!.isEmpty) return false;
    return proofImages!.remove(path);
  }
}

class LedgerPartyWithBalance {
  final LedgerParty party;
  final double totalGive;
  final double totalTake;
  final double balance;

  LedgerPartyWithBalance({
    required this.party,
    required this.totalGive,
    required this.totalTake,
    required this.balance,
  });

  double get currentBalance {
    if (party.isDebtor) {
      return party.openingBalance + totalTake - totalGive;
    } else {
      return party.openingBalance + totalGive - totalTake;
    }
  }
}

class LedgerSummary {
  final double totalYouWillGet;
  final double totalYouWillGive;
  final double netBalance;
  final int debtorCount;
  final int creditorCount;

  LedgerSummary({
    required this.totalYouWillGet,
    required this.totalYouWillGive,
    required this.netBalance,
    required this.debtorCount,
    required this.creditorCount,
  });
}

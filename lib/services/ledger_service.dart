import '../models/ledger_party_model.dart';
import '../models/ledger_transaction_model.dart';
import '../services/database_service.dart';

class LedgerService {
  final DatabaseService _db = DatabaseService();

  Future<int> addParty(LedgerParty party) async {
    return await _db.insertLedgerParty(party);
  }

  Future<List<LedgerParty>> getAllParties() async {
    return await _db.getAllLedgerParties();
  }

  Future<LedgerParty?> getParty(int id) async {
    return await _db.getLedgerParty(id);
  }

  Future<List<LedgerParty>> getPartiesByType(String type) async {
    return await _db.getLedgerPartiesByType(type);
  }

  Future<List<LedgerParty>> searchParties(String query) async {
    return await _db.searchLedgerParties(query);
  }

  Future<int> updateParty(LedgerParty party) async {
    return await _db.updateLedgerParty(party);
  }

  Future<int> deleteParty(int id) async {
    return await _db.deleteLedgerParty(id);
  }

  Future<bool> partyHasTransactions(int partyId) async {
    return await _db.ledgerPartyHasTransactions(partyId);
  }

  Future<int> addTransaction(LedgerTransaction transaction) async {
    return await _db.insertLedgerTransaction(transaction);
  }

  Future<List<LedgerTransaction>> getTransactions(int partyId) async {
    return await _db.getLedgerTransactions(partyId);
  }

  Future<LedgerTransaction?> getTransaction(int id) async {
    return await _db.getLedgerTransaction(id);
  }

  Future<int> updateTransaction(LedgerTransaction transaction) async {
    return await _db.updateLedgerTransaction(transaction);
  }

  Future<int> deleteTransaction(int id) async {
    return await _db.deleteLedgerTransaction(id);
  }

  Future<double> getTotalGive(int partyId) async {
    return await _db.getTotalGiveForParty(partyId);
  }

  Future<double> getTotalTake(int partyId) async {
    return await _db.getTotalTakeForParty(partyId);
  }

  Future<double> getBalance(int partyId) async {
    final party = await getParty(partyId);
    if (party == null) return 0;

    final totalGive = await getTotalGive(partyId);
    final totalTake = await getTotalTake(partyId);

    if (party.isDebtor) {
      return party.openingBalance + totalTake - totalGive;
    } else {
      return party.openingBalance + totalGive - totalTake;
    }
  }

  Future<LedgerSummary> getSummary() async {
    return await _db.getLedgerSummary();
  }

  Future<List<LedgerPartyWithBalance>> getAllPartiesWithBalance() async {
    final parties = await getAllParties();
    final List<LedgerPartyWithBalance> result = [];

    for (var party in parties) {
      final totalGive = await getTotalGive(party.id!);
      final totalTake = await getTotalTake(party.id!);
      final balance = party.isDebtor
          ? party.openingBalance + totalTake - totalGive
          : party.openingBalance + totalGive - totalTake;

      result.add(LedgerPartyWithBalance(
        party: party,
        totalGive: totalGive,
        totalTake: totalTake,
        balance: balance,
      ));
    }

    result.sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));
    return result;
  }

  Future<List<LedgerPartyWithBalance>> getPartiesWithBalanceByType(
      String type) async {
    final parties = await getPartiesByType(type);
    final List<LedgerPartyWithBalance> result = [];

    for (var party in parties) {
      final totalGive = await getTotalGive(party.id!);
      final totalTake = await getTotalTake(party.id!);
      final balance = party.isDebtor
          ? party.openingBalance + totalTake - totalGive
          : party.openingBalance + totalGive - totalTake;

      result.add(LedgerPartyWithBalance(
        party: party,
        totalGive: totalGive,
        totalTake: totalTake,
        balance: balance,
      ));
    }

    result.sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));
    return result;
  }

  Future<List<LedgerPartyWithBalance>> searchPartiesWithBalance(
      String query) async {
    final parties = await searchParties(query);
    final List<LedgerPartyWithBalance> result = [];

    for (var party in parties) {
      final totalGive = await getTotalGive(party.id!);
      final totalTake = await getTotalTake(party.id!);
      final balance = party.isDebtor
          ? party.openingBalance + totalTake - totalGive
          : party.openingBalance + totalGive - totalTake;

      result.add(LedgerPartyWithBalance(
        party: party,
        totalGive: totalGive,
        totalTake: totalTake,
        balance: balance,
      ));
    }

    result.sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));
    return result;
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer_model.dart';
import '../models/nominee_model.dart';
import '../models/id_proof_model.dart';
import '../models/booking_model.dart';
import '../models/payment_model.dart';
import '../models/quotation_model.dart';
import '../models/ledger_party_model.dart';
import '../models/ledger_transaction_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ms_group_properties.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ledger_transaction (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          party_id INTEGER NOT NULL,
          type TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          remark TEXT,
          proof_images TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (party_id) REFERENCES ledger_party(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_ledger_transaction_party_v2 
        ON ledger_transaction(party_id)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_ledger_transaction_date_v2 
        ON ledger_transaction(date)
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        dob TEXT,
        occupation TEXT,
        relation_name TEXT,
        relation_type TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_customers_phone ON customers(phone)
    ''');

    await db.execute('''
      CREATE TABLE nominees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        relation TEXT,
        aadhar TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE id_proofs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        number TEXT NOT NULL,
        image_path TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE plot_bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        plot_number TEXT NOT NULL,
        block TEXT,
        sector TEXT,
        location TEXT,
        length REAL NOT NULL,
        breadth REAL NOT NULL,
        total_area REAL NOT NULL,
        rate_per_gaj REAL NOT NULL,
        total_price REAL NOT NULL,
        down_payment_percent REAL NOT NULL,
        down_payment_amount REAL NOT NULL,
        emi_months INTEGER NOT NULL,
        emi_amount REAL NOT NULL,
        token_date TEXT,
        token_amount REAL NOT NULL,
        booking_date TEXT NOT NULL,
        remarks TEXT,
        status TEXT DEFAULT 'active',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_bookings_customer ON plot_bookings(customer_id)
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        booking_id INTEGER NOT NULL,
        payment_type TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_mode TEXT NOT NULL,
        bank_name TEXT,
        cheque_number TEXT,
        transaction_id TEXT,
        receipt_number TEXT,
        status TEXT DEFAULT 'completed',
        remarks TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (booking_id) REFERENCES plot_bookings(id)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_payments_booking ON payments(booking_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_payments_date ON payments(payment_date)
    ''');

    await db.execute('''
      CREATE TABLE quotations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        customer_name TEXT NOT NULL,
        phone TEXT,
        plot_number TEXT NOT NULL,
        block TEXT,
        sector TEXT,
        location TEXT,
        length REAL NOT NULL,
        breadth REAL NOT NULL,
        total_area REAL NOT NULL,
        rate_per_gaj REAL NOT NULL,
        total_price REAL NOT NULL,
        down_payment_percent REAL NOT NULL,
        down_payment_amount REAL NOT NULL,
        emi_months INTEGER NOT NULL,
        emi_amount REAL NOT NULL,
        validity_days INTEGER DEFAULT 30,
        valid_until TEXT,
        remarks TEXT,
        status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ledger_party (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        party_type TEXT NOT NULL,
        opening_balance REAL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ledger_transaction (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        party_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        remark TEXT,
        proof_images TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (party_id) REFERENCES ledger_party(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_ledger_party_type ON ledger_party(party_type)');
    await db.execute(
        'CREATE INDEX idx_ledger_transaction_party ON ledger_transaction(party_id)');
    await db.execute(
        'CREATE INDEX idx_ledger_transaction_date ON ledger_transaction(date)');
  }

  Future<int> insertCustomer(CustomerModel customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap()..remove('id'));
  }

  Future<List<CustomerModel>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'created_at DESC');
    return maps.map((map) => CustomerModel.fromMap(map)).toList();
  }

  Future<CustomerModel?> getCustomer(int id) async {
    final db = await database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return CustomerModel.fromMap(maps.first);
  }

  Future<int> updateCustomer(CustomerModel customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> customerHasBookings(int customerId) async {
    final db = await database;
    final result = await db.query(
      'plot_bookings',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<bool> customerHasPayments(int customerId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT p.id FROM payments p
      INNER JOIN plot_bookings b ON p.booking_id = b.id
      WHERE b.customer_id = ?
      LIMIT 1
    ''', [customerId]);
    return result.isNotEmpty;
  }

  Future<bool> phoneExists(String phone, {int? excludeId}) async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: excludeId != null ? 'phone = ? AND id != ?' : 'phone = ?',
      whereArgs: excludeId != null ? [phone, excludeId] : [phone],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> insertNominee(NomineeModel nominee) async {
    final db = await database;
    return await db.insert('nominees', nominee.toMap()..remove('id'));
  }

  Future<List<NomineeModel>> getNominees(int customerId) async {
    final db = await database;
    final maps = await db.query(
      'nominees',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
    return maps.map((map) => NomineeModel.fromMap(map)).toList();
  }

  Future<int> updateNominee(NomineeModel nominee) async {
    final db = await database;
    return await db.update(
      'nominees',
      nominee.toMap(),
      where: 'id = ?',
      whereArgs: [nominee.id],
    );
  }

  Future<int> deleteNominee(int id) async {
    final db = await database;
    return await db.delete('nominees', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertIdProof(IdProofModel idProof) async {
    final db = await database;
    return await db.insert('id_proofs', idProof.toMap()..remove('id'));
  }

  Future<List<IdProofModel>> getIdProofs(int customerId) async {
    final db = await database;
    final maps = await db.query(
      'id_proofs',
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
    return maps.map((map) => IdProofModel.fromMap(map)).toList();
  }

  Future<int> deleteIdProof(int id) async {
    final db = await database;
    return await db.delete('id_proofs', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertBooking(BookingModel booking) async {
    final db = await database;
    return await db.insert('plot_bookings', booking.toMap()..remove('id'));
  }

  Future<List<BookingModel>> getAllBookings() async {
    final db = await database;
    final maps = await db.query('plot_bookings', orderBy: 'created_at DESC');
    return maps.map((map) => BookingModel.fromMap(map)).toList();
  }

  Future<List<BookingModel>> getBookingsForCustomer(int customerId) async {
    final db = await database;
    final maps = await db.query(
      'plot_bookings',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => BookingModel.fromMap(map)).toList();
  }

  Future<BookingModel?> getBooking(int id) async {
    final db = await database;
    final maps = await db.query(
      'plot_bookings',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return BookingModel.fromMap(maps.first);
  }

  Future<int> updateBooking(BookingModel booking) async {
    final db = await database;
    return await db.update(
      'plot_bookings',
      booking.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [booking.id],
    );
  }

  Future<int> deleteBooking(int id) async {
    final db = await database;
    return await db.delete('plot_bookings', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertPayment(PaymentModel payment) async {
    final db = await database;
    return await db.insert('payments', payment.toMap()..remove('id'));
  }

  Future<List<PaymentModel>> getPaymentsForBooking(int bookingId) async {
    final db = await database;
    final maps = await db.query(
      'payments',
      where: 'booking_id = ?',
      whereArgs: [bookingId],
      orderBy: 'payment_date DESC',
    );
    return maps.map((map) => PaymentModel.fromMap(map)).toList();
  }

  Future<List<PaymentModel>> getAllPayments() async {
    final db = await database;
    final maps = await db.query('payments', orderBy: 'payment_date DESC');
    return maps.map((map) => PaymentModel.fromMap(map)).toList();
  }

  Future<PaymentModel?> getPayment(int id) async {
    final db = await database;
    final maps = await db.query('payments', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return PaymentModel.fromMap(maps.first);
  }

  Future<int> deletePayment(int id) async {
    final db = await database;
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalReceivedAmount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM payments WHERE status = "completed"',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalReceivableAmount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total_price) as total FROM plot_bookings WHERE status = "active"',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, int>> getDashboardStats() async {
    final db = await database;
    final customerCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM customers'),
        ) ??
        0;
    final bookingCount = Sqflite.firstIntValue(
          await db.rawQuery(
              'SELECT COUNT(*) FROM plot_bookings WHERE status = "active"'),
        ) ??
        0;
    final paymentCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM payments'),
        ) ??
        0;
    final quotationCount = Sqflite.firstIntValue(
          await db.rawQuery(
              'SELECT COUNT(*) FROM quotations WHERE status = "pending"'),
        ) ??
        0;

    return {
      'customers': customerCount,
      'bookings': bookingCount,
      'payments': paymentCount,
      'quotations': quotationCount,
    };
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    final db = await database;
    final recentPayments = await db.rawQuery('''
      SELECT p.*, b.plot_number, c.name as customer_name
      FROM payments p
      INNER JOIN plot_bookings b ON p.booking_id = b.id
      INNER JOIN customers c ON b.customer_id = c.id
      ORDER BY p.created_at DESC
      LIMIT 5
    ''');
    return recentPayments;
  }

  Future<String> generateReceiptNumber() async {
    final db = await database;
    final year = DateTime.now().year;
    final prefix = 'REC-$year-';

    final result = await db.rawQuery('''
      SELECT receipt_number FROM payments
      WHERE receipt_number LIKE ?
      ORDER BY id DESC LIMIT 1
    ''', ['$prefix%']);

    if (result.isEmpty) {
      return '$prefix${1.toString().padLeft(4, '0')}';
    }

    final lastNumber = int.tryParse(
          result.first['receipt_number'].toString().replaceAll(prefix, ''),
        ) ??
        0;
    return '$prefix${(lastNumber + 1).toString().padLeft(4, '0')}';
  }

  Future<String> generateBookingNumber() async {
    final db = await database;
    final year = DateTime.now().year;
    final prefix = 'BK-$year-';

    final result = await db.rawQuery('''
      SELECT id FROM plot_bookings
      ORDER BY id DESC LIMIT 1
    ''');

    if (result.isEmpty) {
      return '$prefix${1.toString().padLeft(4, '0')}';
    }

    final lastId = result.first['id'] as int;
    return '$prefix${(lastId + 1).toString().padLeft(4, '0')}';
  }

  Future<String> generateQuotationNumber() async {
    final db = await database;
    final year = DateTime.now().year;
    final prefix = 'QT-$year-';

    final result = await db.rawQuery('''
      SELECT id FROM quotations
      ORDER BY id DESC LIMIT 1
    ''');

    if (result.isEmpty) {
      return '$prefix${1.toString().padLeft(4, '0')}';
    }

    final lastId = result.first['id'] as int;
    return '$prefix${(lastId + 1).toString().padLeft(4, '0')}';
  }

  Future<int> insertQuotation(QuotationModel quotation) async {
    final db = await database;
    return await db.insert('quotations', quotation.toMap()..remove('id'));
  }

  Future<List<QuotationModel>> getAllQuotations() async {
    final db = await database;
    final maps = await db.query('quotations', orderBy: 'created_at DESC');
    return maps.map((map) => QuotationModel.fromMap(map)).toList();
  }

  Future<QuotationModel?> getQuotation(int id) async {
    final db = await database;
    final maps = await db.query('quotations', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return QuotationModel.fromMap(maps.first);
  }

  Future<int> updateQuotation(QuotationModel quotation) async {
    final db = await database;
    return await db.update(
      'quotations',
      quotation.toMap()..['updated_at'] = DateTime.now().toIso8601String(),
      where: 'id = ?',
      whereArgs: [quotation.id],
    );
  }

  Future<int> deleteQuotation(int id) async {
    final db = await database;
    return await db.delete('quotations', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertLedgerParty(LedgerParty party) async {
    final db = await database;
    return await db.insert('ledger_party', party.toMap()..remove('id'));
  }

  Future<List<LedgerParty>> getAllLedgerParties() async {
    final db = await database;
    final maps = await db.query('ledger_party', orderBy: 'created_at DESC');
    return maps.map((map) => LedgerParty.fromMap(map)).toList();
  }

  Future<LedgerParty?> getLedgerParty(int id) async {
    final db = await database;
    final maps =
        await db.query('ledger_party', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return LedgerParty.fromMap(maps.first);
  }

  Future<List<LedgerParty>> getLedgerPartiesByType(String partyType) async {
    final db = await database;
    final maps = await db.query(
      'ledger_party',
      where: 'party_type = ?',
      whereArgs: [partyType],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => LedgerParty.fromMap(map)).toList();
  }

  Future<List<LedgerParty>> searchLedgerParties(String query) async {
    final db = await database;
    final maps = await db.query(
      'ledger_party',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => LedgerParty.fromMap(map)).toList();
  }

  Future<int> updateLedgerParty(LedgerParty party) async {
    final db = await database;
    return await db.update(
      'ledger_party',
      party.toMap(),
      where: 'id = ?',
      whereArgs: [party.id],
    );
  }

  Future<int> deleteLedgerParty(int id) async {
    final db = await database;
    await db
        .delete('ledger_transaction', where: 'party_id = ?', whereArgs: [id]);
    return await db.delete('ledger_party', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> ledgerPartyHasTransactions(int partyId) async {
    final db = await database;
    final result = await db.query(
      'ledger_transaction',
      where: 'party_id = ?',
      whereArgs: [partyId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<int> insertLedgerTransaction(LedgerTransaction transaction) async {
    final db = await database;
    return await db.insert(
        'ledger_transaction', transaction.toMap()..remove('id'));
  }

  Future<List<LedgerTransaction>> getLedgerTransactions(int partyId) async {
    final db = await database;
    final maps = await db.query(
      'ledger_transaction',
      where: 'party_id = ?',
      whereArgs: [partyId],
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((map) => LedgerTransaction.fromMap(map)).toList();
  }

  Future<LedgerTransaction?> getLedgerTransaction(int id) async {
    final db = await database;
    final maps =
        await db.query('ledger_transaction', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return LedgerTransaction.fromMap(maps.first);
  }

  Future<int> updateLedgerTransaction(LedgerTransaction transaction) async {
    final db = await database;
    return await db.update(
      'ledger_transaction',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteLedgerTransaction(int id) async {
    final db = await database;
    return await db
        .delete('ledger_transaction', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalGiveForParty(int partyId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM ledger_transaction WHERE party_id = ? AND type = ?',
      [partyId, 'give'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalTakeForParty(int partyId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM ledger_transaction WHERE party_id = ? AND type = ?',
      [partyId, 'take'],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<LedgerSummary> getLedgerSummary() async {
    final db = await database;

    final debtors = await db
        .query('ledger_party', where: 'party_type = ?', whereArgs: ['debtor']);
    final creditors = await db.query('ledger_party',
        where: 'party_type = ?', whereArgs: ['creditor']);

    double totalYouWillGet = 0;
    double totalYouWillGive = 0;

    for (var debtor in debtors) {
      final partyId = debtor['id'] as int;
      final openingBalance =
          (debtor['opening_balance'] as num?)?.toDouble() ?? 0;
      final totalGive = await getTotalGiveForParty(partyId);
      final totalTake = await getTotalTakeForParty(partyId);
      final balance = openingBalance + totalTake - totalGive;
      if (balance > 0) totalYouWillGet += balance;
    }

    for (var creditor in creditors) {
      final partyId = creditor['id'] as int;
      final openingBalance =
          (creditor['opening_balance'] as num?)?.toDouble() ?? 0;
      final totalGive = await getTotalGiveForParty(partyId);
      final totalTake = await getTotalTakeForParty(partyId);
      final balance = openingBalance + totalGive - totalTake;
      if (balance > 0) totalYouWillGive += balance;
    }

    return LedgerSummary(
      totalYouWillGet: totalYouWillGet,
      totalYouWillGive: totalYouWillGive,
      netBalance: totalYouWillGet - totalYouWillGive,
      debtorCount: debtors.length,
      creditorCount: creditors.length,
    );
  }
}

// db/db_helper.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/wallet.dart';
import '../models/txn.dart';
import '../models/category.dart';
import '../models/recurring.dart';
import '../models/budget.dart';
import 'package:intl/intl.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _db;
  DBHelper._init();

  Future<void> init() async {
    if (_db != null) return;
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'money_app.db');
    _db = await openDatabase(path, version: 3, onCreate: _createDB, onUpgrade: _onUpgrade);
    // seed categories if empty
    await _seedCategories();
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE wallets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      balance REAL,
      colorValue INTEGER,
      icon TEXT
    );
    ''');
    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key TEXT UNIQUE,
      name TEXT,
      icon TEXT,
      colorValue INTEGER
    );
    ''');
    await db.execute('''
    CREATE TABLE txns (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      walletId INTEGER,
      amount REAL,
      type TEXT,
      categoryKey TEXT,
      note TEXT,
      date TEXT,
      FOREIGN KEY(walletId) REFERENCES wallets(id),
      FOREIGN KEY(categoryKey) REFERENCES categories(key)
    );
    ''');
    await db.execute('''
    CREATE TABLE recurrings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      walletId INTEGER,
      amount REAL,
      type TEXT,
      category TEXT,
      note TEXT,
      startDate TEXT,
      interval TEXT,
      intervalCount INTEGER,
      nextRun TEXT,
      active INTEGER
    );
    ''');
    await db.execute('''
    CREATE TABLE budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      categoryKey TEXT,
      amount REAL,
      period TEXT,
      month INTEGER,
      year INTEGER
    );
    ''');
  }

  Future _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      // previous upgrade handled earlier
      await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE,
        name TEXT,
        icon TEXT,
        colorValue INTEGER
      );
      ''');
      await db.execute('''
      ALTER TABLE txns ADD COLUMN categoryKey TEXT;
      ''');
    }
    if (oldV < 3) {
      await db.execute('''
      CREATE TABLE recurrings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        walletId INTEGER,
        amount REAL,
        type TEXT,
        category TEXT,
        note TEXT,
        startDate TEXT,
        interval TEXT,
        intervalCount INTEGER,
        nextRun TEXT,
        active INTEGER
      );
      ''');
      await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryKey TEXT,
        amount REAL,
        period TEXT,
        month INTEGER,
        year INTEGER
      );
      ''');
    }
  }

  Future<void> _seedCategories() async {
    final db = _db!;
    final res = await db.query('categories', limit: 1);
    if (res.isNotEmpty) return;
    final presets = [
      CategoryModel(key: 'bbm', name: 'BBM', icon: 'local_gas_station', colorValue: 0xFF2E7D32),
      CategoryModel(key: 'galon', name: 'Galon Air', icon: 'local_drink', colorValue: 0xFF0288D1),
      CategoryModel(key: 'listrik', name: 'Listrik', icon: 'electrical_services', colorValue: 0xFFF57C00),
      CategoryModel(key: 'gas', name: 'Gas', icon: 'fire_extinguisher', colorValue: 0xFFD32F2F),
      CategoryModel(key: 'umum', name: 'Umum', icon: 'category', colorValue: 0xFF616161),
    ];
    for (var p in presets) {
      await db.insert('categories', p.toMap());
    }
  }

  // Wallet CRUD
  Future<int> insertWallet(WalletModel w) async {
    final db = _db!;
    return await db.insert('wallets', w.toMap());
  }

  Future<int> updateWallet(WalletModel w) async {
    final db = _db!;
    return await db.update('wallets', w.toMap(), where: 'id = ?', whereArgs: [w.id]);
  }

  Future<int> deleteWallet(int id) async {
    final db = _db!;
    await db.delete('txns', where: 'walletId = ?', whereArgs: [id]); // delete txns first
    return await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<WalletModel>> getWallets() async {
    final db = _db!;
    final res = await db.query('wallets', orderBy: 'id DESC');
    return res.map((e) => WalletModel.fromMap(e)).toList();
  }

  // Category
  Future<List<CategoryModel>> getCategories() async {
    final db = _db!;
    final res = await db.query('categories', orderBy: 'id ASC');
    return res.map((e) => CategoryModel.fromMap(e)).toList();
  }

  // Transaction CRUD with filters & pagination
  Future<int> insertTxn(TxnModel t) async {
    final db = _db!;
    final id = await db.insert('txns', t.toMap());
    // Update wallet balance
    final wallet = (await db.query('wallets', where: 'id = ?', whereArgs: [t.walletId])).first;
    double bal = (wallet['balance'] as num).toDouble();
    bal += (t.type == 'in') ? t.amount : -t.amount;
    await db.update('wallets', {'balance': bal}, where: 'id = ?', whereArgs: [t.walletId]);
    return id;
  }

  Future<int> updateTxn(TxnModel t) async {
    final db = _db!;
    if (t.id == null) throw Exception('Transaction id is null');
    // get old txn
    final oldRes = await db.query('txns', where: 'id = ?', whereArgs: [t.id]);
    if (oldRes.isEmpty) throw Exception('Transaction not found');
    final old = TxnModel.fromMap(oldRes.first);
    // revert old transaction balance on its wallet
    final oldWalletRow = (await db.query('wallets', where: 'id = ?', whereArgs: [old.walletId])).first;
    double oldBal = (oldWalletRow['balance'] as num).toDouble();
    // revert: if old.type == 'in' then subtract old.amount else add old.amount
    oldBal -= (old.type == 'in') ? old.amount : -old.amount;
    await db.update('wallets', {'balance': oldBal}, where: 'id = ?', whereArgs: [old.walletId]);

    // apply new transaction to target wallet
    final newWalletRow = (await db.query('wallets', where: 'id = ?', whereArgs: [t.walletId])).first;
    double newBal = (newWalletRow['balance'] as num).toDouble();
    newBal += (t.type == 'in') ? t.amount : -t.amount;
    await db.update('wallets', {'balance': newBal}, where: 'id = ?', whereArgs: [t.walletId]);

    return await db.update('txns', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<int> deleteTxn(int id) async {
    final db = _db!;
    final t = (await db.query('txns', where: 'id = ?', whereArgs: [id])).first;
    final txn = TxnModel.fromMap(t);
    // revert wallet balance
    final wallet = (await db.query('wallets', where: 'id = ?', whereArgs: [txn.walletId])).first;
    double bal = (wallet['balance'] as num).toDouble();
    bal -= (txn.type == 'in') ? txn.amount : -txn.amount;
    await db.update('wallets', {'balance': bal}, where: 'id = ?', whereArgs: [txn.walletId]);
    return await db.delete('txns', where: 'id = ?', whereArgs: [id]);
  }

  // getTxns with filters and pagination
  Future<List<TxnModel>> getTxns({
    int? walletId,
    String? type, // 'in' or 'out'
    String? categoryKey,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? limit,
    int? offset,
  }) async {
    final db = _db!;
    var whereClauses = <String>[];
    var args = <dynamic>[];

    if (walletId != null) {
      whereClauses.add('walletId = ?');
      args.add(walletId);
    }
    if (type != null) {
      whereClauses.add('type = ?');
      args.add(type);
    }
    if (categoryKey != null) {
      whereClauses.add('categoryKey = ?');
      args.add(categoryKey);
    }
    if (dateFrom != null) {
      whereClauses.add('date >= ?');
      args.add(dateFrom.toIso8601String());
    }
    if (dateTo != null) {
      whereClauses.add('date <= ?');
      args.add(dateTo.toIso8601String());
    }
    final whereStr = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final res = await db.query(
      'txns',
      where: whereStr,
      whereArgs: args,
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );
    return res.map((e) => TxnModel.fromMap(e)).toList();
  }

  Future<int> countTxns({
    int? walletId,
    String? type,
    String? categoryKey,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final db = _db!;
    var whereClauses = <String>[];
    var args = <dynamic>[];

    if (walletId != null) {
      whereClauses.add('walletId = ?');
      args.add(walletId);
    }
    if (type != null) {
      whereClauses.add('type = ?');
      args.add(type);
    }
    if (categoryKey != null) {
      whereClauses.add('categoryKey = ?');
      args.add(categoryKey);
    }
    if (dateFrom != null) {
      whereClauses.add('date >= ?');
      args.add(dateFrom.toIso8601String());
    }
    if (dateTo != null) {
      whereClauses.add('date <= ?');
      args.add(dateTo.toIso8601String());
    }
    final whereStr = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final res = await db.rawQuery('SELECT COUNT(*) as c FROM txns' + (whereStr != null ? ' WHERE $whereStr' : ''), args);
    return (res.first['c'] as int);
  }

  // cashflow grouped by day (existing)
  Future<List<Map<String, dynamic>>> cashflowGroupedByDay({int days = 30}) async {
    final db = _db!;
    final now = DateTime.now();
    final from = now.subtract(Duration(days: days - 1));
    final res = await db.rawQuery('''
      SELECT date(substr(date,1,10)) as d, 
             SUM(CASE WHEN type='in' THEN amount ELSE -amount END) as total
      FROM txns
      WHERE date BETWEEN ? AND ?
      GROUP BY d
      ORDER BY d ASC
    ''', [from.toIso8601String(), now.toIso8601String()]);
    return res;
  }

  // monthly report: sum per category & totals
  Future<Map<String, dynamic>> monthlyReport(int year, int month, {int? walletId}) async {
    final db = _db!;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1).subtract(const Duration(seconds: 1));
    List<Object?> args = [
      start.toIso8601String(),
      end.toIso8601String(),
    ];
    var whereExtra = '';
    if (walletId != null) {
      whereExtra = ' AND walletId = ?';
      args.add(walletId);
    }
    final rows = await db.rawQuery('''
      SELECT categoryKey, 
             SUM(CASE WHEN type='in' THEN amount ELSE 0 END) as total_in,
             SUM(CASE WHEN type='out' THEN amount ELSE 0 END) as total_out
      FROM txns
      WHERE date BETWEEN ? AND ? $whereExtra
      GROUP BY categoryKey
    ''', args);

    double totalIn = 0, totalOut = 0;
    Map<String, Map<String, double>> perCat = {};
    for (var r in rows) {
      final key = r['categoryKey'] as String? ?? 'umum';
      final tin = (r['total_in'] as num?)?.toDouble() ?? 0.0;
      final tout = (r['total_out'] as num?)?.toDouble() ?? 0.0;
      totalIn += tin;
      totalOut += tout;
      perCat[key] = {'in': tin, 'out': tout};
    }
    return {
      'year': year,
      'month': month,
      'total_in': totalIn,
      'total_out': totalOut,
      'per_category': perCat,
    };
  }

  // Recurring CRUD & helpers
  Future<int> insertRecurring(RecurringModel r) async {
    final db = _db!;
    return await db.insert('recurrings', r.toMap());
  }

  Future<int> updateRecurring(RecurringModel r) async {
    final db = _db!;
    return await db.update('recurrings', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
  }

  Future<int> deleteRecurring(int id) async {
    final db = _db!;
    return await db.delete('recurrings', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<RecurringModel>> getRecurrings({bool onlyActive = false}) async {
    final db = _db!;
    final res = onlyActive ? await db.query('recurrings', where: 'active = 1') : await db.query('recurrings');
    return res.map((e) => RecurringModel.fromMap(e)).toList();
  }

  Future<List<RecurringModel>> getDueRecurrings(DateTime before) async {
    final db = _db!;
    final res = await db.query('recurrings', where: 'active = 1 AND nextRun <= ?', whereArgs: [before.toIso8601String()]);
    return res.map((e) => RecurringModel.fromMap(e)).toList();
  }

  // Advance nextRun based on interval
  DateTime _advanceNextRun(DateTime from, String interval, int count) {
    switch (interval) {
      case 'daily':
        return DateTime(from.year, from.month, from.day).add(Duration(days: 1 * count));
      case 'weekly':
        return from.add(Duration(days: 7 * count));
      case 'monthly':
      default:
        return DateTime(from.year, from.month + count, from.day);
    }
  }

  Future<void> advanceRecurringNextRun(int id, int intervalCount, String interval) async {
    final db = _db!;
    final res = await db.query('recurrings', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return;
    final r = RecurringModel.fromMap(res.first);
    DateTime next = _advanceNextRun(r.nextRun, interval, intervalCount);
    await db.update('recurrings', {'nextRun': next.toIso8601String()}, where: 'id = ?', whereArgs: [id]);
  }

  // Budgets CRUD
  Future<int> insertBudget(BudgetModel b) async {
    final db = _db!;
    return await db.insert('budgets', b.toMap());
  }

  Future<int> updateBudget(BudgetModel b) async {
    final db = _db!;
    return await db.update('budgets', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }

  Future<int> deleteBudget(int id) async {
    final db = _db!;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BudgetModel>> getBudgets() async {
    final db = _db!;
    final res = await db.query('budgets', orderBy: 'id DESC');
    return res.map((e) => BudgetModel.fromMap(e)).toList();
  }

  // Calculate spending for category in year/month (pengeluaran only)
  Future<double> categorySpendingForMonth(String categoryKey, int year, int month) async {
    final db = _db!;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1).subtract(const Duration(seconds: 1));
    final res = await db.rawQuery('''
      SELECT SUM(amount) as total FROM txns
      WHERE categoryKey = ? AND type = 'out' AND date BETWEEN ? AND ?
    ''', [categoryKey, start.toIso8601String(), end.toIso8601String()]);
    final val = res.first['total'];
    return (val == null) ? 0.0 : (val as num).toDouble();
  }
}
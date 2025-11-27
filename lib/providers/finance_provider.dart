import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class FinanceProvider extends ChangeNotifier {
  final Box _box;
  List<TransactionModel> _transactions = [];

  FinanceProvider(this._box) {
    _load();
  }

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  Future<void> _load() async {
    _transactions = _box.values.cast<TransactionModel>().toList();
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel t) async {
    await _box.put(t.id, t);
    _transactions.insert(0, t);
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _box.delete(id);
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  double get totalIncome =>
      _transactions.where((t) => !t.isExpense).fold(0.0, (p, t) => p + t.amount);

  double get totalExpense =>
      _transactions.where((t) => t.isExpense).fold(0.0, (p, t) => p + t.amount);

  double get balance => totalIncome - totalExpense;

  // Return last N months cashflow (expense negative)
  Map<String, double> monthlyCashflow({int months = 6}) {
    final now = DateTime.now();
    Map<String, double> data = {};
    for (int i = months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM yy').format(m);
      data[key] = 0.0;
    }
    for (var t in _transactions) {
      final key = DateFormat('MMM yy').format(DateTime(t.date.year, t.date.month, 1));
      if (data.containsKey(key)) {
        data[key] = data[key]! + (t.isExpense ? -t.amount : t.amount);
      }
    }
    return data;
  }
}
// providers/budget_provider.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/budget.dart';

class BudgetProvider extends ChangeNotifier {
  List<BudgetModel> _list = [];

  List<BudgetModel> get list => _list;

  BudgetProvider() {
    load();
  }

  Future<void> load() async {
    _list = await DBHelper.instance.getBudgets();
    notifyListeners();
  }

  Future<void> add(BudgetModel b) async {
    await DBHelper.instance.insertBudget(b);
    await load();
  }

  Future<void> update(BudgetModel b) async {
    await DBHelper.instance.updateBudget(b);
    await load();
  }

  Future<void> delete(int id) async {
    await DBHelper.instance.deleteBudget(id);
    await load();
  }

  Future<double> spendingForMonth(String categoryKey, int year, int month) async {
    return await DBHelper.instance.categorySpendingForMonth(categoryKey, year, month);
  }
}
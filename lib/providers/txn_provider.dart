// providers/txn_provider.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/txn.dart';

class TxnProvider extends ChangeNotifier {
  List<TxnModel> _txns = [];
  int _totalCount = 0;

  List<TxnModel> get txns => _txns;
  int get totalCount => _totalCount;

  TxnProvider() {
    // initial load is triggered by screens with desired filters/pagination
  }

  Future<void> load({
    int? walletId,
    String? type,
    String? categoryKey,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? limit,
    int? offset,
  }) async {
    _txns = await DBHelper.instance.getTxns(
      walletId: walletId,
      type: type,
      categoryKey: categoryKey,
      dateFrom: dateFrom,
      dateTo: dateTo,
      limit: limit,
      offset: offset,
    );
    _totalCount = await DBHelper.instance.countTxns(
      walletId: walletId,
      type: type,
      categoryKey: categoryKey,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    notifyListeners();
  }

  Future<void> addTxn(TxnModel t) async {
    await DBHelper.instance.insertTxn(t);
    notifyListeners();
  }

  Future<void> updateTxn(TxnModel t) async {
    await DBHelper.instance.updateTxn(t);
    notifyListeners();
  }

  Future<void> deleteTxn(int id) async {
    await DBHelper.instance.deleteTxn(id);
    notifyListeners();
  }
}
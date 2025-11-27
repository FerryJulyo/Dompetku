// providers/wallet_provider.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/wallet.dart';

class WalletProvider extends ChangeNotifier {
  List<WalletModel> _wallets = [];
  // bool _inited = false;

  List<WalletModel> get wallets => _wallets;

  WalletProvider() {
    load();
  }

  Future<void> load() async {
    _wallets = await DBHelper.instance.getWallets();
    // _inited = true;
    notifyListeners();
  }

  Future<void> addWallet(WalletModel w) async {
    await DBHelper.instance.insertWallet(w);
    await load();
  }

  Future<void> updateWallet(WalletModel w) async {
    await DBHelper.instance.updateWallet(w);
    await load();
  }

  Future<void> deleteWallet(int id) async {
    await DBHelper.instance.deleteWallet(id);
    await load();
  }

  double totalBalance() {
    return _wallets.fold(0.0, (p, e) => p + e.balance);
  }
}
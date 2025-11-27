// providers/recurring_provider.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/recurring.dart';
import '../models/txn.dart';
import '../utils/notify_service.dart';

class RecurringProvider extends ChangeNotifier {
  List<RecurringModel> _list = [];

  List<RecurringModel> get list => _list;

  RecurringProvider() {
    load();
  }

  Future<void> load() async {
    _list = await DBHelper.instance.getRecurrings();
    notifyListeners();
  }

  Future<void> add(RecurringModel r) async {
    await DBHelper.instance.insertRecurring(r);
    await load();
    // schedule notification for nextRun
    await NotifyService().scheduleRecurringNotification(r);
  }

  Future<void> update(RecurringModel r) async {
    await DBHelper.instance.updateRecurring(r);
    await load();
    await NotifyService().scheduleRecurringNotification(r);
  }

  Future<void> delete(int id) async {
    await DBHelper.instance.deleteRecurring(id);
    await load();
    await NotifyService().cancelNotification(id);
  }

  // Process due recurrings: create txns for due items up to 'before' time
  Future<void> processDue({DateTime? before}) async {
    final now = DateTime.now();
    final dueBefore = before ?? now;
    final due = await DBHelper.instance.getDueRecurrings(dueBefore);
    for (var r in due) {
      // create txn
      final txn = TxnModel(
        walletId: r.walletId,
        amount: r.amount,
        type: r.type,
        category: r.category,
        note: r.note + ' (recurring)',
        date: r.nextRun,
      );
      await DBHelper.instance.insertTxn(txn);
      // advance nextRun until it's after now
      DateTime next = r.nextRun;
      do {
        next = DBHelper.instance._advanceNextRun(next, r.interval, r.intervalCount);
      } while (!next.isAfter(dueBefore));
      r.nextRun = next;
      await DBHelper.instance.updateRecurring(r);
      // schedule notification for nextRun
      await NotifyService().scheduleRecurringNotification(r);
    }
    await load();
  }
}
// widgets/txn_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/txn.dart';

class TxnTile extends StatelessWidget {
  final TxnModel txn;
  const TxnTile({super.key, required this.txn});

  @override
  Widget build(BuildContext context) {
    final oCcy = NumberFormat.simpleCurrency(locale: 'id_ID', name: 'IDR', decimalDigits: 0);
    final sign = txn.type == 'in' ? '+' : '-';
    return ListTile(
      leading: CircleAvatar(child: Text(txn.category[0].toUpperCase())),
      title: Text(txn.category),
      subtitle: Text(txn.note),
      trailing: Text('$sign${oCcy.format(txn.amount)}', style: TextStyle(color: txn.type == 'in' ? Colors.green : Colors.red)),
    );
  }
}
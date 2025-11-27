import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel t;
  final VoidCallback onDelete;

  const TransactionTile({Key? key, required this.t, required this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Dismissible(
      key: Key(t.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: t.isExpense ? Colors.red.shade100 : Colors.green.shade100,
          child: Icon(t.isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: t.isExpense ? Colors.red : Colors.green),
        ),
        title: Text(t.title),
        subtitle: Text('${t.category} • ${DateFormat.yMMMd().format(t.date)}'),
        trailing: Text(
          (t.isExpense ? '-' : '+') + fmt.format(t.amount),
          style: TextStyle(color: t.isExpense ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
// screens/recurring_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/category_provider.dart';
import '../models/recurring.dart';
import 'add_recurring_screen.dart';
import 'package:intl/intl.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<RecurringProvider>(context, listen: false).load();
  }

  @override
  Widget build(BuildContext context) {
    final rp = Provider.of<RecurringProvider>(context);
    final cp = Provider.of<CategoryProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Transactions')),
      body: rp.list.isEmpty ? const Center(child: Text('Belum ada recurring')) : ListView.separated(
        itemCount: rp.list.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (c, i) {
          final r = rp.list[i];
          final cat = cp.findByKey(r.category);
          return ListTile(
            leading: CircleAvatar(child: Text(cat?.name[0] ?? 'R')),
            title: Text('${cat?.name ?? r.category} - ${r.type == 'in' ? '+' : '-'}${r.amount}'),
            subtitle: Text('Next: ${DateFormat.yMMMd().add_jm().format(r.nextRun)} • Every ${r.intervalCount} ${r.interval}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddRecurringScreen(editing: r)));
                await rp.load();
              }),
              IconButton(icon: const Icon(Icons.delete), onPressed: () async {
                await rp.delete(r.id!);
              }),
            ]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddRecurringScreen()));
          await rp.load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
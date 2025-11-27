// screens/budget_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import 'add_budget_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    Provider.of<BudgetProvider>(context, listen: false).load();
  }

  @override
  Widget build(BuildContext context) {
    final bp = Provider.of<BudgetProvider>(context);
    final cp = Provider.of<CategoryProvider>(context);
    final nf = NumberFormat.simpleCurrency(locale: 'id_ID', name: 'IDR', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: Column(
        children: [
          Row(children: [
            DropdownButton<int>(value: _month, items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(value: m, child: Text(DateFormat.MMMM().format(DateTime(2020, m))))).toList(), onChanged: (v) {
              setState(() => _month = v!);
            }),
            const SizedBox(width: 8),
            DropdownButton<int>(value: _year, items: List.generate(5, (i) => DateTime.now().year - i).map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(), onChanged: (v) {
              setState(() => _year = v!);
            })
          ]),
          Expanded(
            child: ListView.separated(
              itemCount: bp.list.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (c, i) {
                final b = bp.list[i];
                final cat = cp.findByKey(b.categoryKey);
                return FutureBuilder<double>(
                  future: bp.spendingForMonth(b.categoryKey, _year, _month),
                  builder: (context, snap) {
                    final spent = snap.data ?? 0.0;
                    final over = spent > b.amount;
                    return ListTile(
                      leading: CircleAvatar(child: Text(cat?.name[0] ?? 'B')),
                      title: Text(cat?.name ?? b.categoryKey),
                      subtitle: Text('Budget: ${nf.format(b.amount)} • Spent: ${nf.format(spent)}'),
                      trailing: over ? const Icon(Icons.warning, color: Colors.red) : const Icon(Icons.check, color: Colors.green),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddBudgetScreen(editing: b)));
                        await bp.load();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddBudgetScreen()));
        await bp.load();
      }, child: const Icon(Icons.add)),
    );
  }
}
// screens/add_budget_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/budget.dart';
import '../providers/category_provider.dart';
import '../providers/budget_provider.dart';

class AddBudgetScreen extends StatefulWidget {
  final BudgetModel? editing;
  const AddBudgetScreen({super.key, this.editing});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _form = GlobalKey<FormState>();
  String _categoryKey = 'umum';
  double _amount = 0;
  String _period = 'monthly';
  int _month = 0;
  int _year = 0;

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _categoryKey = widget.editing!.categoryKey;
      _amount = widget.editing!.amount;
      _period = widget.editing!.period;
      _month = widget.editing!.month;
      _year = widget.editing!.year;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = Provider.of<CategoryProvider>(context).categories;
    return Scaffold(
      appBar: AppBar(title: Text(widget.editing == null ? 'Tambah Budget' : 'Edit Budget')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _form,
          child: Column(
            children: [
              DropdownButtonFormField<String>(value: _categoryKey, items: cats.map((c) => DropdownMenuItem(value: c.key, child: Text(c.name))).toList(), onChanged: (v) => setState(() => _categoryKey = v!)),
              TextFormField(initialValue: _amount == 0 ? '' : _amount.toString(), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah Budget'), validator: (v) => (v == null || double.tryParse(v) == null) ? 'Isi angka' : null, onSaved: (v) => _amount = double.parse(v!)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () async {
                if (!_form.currentState!.validate()) return;
                _form.currentState!.save();
                final b = BudgetModel(id: widget.editing?.id, categoryKey: _categoryKey, amount: _amount, period: _period, month: _month, year: _year);
                final bp = Provider.of<BudgetProvider>(context, listen: false);
                if (widget.editing == null) await bp.add(b); else await bp.update(b);
                if (mounted) Navigator.of(context).pop();
              }, child: Text(widget.editing == null ? 'Simpan' : 'Update'))
            ],
          ),
        ),
      ),
    );
  }
}
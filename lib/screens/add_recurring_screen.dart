// screens/add_recurring_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/recurring.dart';
import '../providers/wallet_provider.dart';
import '../providers/category_provider.dart';
import '../providers/recurring_provider.dart';

class AddRecurringScreen extends StatefulWidget {
  final RecurringModel? editing;
  const AddRecurringScreen({super.key, this.editing});

  @override
  State<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends State<AddRecurringScreen> {
  final _form = GlobalKey<FormState>();
  double _amount = 0;
  String _type = 'out';
  String _categoryKey = 'umum';
  String _note = '';
  DateTime _startDate = DateTime.now();
  String _interval = 'monthly';
  int _intervalCount = 1;
  int? _walletId;

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      final e = widget.editing!;
      _amount = e.amount;
      _type = e.type;
      _categoryKey = e.category;
      _note = e.note;
      _startDate = e.startDate;
      _interval = e.interval;
      _intervalCount = e.intervalCount;
      _walletId = e.walletId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = Provider.of<WalletProvider>(context).wallets;
    final cats = Provider.of<CategoryProvider>(context).categories;
    if (_walletId == null && wallets.isNotEmpty) _walletId = wallets.first.id;

    return Scaffold(
      appBar: AppBar(title: Text(widget.editing == null ? 'Tambah Recurring' : 'Edit Recurring')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _form,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _walletId,
                decoration: const InputDecoration(labelText: 'Wallet'),
                items: wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                onChanged: (v) => setState(() => _walletId = v),
              ),
              TextFormField(
                initialValue: _amount == 0 ? '' : _amount.toString(),
                decoration: const InputDecoration(labelText: 'Jumlah'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Isi jumlah valid' : null,
                onSaved: (v) => _amount = double.parse(v!),
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      items: const [
                        DropdownMenuItem(value: 'in', child: Text('Pemasukan')),
                        DropdownMenuItem(value: 'out', child: Text('Pengeluaran')),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                      decoration: const InputDecoration(labelText: 'Tipe'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _categoryKey,
                      items: cats.map((c) => DropdownMenuItem(value: c.key, child: Text(c.name))).toList(),
                      onChanged: (v) => setState(() => _categoryKey = v!),
                      decoration: const InputDecoration(labelText: 'Kategori'),
                    ),
                  ),
                ],
              ),
              TextFormField(
                initialValue: _note,
                decoration: const InputDecoration(labelText: 'Catatan'),
                onChanged: (v) => _note = v,
              ),
              Row(
                children: [
                  const Text('Mulai:'),
                  TextButton(onPressed: () async {
                    final d = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDate: _startDate);
                    if (d != null) setState(() => _startDate = d);
                  }, child: Text(DateFormat.yMMMd().format(_startDate))),
                ],
              ),
              Row(
                children: [
                  Expanded(child: DropdownButtonFormField<String>(value: _interval, items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Harian')),
                    DropdownMenuItem(value: 'weekly', child: Text('Mingguan')),
                    DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
                  ], onChanged: (v) => setState(() => _interval = v!), decoration: const InputDecoration(labelText: 'Interval'))),
                  const SizedBox(width: 8),
                  SizedBox(width: 100, child: TextFormField(initialValue: _intervalCount.toString(), keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Setiap'), onChanged: (v) => _intervalCount = int.tryParse(v) ?? 1)),
                ],
              ),
              const Spacer(),
              ElevatedButton(onPressed: () async {
                if (!_form.currentState!.validate()) return;
                _form.currentState!.save();
                if (_walletId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih wallet')));
                  return;
                }
                final r = RecurringModel(
                  id: widget.editing?.id,
                  walletId: _walletId!,
                  amount: _amount,
                  type: _type,
                  category: _categoryKey,
                  note: _note,
                  startDate: _startDate,
                  interval: _interval,
                  intervalCount: _intervalCount,
                  nextRun: _startDate,
                  active: true,
                );
                final rp = Provider.of<RecurringProvider>(context, listen: false);
                if (widget.editing == null) {
                  await rp.add(r);
                } else {
                  await rp.update(r);
                }
                if (mounted) Navigator.of(context).pop();
              }, child: Text(widget.editing == null ? 'Simpan' : 'Update')),
            ],
          ),
        ),
      ),
    );
  }
}
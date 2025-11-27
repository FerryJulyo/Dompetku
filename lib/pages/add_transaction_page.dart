import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({Key? key}) : super(key: key);

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  double _amount = 0;
  bool _isExpense = true;
  DateTime _date = DateTime.now();
  String _category = 'Umum';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Material(
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Judul'),
                  onSaved: (v) => _title = v?.trim() ?? '',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Masukkan judul' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Jumlah', prefixText: 'Rp '),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => _amount = double.tryParse(v?.replaceAll(',', '') ?? '') ?? 0,
                  validator: (v) {
                    final val = double.tryParse(v?.replaceAll(',', '') ?? '');
                    if (val == null || val <= 0) return 'Masukkan jumlah valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<bool>(
                        value: _isExpense,
                        items: const [
                          DropdownMenuItem(value: true, child: Text('Pengeluaran')),
                          DropdownMenuItem(value: false, child: Text('Pemasukan')),
                        ],
                        onChanged: (v) => setState(() => _isExpense = v ?? true),
                        decoration: const InputDecoration(labelText: 'Tipe'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: _category,
                        decoration: const InputDecoration(labelText: 'Kategori'),
                        onSaved: (v) => _category = v?.trim() ?? 'Umum',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanggal'),
                  subtitle: Text('${_date.toLocal()}'.split(' ')[0]),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100));
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: _submit,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Simpan'),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final id = const Uuid().v4();
    final tx = TransactionModel(
        id: id, title: _title, amount: _amount, date: _date, isExpense: _isExpense, category: _category);
    final prov = Provider.of<FinanceProvider>(context, listen: false);
    prov.addTransaction(tx);
    Navigator.of(context).pop();
  }
}
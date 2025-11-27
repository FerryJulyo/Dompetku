// screens/add_txn_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/txn.dart';
import '../providers/wallet_provider.dart';
import '../providers/txn_provider.dart';
// import '../models/wallet.dart';
import '../providers/category_provider.dart';
// import '../models/category.dart';

class AddTxnScreen extends StatefulWidget {
  final TxnModel? editing; // if provided, we edit existing txn
  const AddTxnScreen({super.key, this.editing});

  @override
  State<AddTxnScreen> createState() => _AddTxnScreenState();
}

class _AddTxnScreenState extends State<AddTxnScreen> {
  final _form = GlobalKey<FormState>();
  double _amount = 0;
  String _type = 'out';
  String _categoryKey = 'umum';
  String _note = '';
  DateTime _date = DateTime.now();
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
      _date = e.date;
      _walletId = e.walletId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = Provider.of<WalletProvider>(context).wallets;
    final cats = Provider.of<CategoryProvider>(context).categories;
    if (_walletId == null && wallets.isNotEmpty) _walletId = wallets.first.id;

    return Scaffold(
      appBar: AppBar(title: Text(widget.editing == null ? 'Tambah Transaksi' : 'Edit Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              // Wallet selector
              DropdownButtonFormField<int>(
                value: _walletId,
                decoration: const InputDecoration(labelText: 'Pilih Wallet'),
                items: wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                onChanged: (v) => setState(() => _walletId = v),
              ),
              TextFormField(
                initialValue: _amount == 0 ? '' : _amount.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah'),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Isi jumlah valid' : null,
                onSaved: (v) => _amount = double.parse(v!),
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'Tipe'),
                      items: const [
                        DropdownMenuItem(value: 'in', child: Text('Pemasukan')),
                        DropdownMenuItem(value: 'out', child: Text('Pengeluaran')),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _categoryKey,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: cats.map((c) => DropdownMenuItem(value: c.key, child: Text(c.name))).toList(),
                      onChanged: (v) => setState(() => _categoryKey = v!),
                    ),
                  )
                ],
              ),
              TextFormField(
                initialValue: _note,
                decoration: const InputDecoration(labelText: 'Catatan'),
                onChanged: (v) => _note = v,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Tanggal: '),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                    child: Text(DateFormat.yMMMd().format(_date)),
                  )
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  _form.currentState!.save();
                  if (_walletId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih wallet dulu')));
                    return;
                  }
                  final txn = TxnModel(
                    id: widget.editing?.id,
                    walletId: _walletId!,
                    amount: _amount,
                    type: _type,
                    category: _categoryKey,
                    note: _note,
                    date: _date,
                  );
                  final tp = Provider.of<TxnProvider>(context, listen: false);
                  if (widget.editing == null) {
                    await tp.addTxn(txn);
                  } else {
                    await tp.updateTxn(txn);
                  }
                  await Provider.of<WalletProvider>(context, listen: false).load();
                  if (mounted) Navigator.of(context).pop();
                },
                child: Text(widget.editing == null ? 'Simpan Transaksi' : 'Update Transaksi'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
// screens/add_wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wallet.dart';
import '../providers/wallet_provider.dart';

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _balanceCtl = TextEditingController(text: '0');
  Color _color = Colors.teal;
  String _icon = 'local_gas_station';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Nama Wallet'),
                validator: (v) => (v == null || v.isEmpty) ? 'Isi nama wallet' : null,
              ),
              TextFormField(
                controller: _balanceCtl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Saldo awal'),
                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Isi saldo valid' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Warna:'),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      // simple cycle of colors
                      final colors = [Colors.teal, Colors.blue, Colors.orange, Colors.purple, Colors.green];
                      int currentIndex = colors.indexWhere((c) => c.value == _color.value);
                      if (currentIndex == -1) currentIndex = 0;

                      final idx = (currentIndex + 1) % colors.length;
                      setState(() => _color = colors[idx]);
                    },
                    child: CircleAvatar(backgroundColor: _color),
                  ),
                  const SizedBox(width: 16),
                  const Text('Icon:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _icon,
                    items: const [
                      DropdownMenuItem(value: 'local_gas_station', child: Icon(Icons.local_gas_station)),
                      DropdownMenuItem(value: 'local_drink', child: Icon(Icons.local_drink)),
                      DropdownMenuItem(value: 'electric_bolt', child: Icon(Icons.electric_bolt)),
                      DropdownMenuItem(value: 'account_balance_wallet', child: Icon(Icons.account_balance_wallet)),
                    ],
                    onChanged: (v) => setState(() => _icon = v!),
                  )
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  final w = WalletModel(
                    name: _nameCtl.text,
                    balance: double.parse(_balanceCtl.text),
                    colorValue: _color.value,
                    icon: _icon,
                  );
                  await Provider.of<WalletProvider>(context, listen: false).addWallet(w);
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('Simpan Wallet'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
// screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/txn_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/category_provider.dart';
import '../models/txn.dart';
import 'add_txn_screen.dart';
import '../models/category.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _page = 0;
  final int _pageSize = 20;
  int? _walletId;
  String? _type; // in/out/null
  String? _categoryKey;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Provider.of<TxnProvider>(context, listen: false).load(
      walletId: _walletId,
      type: _type,
      categoryKey: _categoryKey,
      dateFrom: _from,
      dateTo: _to,
      limit: _pageSize,
      offset: _page * _pageSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TxnProvider>(context);
    final wp = Provider.of<WalletProvider>(context);
    final cp = Provider.of<CategoryProvider>(context);
    final nf = NumberFormat.simpleCurrency(locale: 'id_ID', name: 'IDR', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Semua Transaksi')),
      body: Column(
        children: [
          // Filter row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              DropdownButton<int?>(
                value: _walletId,
                hint: const Text('Wallet'),
                items: [null, ...wp.wallets].map((w) {
                  return DropdownMenuItem<int?>(
                    value: w is int ? w : (w == null ? null : (w as dynamic).id),
                    child: Text(w == null ? 'Semua Wallet' : (w is int ? w.toString() : (w as dynamic).name)),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _walletId = v;
                    _page = 0;
                  });
                  _load();
                },
              ),
              DropdownButton<String?>(
                value: _type,
                hint: const Text('Tipe'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua')),
                  DropdownMenuItem(value: 'in', child: Text('Pemasukan')),
                  DropdownMenuItem(value: 'out', child: Text('Pengeluaran')),
                ],
                onChanged: (v) {
                  setState(() {
                    _type = v;
                    _page = 0;
                  });
                  _load();
                },
              ),
              DropdownButton<String?>(
                value: _categoryKey,
                hint: const Text('Kategori'),
                items: [null, ...cp.categories.map((c) => c.key)].map((k) {
                  return DropdownMenuItem(value: k, child: Text(k == null ? 'Semua' : cp.findByKey(k)!.name));
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _categoryKey = v;
                    _page = 0;
                  });
                  _load();
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDateRangePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (picked != null) {
                    setState(() {
                      _from = picked.start;
                      _to = picked.end;
                      _page = 0;
                    });
                    _load();
                  }
                },
                child: const Text('Tanggal'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _walletId = null;
                    _type = null;
                    _categoryKey = null;
                    _from = null;
                    _to = null;
                    _page = 0;
                  });
                  _load();
                },
                child: const Text('Reset'),
              )
            ]),
          ),
          const Divider(),
          Expanded(
            child: tp.txns.isEmpty
                ? const Center(child: Text('Belum ada transaksi'))
                : ListView.separated(
                    itemCount: tp.txns.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final t = tp.txns[i];
                      final cat = cp.findByKey(t.category);
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: Color(cat?.colorValue ?? 0xFF616161), child: Icon(_iconFromString(cat?.icon ?? 'category'))),
                        title: Text(cat?.name ?? t.category),
                        subtitle: Text('${t.note}\n${DateFormat.yMMMd().format(t.date)}'),
                        trailing: Text('${t.type == 'in' ? '+' : '-'}${nf.format(t.amount)}', style: TextStyle(color: t.type == 'in' ? Colors.green : Colors.red)),
                        isThreeLine: true,
                        onTap: () async {
                          // edit
                          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddTxnScreen(editing: t)));
                          await _load();
                        },
                      );
                    },
                  ),
          ),
          // Pagination controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Menampilkan ${tp.txns.length} dari ${tp.totalCount}'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _page == 0
                          ? null
                          : () {
                              setState(() {
                                _page--;
                              });
                              _load();
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: (_page + 1) * _pageSize >= tp.totalCount
                          ? null
                          : () {
                              setState(() {
                                _page++;
                              });
                              _load();
                            },
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddTxnScreen()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _iconFromString(String s) {
    switch (s) {
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'local_drink':
        return Icons.local_drink;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'fire_extinguisher':
        return Icons.fireplace;
      case 'category':
      default:
        return Icons.category;
    }
  }
}
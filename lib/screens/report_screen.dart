// screens/report_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../db/db_helper.dart';
import '../providers/category_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/export_util.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  int? _walletId;

  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await DBHelper.instance.monthlyReport(_year, _month, walletId: _walletId);
    setState(() => _report = r);
  }

  @override
  Widget build(BuildContext context) {
    final wp = Provider.of<WalletProvider>(context);
    final cp = Provider.of<CategoryProvider>(context);
    final nf = NumberFormat.simpleCurrency(locale: 'id_ID', name: 'IDR', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Bulanan')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              DropdownButton<int>(
                value: _month,
                items: List.generate(12, (i) {
                  final m = i + 1;
                  return DropdownMenuItem(value: m, child: Text(DateFormat.MMMM().format(DateTime(2020, m))));
                }),
                onChanged: (v) {
                  setState(() => _month = v!);
                  _load();
                },
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _year,
                items: List.generate(5, (i) => DateTime.now().year - i).map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                onChanged: (v) {
                  setState(() => _year = v!);
                  _load();
                },
              ),
              const SizedBox(width: 8),
              DropdownButton<int?>(
                value: _walletId,
                items: [null, ...wp.wallets].map((w) => DropdownMenuItem(value: w == null ? null : w.id, child: Text(w == null ? 'Semua Wallet' : w.name))).toList(),
                onChanged: (v) {
                  setState(() => _walletId = v);
                  _load();
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _report == null
                    ? null
                    : () async {
                        final bytes = await ExportUtil.generateReportPdf(_report!, cp);
                        await ExportUtil.saveAndSharePdf(bytes, 'laporan_${_year}_${_month}.pdf');
                      },
                child: const Text('Export PDF'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _report == null
                    ? null
                    : () async {
                        final path = await ExportUtil.exportReportCsv(_report!, cp);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV disimpan di: $path')));
                      },
                child: const Text('Export CSV'),
              ),
            ]),
            const SizedBox(height: 12),
            if (_report == null) const CircularProgressIndicator() else Expanded(child: _buildReportBody(_report!, cp, nf))
          ],
        ),
      ),
    );
  }

  Widget _buildReportBody(Map<String, dynamic> rep, CategoryProvider cp, NumberFormat nf) {
    final perCat = rep['per_category'] as Map<String, dynamic>;
    final keys = perCat.keys.toList();
    return ListView(
      children: [
        ListTile(title: Text('Periode: ${rep['month']}/${rep['year']}')),
        ListTile(title: Text('Total Pemasukan: ${nf.format(rep['total_in'])}')),
        ListTile(title: Text('Total Pengeluaran: ${nf.format(rep['total_out'])}')),
        const Divider(),
        ...keys.map((k) {
          final data = perCat[k] as Map;
          final cat = cp.findByKey(k);
          return ListTile(
            leading: CircleAvatar(backgroundColor: Color(cat?.colorValue ?? 0xFF616161), child: Icon(_iconFromString(cat?.icon ?? 'category'))),
            title: Text(cat?.name ?? k),
            subtitle: Text('In: ${nf.format(data['in'])}  Out: ${nf.format(data['out'])}'),
          );
        }).toList()
      ],
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
      default:
        return Icons.category;
    }
  }
}
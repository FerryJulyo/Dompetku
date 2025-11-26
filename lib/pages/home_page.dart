import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../widgets/animated_balance_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  List<FlSpot> _toSpots(List<double> values) {
    return List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<FinanceProvider>(context);
    final monthly = prov.monthlyCashflow(months: 6);
    final labels = monthly.keys.toList();
    final values = monthly.values.toList();
    final spots = _toSpots(values);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartWallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {},
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // just trigger UI refresh
          // provider already listens to Hive changes
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AnimatedBalanceCard(balance: prov.balance, income: prov.totalIncome, expense: prov.totalExpense),
            const SizedBox(height: 18),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Cashflow 6 bulan', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text('${labels.first} - ${labels.last}', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true, drawVerticalLine: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, meta) {
                                      final i = v.toInt();
                                      if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                                      return Text(labels[i], style: const TextStyle(fontSize: 10));
                                    }),
                              ),
                            ),
                            minY: values.reduce((a, b) => a < b ? a : b) - 50,
                            maxY: values.reduce((a, b) => a > b ? a : b) + 50,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                barWidth: 3,
                                belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.18)),
                                dotData: FlDotData(show: true),
                                color: Colors.blue,
                              )
                            ],
                          ),
                          swapAnimationDuration: const Duration(milliseconds: 800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: const [Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold))],
            ),
            const SizedBox(height: 8),
            prov.transactions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('Belum ada transaksi. Tambah sekarang!', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : Column(
                    children: prov.transactions.map((t) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: TransactionTile(t: t, onDelete: () => prov.deleteTransaction(t.id)),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
            PageRouteBuilder(pageBuilder: (c, a1, a2) => const AddTransactionPage(), transitionsBuilder: (c, a1, a2, child) {
              return FadeTransition(opacity: a1, child: child);
            })),
        child: const Icon(Icons.add),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedBalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const AnimatedBalanceCard({
    Key? key,
    required this.balance,
    required this.income,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Hero(
      tag: 'balance-card',
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: Column(
              key: ValueKey(balance),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saldo Anda', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: balance),
                  duration: const Duration(milliseconds: 900),
                  builder: (context, value, child) {
                    return Text(formatter.format(value),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold));
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _smallStat('Pemasukan', formatter.format(income), Colors.green),
                    const SizedBox(width: 12),
                    _smallStat('Pengeluaran', formatter.format(expense), Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
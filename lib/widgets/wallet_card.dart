// widgets/wallet_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';

class WalletCard extends StatelessWidget {
  final WalletModel wallet;
  const WalletCard({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    final oCcy = NumberFormat.compactSimpleCurrency(locale: 'id_ID', name: 'IDR');
    final color = Color(wallet.colorValue);
    final icon = _iconFromString(wallet.icon);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      width: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: Colors.white), const Spacer(), Text(wallet.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
          const Spacer(),
          Text(oCcy.format(wallet.balance), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  IconData _iconFromString(String s) {
    switch (s) {
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'local_drink':
        return Icons.local_drink;
      case 'electric_bolt':
        return Icons.electrical_services;
      case 'account_balance_wallet':
      default:
        return Icons.account_balance_wallet;
    }
  }
}
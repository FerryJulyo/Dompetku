// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';

import '../providers/wallet_provider.dart';
import '../providers/txn_provider.dart';
import '../widgets/wallet_card.dart';
import '../widgets/txn_tile.dart';
import '../widgets/cashflow_chart.dart';
import '../screens/add_wallet_screen.dart';
import '../screens/add_txn_screen.dart';
// import '../models/wallet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final oCcy = NumberFormat.simpleCurrency(locale: 'id_ID', name: 'IDR', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final wp = Provider.of<WalletProvider>(context, listen: false);
    final tp = Provider.of<TxnProvider>(context, listen: false);
    wp.load();
    tp.load();
  }

  @override
  Widget build(BuildContext context) {
    final wp = Provider.of<WalletProvider>(context);
    final tp = Provider.of<TxnProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoneyApp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              wp.load();
              tp.load();
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await wp.load();
          await tp.load();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total balance
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'total-balance',
                        child: CircleAvatar(
                          radius: 28,
                          child: const Icon(Icons.account_balance_wallet),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Saldo', style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(oCcy.format(wp.totalBalance()), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Wallet list horizontal
              SizedBox(
                height: 140,
                child: wp.wallets.isEmpty
                    ? Center(child: Text('Belum ada wallet. Tambah wallet baru.'))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, i) {
                          final w = wp.wallets[i];
                          return GestureDetector(
                            onTap: () async {
                              // reload txns for selected wallet
                              await Provider.of<TxnProvider>(context, listen: false).load(walletId: w.id);
                            },
                            child: WalletCard(wallet: w),
                          );
                        },
                        separatorBuilder: (c, i) => const SizedBox(width: 12),
                        itemCount: wp.wallets.length,
                      ),
              ),
              const SizedBox(height: 16),
              // Chart
              const Text('Cashflow (30 hari)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const CashflowChart(days: 30),
              const SizedBox(height: 16),
              // Transactions history
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('History Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  TextButton(
                      onPressed: () => Provider.of<TxnProvider>(context, listen: false).load(),
                      child: const Text('Semua')),
                ],
              ),
              const SizedBox(height: 8),
              tp.txns.isEmpty
                  ? const Center(child: Text('Belum ada transaksi'))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (c, i) => TxnTile(txn: tp.txns[i]),
                      separatorBuilder: (c, i) => const Divider(),
                      itemCount: tp.txns.length,
                    ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: OpenContainer(
        closedElevation: 6,
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (context, _) => const AddTxnScreen(),
        closedBuilder: (context, openContainer) => FloatingActionButton.extended(
          onPressed: openContainer,
          label: const Text('Tambah Transaksi'),
          icon: const Icon(Icons.add),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FloatingActionButton.small(
                heroTag: 'add_wallet',
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddWalletScreen()));
                },
                child: const Icon(Icons.account_balance_wallet_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Tambah wallet untuk kategori seperti BBM / Galon Air / Listrik / Gas')),
            ],
          ),
        ),
      ),
    );
  }
}
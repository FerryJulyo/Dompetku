// main.dart (modified)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/wallet_provider.dart';
import 'providers/txn_provider.dart';
import 'providers/category_provider.dart';
import 'providers/recurring_provider.dart';
import 'providers/budget_provider.dart';
import 'screens/home_screen.dart';
import 'db/db_helper.dart';
import 'utils/notify_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.instance.init(); // inisialisasi DB (v3)
  await NotifyService().init(); // inisialisasi notifikasi & timezone
  runApp(const MoneyApp());
}

class MoneyApp extends StatelessWidget {
  const MoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => TxnProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => RecurringProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
      ],
      child: MaterialApp(
        title: 'MoneyApp',
        theme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const StartupWrapper(),
      ),
    );
  }
}

class StartupWrapper extends StatefulWidget {
  const StartupWrapper({super.key});

  @override
  State<StartupWrapper> createState() => _StartupWrapperState();
}

class _StartupWrapperState extends State<StartupWrapper> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // process due recurrings on startup
    final rp = Provider.of<RecurringProvider>(context, listen: false);
    await rp.processDue();
    // load other providers
    await Provider.of<WalletProvider>(context, listen: false).load();
    await Provider.of<TxnProvider>(context, listen: false).load();
    await Provider.of<CategoryProvider>(context, listen: false).load();
    await Provider.of<BudgetProvider>(context, listen: false).load();
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return const HomeScreen();
  }
}
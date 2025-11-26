import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/transaction.dart';
import 'providers/finance_provider.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  final box = await Hive.openBox('transactionsBox');
  // ensure stored items are typed; if migrating from previous, ensure values are TransactionModel
  runApp(MyApp(box));
}

class MyApp extends StatelessWidget {
  final Box box;
  const MyApp(this.box, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinanceProvider(box),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SmartWallet',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
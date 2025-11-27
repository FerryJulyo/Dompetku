import 'package:hive/hive.dart';

part '../model/transaction.g.dart'; // not required if using manual adapter, kept for clarity

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  bool isExpense;

  @HiveField(5)
  String category;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.category,
  });
}

// Manual TypeAdapter (no build_runner needed)
class TransactionAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    final id = reader.readString();
    final title = reader.readString();
    final amount = reader.readDouble();
    final date = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final isExpense = reader.readBool();
    final category = reader.readString();
    return TransactionModel(
        id: id, title: title, amount: amount, date: date, isExpense: isExpense, category: category);
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeDouble(obj.amount);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeBool(obj.isExpense);
    writer.writeString(obj.category);
  }
}
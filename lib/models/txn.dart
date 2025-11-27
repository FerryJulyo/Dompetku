// models/txn.dart
class TxnModel {
  int? id;
  int walletId;
  double amount;
  String type; // "in" or "out"
  String category;
  String note;
  DateTime date;

  TxnModel({
    this.id,
    required this.walletId,
    required this.amount,
    required this.type,
    required this.category,
    required this.note,
    required this.date,
  });

  factory TxnModel.fromMap(Map<String, dynamic> m) => TxnModel(
        id: m['id'],
        walletId: m['walletId'],
        amount: (m['amount'] as num).toDouble(),
        type: m['type'],
        category: m['category'],
        note: m['note'],
        date: DateTime.parse(m['date']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'walletId': walletId,
        'amount': amount,
        'type': type,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
      };
}
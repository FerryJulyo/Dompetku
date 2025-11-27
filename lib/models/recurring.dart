// models/recurring.dart
class RecurringModel {
  int? id;
  int walletId;
  double amount;
  String type; // 'in' or 'out'
  String category; // categoryKey
  String note;
  DateTime startDate;
  String interval; // 'daily', 'weekly', 'monthly'
  int intervalCount; // e.g., every 2 weeks
  DateTime nextRun;
  bool active;

  RecurringModel({
    this.id,
    required this.walletId,
    required this.amount,
    required this.type,
    required this.category,
    required this.note,
    required this.startDate,
    required this.interval,
    this.intervalCount = 1,
    required this.nextRun,
    this.active = true,
  });

  factory RecurringModel.fromMap(Map<String, dynamic> m) => RecurringModel(
        id: m['id'],
        walletId: m['walletId'],
        amount: (m['amount'] as num).toDouble(),
        type: m['type'],
        category: m['category'],
        note: m['note'],
        startDate: DateTime.parse(m['startDate']),
        interval: m['interval'],
        intervalCount: m['intervalCount'] ?? 1,
        nextRun: DateTime.parse(m['nextRun']),
        active: (m['active'] as int) == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'walletId': walletId,
        'amount': amount,
        'type': type,
        'category': category,
        'note': note,
        'startDate': startDate.toIso8601String(),
        'interval': interval,
        'intervalCount': intervalCount,
        'nextRun': nextRun.toIso8601String(),
        'active': active ? 1 : 0,
      };
}
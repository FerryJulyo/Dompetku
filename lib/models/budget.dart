// models/budget.dart
class BudgetModel {
  int? id;
  String categoryKey;
  double amount;
  String period; // 'monthly' (for now)
  int month; // target month (1-12) - optional for specific period; if 0 use recurring monthly
  int year; // year for the budget; if 0 then recurring monthly

  BudgetModel({
    this.id,
    required this.categoryKey,
    required this.amount,
    this.period = 'monthly',
    this.month = 0,
    this.year = 0,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> m) => BudgetModel(
        id: m['id'],
        categoryKey: m['categoryKey'],
        amount: (m['amount'] as num).toDouble(),
        period: m['period'],
        month: m['month'],
        year: m['year'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryKey': categoryKey,
        'amount': amount,
        'period': period,
        'month': month,
        'year': year,
      };
}
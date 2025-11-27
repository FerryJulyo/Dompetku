// models/wallet.dart
class WalletModel {
  int? id;
  String name;
  double balance;
  int colorValue; // store Color.value
  String icon; // simple string for icon name

  WalletModel({
    this.id,
    required this.name,
    required this.balance,
    required this.colorValue,
    required this.icon,
  });

  factory WalletModel.fromMap(Map<String, dynamic> m) => WalletModel(
        id: m['id'],
        name: m['name'],
        balance: (m['balance'] as num).toDouble(),
        colorValue: m['colorValue'],
        icon: m['icon'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'balance': balance,
        'colorValue': colorValue,
        'icon': icon,
      };
}
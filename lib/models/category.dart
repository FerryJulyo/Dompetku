// models/category.dart
class CategoryModel {
  int? id;
  String key; // internal key: bbm, galon, listrik, gas, umum
  String name;
  String icon; // icon key string
  int colorValue;

  CategoryModel({
    this.id,
    required this.key,
    required this.name,
    required this.icon,
    required this.colorValue,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> m) => CategoryModel(
        id: m['id'],
        key: m['key'],
        name: m['name'],
        icon: m['icon'],
        colorValue: m['colorValue'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'key': key,
        'name': name,
        'icon': icon,
        'colorValue': colorValue,
      };
}
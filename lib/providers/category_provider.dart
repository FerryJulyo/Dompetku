// providers/category_provider.dart
import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  List<CategoryModel> _cats = [];

  List<CategoryModel> get categories => _cats;

  CategoryProvider() {
    load();
  }

  Future<void> load() async {
    _cats = await DBHelper.instance.getCategories();
    notifyListeners();
  }

  CategoryModel? findByKey(String key) {
    try {
      return _cats.firstWhere((c) => c.key == key);
    } catch (e) {
      return null;
    }
  }
}
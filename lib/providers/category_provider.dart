import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:moneymanager/models/category_model.dart';

class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId;

  List<CategoryModel> _expenseCategories = List.from(CategoryModel.defaultExpenseCategories);
  List<CategoryModel> _incomeCategories = List.from(CategoryModel.defaultIncomeCategories);

  List<CategoryModel> get expenseCategories => _expenseCategories;
  List<CategoryModel> get incomeCategories => _incomeCategories;

  Future<void> load(String userId) async {
    _userId = userId;
    try {
      final settingsRef = _firestore.collection('users').doc(userId).collection('settings');

      final [expenseSnap, incomeSnap] = await Future.wait([
        settingsRef.doc('expense_categories').get(),
        settingsRef.doc('income_categories').get(),
      ]);

      _expenseCategories = expenseSnap.exists
          ? (expenseSnap.data()!['categories'] as List).map((e) => CategoryModel.fromMap(e)).toList()
          : List.from(CategoryModel.defaultExpenseCategories);

      _incomeCategories = incomeSnap.exists
          ? (incomeSnap.data()!['categories'] as List).map((e) => CategoryModel.fromMap(e)).toList()
          : List.from(CategoryModel.defaultIncomeCategories);

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> add(String userId, CategoryModel item) async {
    final list = item.isIncome ? _incomeCategories : _expenseCategories;
    if (list.any((c) => c.name == item.name)) return;

    list.add(item);
    _save(item.isIncome);
    notifyListeners();
  }

  Future<void> remove(String userId, CategoryModel item) async {
    final list = item.isIncome ? _incomeCategories : _expenseCategories;
    list.removeWhere((c) => c.name == item.name);
    _save(item.isIncome);
    notifyListeners();
  }

  CategoryModel getCategoryByName(String name, {required bool isIncome}) {
    final list = isIncome ? _incomeCategories : _expenseCategories;

    var category = list.cast<CategoryModel?>().firstWhere(
            (c) => c?.name == name,
        orElse: () => null
    );

    if (category == null) {
      category = CategoryModel.withFallback(name: name, isIncome: isIncome);
      list.add(category);
      _save(isIncome);
      notifyListeners();
    }

    return category;
  }

  void _save(bool isIncome) {
    if (_userId == null) return;

    final list = isIncome ? _incomeCategories : _expenseCategories;
    final doc = isIncome ? 'income_categories' : 'expense_categories';

    _firestore
        .collection('users')
        .doc(_userId!)
        .collection('settings')
        .doc(doc)
        .set({'categories': list.map((e) => e.toMap()).toList()})
        .catchError((e) => debugPrint('Save error: $e'));
  }
}
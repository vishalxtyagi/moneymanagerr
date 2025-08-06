import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:moneymanager/core/models/category_model.dart';

class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CategoryModel> _expenseCategories = List.from(CategoryModel.defaultExpenseCategories);
  List<CategoryModel> _incomeCategories = List.from(CategoryModel.defaultIncomeCategories);

  List<CategoryModel> get expenseCategories =>
      List.unmodifiable(_expenseCategories);

  List<CategoryModel> get incomeCategories =>
      List.unmodifiable(_incomeCategories);

  Future<void> load(String userId) async {
    try {
      final settingsRef =
          _firestore.collection('users').doc(userId).collection('settings');

      final expenseSnap = await settingsRef.doc('expense_categories').get();
      final incomeSnap = await settingsRef.doc('income_categories').get();

      if (expenseSnap.exists) {
        final data = expenseSnap.data()!;
        final rawList = List<Map<String, dynamic>>.from(data['categories']);
        _expenseCategories = rawList.map(CategoryModel.fromMap).toList();
      }

      if (incomeSnap.exists) {
        final data = incomeSnap.data()!;
        final rawList = List<Map<String, dynamic>>.from(data['categories']);
        _incomeCategories = rawList.map(CategoryModel.fromMap).toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> add(String userId, CategoryModel item) async {
    final targetList = item.isIncome ? _incomeCategories : _expenseCategories;
    if (targetList.any((c) => c.name == item.name)) return;

    targetList.add(item);
    await _saveCategories(userId, item.isIncome);
    notifyListeners();
  }

  Future<void> remove(String userId, CategoryModel item) async {
    final targetList = item.isIncome ? _incomeCategories : _expenseCategories;
    targetList.removeWhere((c) => c.name == item.name);
    await _saveCategories(userId, item.isIncome);
    notifyListeners();
  }

  Future<void> _saveCategories(String userId, bool isIncome) async {
    final targetList = isIncome ? _incomeCategories : _expenseCategories;
    final path = isIncome ? 'income_categories' : 'expense_categories';

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc(path)
          .set({'categories': targetList.map((e) => e.toMap()).toList()});
    } catch (e) {
      debugPrint('Error saving $path: $e');
    }
  }

  CategoryModel getCategoryByName(String name, {required bool isIncome}) {
    final targetList = isIncome ? _incomeCategories : _expenseCategories;
    return targetList.firstWhere((c) => c.name == name, orElse: () => CategoryModel.withFallback(name: name, isIncome: isIncome));
  }
}

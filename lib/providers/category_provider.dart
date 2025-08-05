import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/constants.dart';

class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<String> _expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping & Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Travel',
    'Personal Care',
    'Groceries',
    'Fuel',
    'Other',
  ];

  List<String> _incomeCategories = [
    'Salary',
    'Business',
    'Investments',
    'Freelancing',
    'Rental Income',
    'Bonus',
    'Gift Money',
    'Interest',
    'Other',
  ];

  List<String> get expenseCategories => List.unmodifiable(_expenseCategories);
  List<String> get incomeCategories => List.unmodifiable(_incomeCategories);

  CategoryProvider() {
    // Remove automatic initialization - will be called when user is available
  }

  Future<void> loadCategories(String userId) async {
    try {
      // Load expense categories
      final expenseDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('expense_categories')
          .get();
      
      if (expenseDoc.exists) {
        final data = expenseDoc.data() as Map<String, dynamic>;
        _expenseCategories = List<String>.from(data['categories'] ?? _expenseCategories);
      }

      // Load income categories
      final incomeDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('income_categories')
          .get();
      
      if (incomeDoc.exists) {
        final data = incomeDoc.data() as Map<String, dynamic>;
        _incomeCategories = List<String>.from(data['categories'] ?? _incomeCategories);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> addExpenseCategory(String userId, String category) async {
    if (!_expenseCategories.contains(category)) {
      _expenseCategories.add(category);
      await _saveExpenseCategories(userId);
      notifyListeners();
    }
  }

  Future<void> removeExpenseCategory(String userId, String category) async {
    _expenseCategories.remove(category);
    await _saveExpenseCategories(userId);
    notifyListeners();
  }

  Future<void> addIncomeCategory(String userId, String category) async {
    if (!_incomeCategories.contains(category)) {
      _incomeCategories.add(category);
      await _saveIncomeCategories(userId);
      notifyListeners();
    }
  }

  Future<void> removeIncomeCategory(String userId, String category) async {
    _incomeCategories.remove(category);
    await _saveIncomeCategories(userId);
    notifyListeners();
  }

  Future<void> _saveExpenseCategories(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('expense_categories')
          .set({'categories': _expenseCategories});
    } catch (e) {
      debugPrint('Error saving expense categories: $e');
    }
  }

  Future<void> _saveIncomeCategories(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('income_categories')
          .set({'categories': _incomeCategories});
    } catch (e) {
      debugPrint('Error saving income categories: $e');
    }
  }

  IconData getCategoryIcon(String category) {
    const categoryIcons = AppIcons.categoryIcons;
    return categoryIcons[category] ?? Icons.category;
  }

  Color getCategoryColor(String category) {
    const categoryColors = AppColors.colorPalette;
    final allCategories = expenseCategories + incomeCategories;
    final index = allCategories.indexOf(category);
    return categoryColors[index % categoryColors.length];
  }
}

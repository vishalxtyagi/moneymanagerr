import 'package:moneymanager/core/utils/category_util.dart';

class CategoryModel {
  final String name;
  final int iconIndex;
  final bool isIncome;

  const CategoryModel({
    required this.name,
    required this.iconIndex,
    required this.isIncome,
  });
  
  Map<String, dynamic> toMap() => {
        'name': name,
        'iconIndex': iconIndex,
        'isIncome': isIncome,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    int iconIdx = map['iconIndex'] ?? CategoryUtil.defaultIconIndex;
    return CategoryModel(
      name: map['name'],
      iconIndex: iconIdx,
      isIncome: map['isIncome'] ?? false,
    );
  }

  static const List<CategoryModel> defaultIncomeCategories = [
    CategoryModel(name: 'Salary', iconIndex: 26, isIncome: true), // money_3
    CategoryModel(name: 'Business', iconIndex: 23, isIncome: true), // building_4
    CategoryModel(name: 'Investments', iconIndex: 27, isIncome: true), // chart_21
    CategoryModel(name: 'Freelancing', iconIndex: 24, isIncome: true), // profile_2user
    CategoryModel(name: 'Rental Income', iconIndex: 26, isIncome: true), // home_2
    CategoryModel(name: 'Bonus', iconIndex: 28, isIncome: true), // gift
    CategoryModel(name: 'Gift Money', iconIndex: 28, isIncome: true), // gift
    CategoryModel(name: 'Interest', iconIndex: 29, isIncome: true), // percentage_circle
    CategoryModel(name: 'Other', iconIndex: 1, isIncome: true), // more
  ];

  static const List<CategoryModel> defaultExpenseCategories = [
    CategoryModel(name: 'Food & Dining', iconIndex: 2, isIncome: false), // cake
    CategoryModel(name: 'Transportation', iconIndex: 4, isIncome: false), // car
    CategoryModel(name: 'Shopping & Entertainment', iconIndex: 8, isIncome: false), // shopping_bag
    CategoryModel(name: 'Bills & Utilities', iconIndex: 11, isIncome: false), // receipt_1
    CategoryModel(name: 'Healthcare', iconIndex: 16, isIncome: false), // health
    CategoryModel(name: 'Education', iconIndex: 22, isIncome: false), // teacher
    CategoryModel(name: 'Travel', iconIndex: 7, isIncome: false), // airplane
    CategoryModel(name: 'Personal Care', iconIndex: 17, isIncome: false), // heart
    CategoryModel(name: 'Groceries', iconIndex: 25, isIncome: false), // shop
    CategoryModel(name: 'Fuel', iconIndex: 5, isIncome: false), // gas_station
    CategoryModel(name: 'Other', iconIndex: 1, isIncome: false), // more
  ];
}

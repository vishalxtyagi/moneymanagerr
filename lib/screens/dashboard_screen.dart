import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/constants/constants.dart';
import 'package:moneymanager/providers/auth_provider.dart';
import 'package:moneymanager/providers/category_provider.dart';
import 'package:moneymanager/providers/transaction_provider.dart';
import 'package:moneymanager/screens/add_transaction_screen.dart';
import 'package:moneymanager/screens/transaction_history_screen.dart';
import 'package:moneymanager/utils/responsive_helper.dart';
import 'package:moneymanager/shared/widgets/widgets.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (userId != null) {
      transactionProvider.fetchTransactions(userId);
      categoryProvider.loadCategories(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6B8),
      body: SafeArea(
        child: Consumer2<TransactionProvider, AuthProvider>(
          builder: (context, transactionProvider, authProvider, child) {
            final recentTransactions = transactionProvider.recentTranactions;
            final balance = transactionProvider.getBalance();
            final income = transactionProvider.getTotalIncome();
            final expense = transactionProvider.getTotalExpense();
            
            // Calculate consumption indicator
            final consumptionData = _getConsumptionData(income, expense);

            return ResponsiveHelper.constrainWidth(
              context,
              SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Section
                    Padding(
                      padding: ResponsiveHelper.getScreenPadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, authProvider),
                          SizedBox(height: ResponsiveHelper.getSpacing(context, scale: 1.5)),
                          _buildBalanceCard(balance, income, expense, consumptionData),
                          SizedBox(height: ResponsiveHelper.getSpacing(context)),
                        ],
                      ),
                    ),
                    
                    // Content Section
                    ColoredContainer(
                      color: Colors.grey[100]!,
                      padding: ResponsiveHelper.getScreenPadding(context),
                      child: Column(
                        children: [
                          // Statistics Row
                          _buildStatisticsRow(transactionProvider),
                          SizedBox(height: ResponsiveHelper.getSpacing(context)),

                          // Recent Transactions
                          _buildRecentTransactions(recentTransactions, context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider authProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()),
              style: TextStyle(
                color: Colors.black54,
                fontSize: ResponsiveHelper.getFontSize(context, 16),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hello, ${authProvider.user?.displayName?.split(' ').first ?? 'User'}!',
              style: TextStyle(
                color: Colors.black87,
                fontSize: ResponsiveHelper.getFontSize(context, 28),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: ResponsiveHelper.responsive(context, mobile: 20.0, tablet: 24.0, desktop: 28.0),
          backgroundImage: authProvider.user?.photoURL != null
              ? NetworkImage(authProvider.user!.photoURL!)
              : null,
          child: authProvider.user?.photoURL == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
      ],
    );
  }

  Widget _buildBalanceCard(double balance, double income, double expense, Map<String, dynamic> consumptionData) {
    return BalanceCard(
      balance: balance,
      income: income,
      expense: expense,
      consumptionData: consumptionData,
    );
  }

  Widget _buildStatisticsRow(TransactionProvider provider) {
    final todayTransactions = provider.transactions.where((t) {
      final today = DateTime.now();
      return t.date.year == today.year &&
             t.date.month == today.month &&
             t.date.day == today.day;
    }).length;

    final thisMonthTransactions = provider.transactions.where((t) {
      final today = DateTime.now();
      return t.date.year == today.year && t.date.month == today.month;
    }).length;

    final topCategory = provider.getTopSpendingCategories(limit: 1);
    final topCategoryName = topCategory.isNotEmpty ? topCategory.first.key : 'None';

    final stats = [
      ('Today', '$todayTransactions', Icons.today),
      ('This Month', '$thisMonthTransactions', Icons.calendar_month),
      ('Top Category', topCategoryName, Icons.category),
    ];

    if (ResponsiveHelper.isDesktop(context)) {
      return Row(
        children: stats.map((stat) => 
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: StatisticCard(
                title: stat.$1,
                value: stat.$2,
                icon: stat.$3,
                color: AppColors.primary,
              ),
            ),
          ),
        ).toList(),
      );
    } else {
      return Row(
        children: [
          Expanded(child: StatisticCard(title: stats[0].$1, value: stats[0].$2, icon: stats[0].$3, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: StatisticCard(title: stats[1].$1, value: stats[1].$2, icon: stats[1].$3, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: StatisticCard(title: stats[2].$1, value: stats[2].$2, icon: stats[2].$3, color: AppColors.primary)),
        ],
      );
    }
  }

  Widget _buildRecentTransactions(List<dynamic> recentTransactions, BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Recent Transactions',
            action: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionHistoryScreen(),
                  ),
                );
              },
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveHelper.getFontSize(context, 14),
                ),
              ),
            ),
          ),
          if (recentTransactions.isEmpty)
            const EmptyStateWidget(
              icon: Icons.receipt_long,
              title: 'No transactions yet',
              subtitle: 'Start by adding your first transaction',
            )
          else
            Column(
              children: recentTransactions
                  .map((transaction) => TransactionItem(
                        transaction: transaction,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddTransactionScreen(
                                transaction: transaction,
                              ),
                            ),
                          );
                        },
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getConsumptionData(double income, double expense) {
    if (income == 0) {
      return {
        'text': 'No income',
        'color': AppColors.textSecondary,
        'percentage': 0.0,
      };
    }

    final consumptionPercentage = (expense / income) * 100;
    String text;
    Color color;

    if (consumptionPercentage <= 100) {
      text = '${consumptionPercentage.toStringAsFixed(0)}% spent';
      color = AppColors.primaryVariant;
    } else {
      final overBudget = consumptionPercentage - 100;
      text = '${overBudget.toStringAsFixed(0)}% over budget!';
      color = AppColors.error;
    }

    return {
      'text': text,
      'color': color,
      'percentage': consumptionPercentage,
    };
  }
}





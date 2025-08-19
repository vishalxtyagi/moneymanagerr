import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/models/analytics_model.dart';
import 'package:moneymanager/core/providers/auth_provider.dart';
import 'package:moneymanager/core/providers/transaction_provider.dart';
import 'package:moneymanager/core/utils/responsive_util.dart';
import 'package:moneymanager/screens/transaction_history_screen.dart';
import 'package:moneymanager/widgets/common/card.dart';
import 'package:moneymanager/widgets/header/section_header.dart';
import 'package:moneymanager/widgets/items/balance_card.dart';
import 'package:moneymanager/widgets/items/statistic_item.dart';
import 'package:moneymanager/widgets/states/empty_state.dart';

/// Optimized Dashboard Screen with minimal rebuilds and efficient Provider usage
class DashboardScreenOptimized extends StatefulWidget {
  const DashboardScreenOptimized({super.key});

  @override
  State<DashboardScreenOptimized> createState() => _DashboardScreenOptimizedState();
}

class _DashboardScreenOptimizedState extends State<DashboardScreenOptimized>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final responsive = ResponsiveUtil.of(context);
    
    return Scaffold(
      backgroundColor: responsive.isDesktop ? Colors.grey.shade50 : null,
      appBar: responsive.isDesktop ? null : AppBar(
        title: Selector<AuthProvider, String?>(
          selector: (_, provider) => provider.user?.displayName,
          builder: (context, displayName, _) => Text('Hi, ${displayName ?? 'User'}!'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: responsive.isDesktop
          ? _DesktopLayout(responsive: responsive)
          : _MobileLayout(responsive: responsive),
    );
  }
}

/// Desktop layout with proper two-column structure
class _DesktopLayout extends StatelessWidget {
  final ResponsiveUtil responsive;

  const _DesktopLayout({required this.responsive});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.spacing(scale: 1.5)),
      child: responsive.constrain(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            _DashboardHeader(responsive: responsive),
            SizedBox(height: responsive.spacing(scale: 2)),
            
            // Main content - Two column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Balance and quick stats
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _BalanceSection(responsive: responsive),
                      SizedBox(height: responsive.spacing(scale: 1.5)),
                      _QuickStatsSection(responsive: responsive),
                    ],
                  ),
                ),
                
                SizedBox(width: responsive.spacing(scale: 1.5)),
                
                // Right column - Recent transactions
                Expanded(
                  flex: 3,
                  child: _RecentTransactionsSection(responsive: responsive),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile layout with vertical stacking
class _MobileLayout extends StatelessWidget {
  final ResponsiveUtil responsive;

  const _MobileLayout({required this.responsive});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: responsive.screenPadding(),
      child: Column(
        children: [
          // Balance card
          _BalanceSection(responsive: responsive),
          SizedBox(height: responsive.spacing(scale: 1.5)),
          
          // Quick stats
          _QuickStatsSection(responsive: responsive),
          SizedBox(height: responsive.spacing(scale: 1.5)),
          
          // Recent transactions
          _RecentTransactionsSection(responsive: responsive),
        ],
      ),
    );
  }
}

/// Dashboard header for desktop
class _DashboardHeader extends StatelessWidget {
  final ResponsiveUtil responsive;

  const _DashboardHeader({required this.responsive});

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, String?>(
      selector: (_, provider) => provider.user?.displayName,
      builder: (context, displayName, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${displayName ?? 'User'}!',
            style: TextStyle(
              fontSize: responsive.fontSize(32),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s your financial overview',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Optimized balance section with single analytics computation
class _BalanceSection extends StatelessWidget {
  final ResponsiveUtil responsive;

  const _BalanceSection({required this.responsive});

  @override
  Widget build(BuildContext context) {
    return Selector<TransactionProvider, AnalyticsModel>(
      selector: (_, provider) => AnalyticsModel.fromTotals(
        income: provider.totalIncome,
        expense: provider.totalExpense,
      ),
      builder: (context, analytics, _) => BalanceCard(
        analytics: analytics,
      ),
    );
  }
}

/// Quick statistics section with efficient selectors
class _QuickStatsSection extends StatelessWidget {
  final ResponsiveUtil responsive;

  const _QuickStatsSection({required this.responsive});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Quick Stats',
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: responsive.spacing()),
          
          // Use separate selectors to minimize rebuilds
          responsive.isDesktop
              ? Row(
                  children: [
                    Expanded(child: _TodayCountStat(responsive: responsive)),
                    SizedBox(width: responsive.spacing()),
                    Expanded(child: _MonthCountStat(responsive: responsive)),
                    SizedBox(width: responsive.spacing()),
                    Expanded(child: _ExpenseRatioStat(responsive: responsive)),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _TodayCountStat(responsive: responsive)),
                        SizedBox(width: responsive.spacing()),
                        Expanded(child: _MonthCountStat(responsive: responsive)),
                      ],
                    ),
                    SizedBox(height: responsive.spacing()),
                    _ExpenseRatioStat(responsive: responsive),
                  ],
                ),
        ],
      ),
    );
  }
}

/// Individual stat widgets with targeted selectors
class _TodayCountStat extends StatelessWidget {
  final ResponsiveUtil responsive;

  const _TodayCountStat({required this.responsive});

  @override
  Widget build(BuildContext context) {
    return Selector<TransactionProvider, int>(
      selector: (_, provider) => provider.todayCount,
      builder: (context, count, _) => StatisticCard(
        title: 'Today',
        value: count.toString(),
        icon: Iconsax.calendar_1,
        color: AppColors.primary,
      ),
    );
  }
}

class _MonthCountStat extends StatelessWidget {
  final ResponsiveUtil responsive;

  const _MonthCountStat({required this.responsive});

  @override
  Widget build(BuildContext context) {
    return Selector<TransactionProvider, int>(
      selector: (_, provider) => provider.monthCount,
      builder: (context, count, _) => StatisticCard(
        title: 'This Month',
        value: count.toString(),
        icon: Iconsax.calendar,
        color: AppColors.secondary,
      ),
    );
  }
}

class _ExpenseRatioStat extends StatelessWidget {
  final ResponsiveUtil responsive;

  const _ExpenseRatioStat({required this.responsive});

  @override
  Widget build(BuildContext context) {
    return Selector<TransactionProvider, double>(
      selector: (_, provider) => provider.totalIncome > 0 
          ? (provider.totalExpense / provider.totalIncome) * 100 
          : 0.0,
      builder: (context, ratio, _) => StatisticCard(
        title: 'Expense Ratio',
        value: '${ratio.toStringAsFixed(1)}%',
        icon: Iconsax.percentage_circle,
        color: ratio > 80 ? Colors.red : ratio > 60 ? Colors.orange : Colors.green,
      ),
    );
  }
}

/// Recent transactions section with optimized list
class _RecentTransactionsSection extends StatelessWidget {
  final ResponsiveUtil responsive;

  const _RecentTransactionsSection({required this.responsive});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Recent Transactions',
            action: TextButton.icon(
              onPressed: () => _NavigationHelper.navigateToHistory(context),
              icon: const Icon(Iconsax.arrow_right_3, size: 16),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.fontSize(14),
                ),
              ),
            ),
          ),
          
          // Efficient list with limited items
          Selector<TransactionProvider, List<dynamic>>(
            selector: (_, provider) => [
              provider.all.take(5).toList(),
              provider.all.length, // Include length for empty state
            ],
            builder: (context, data, _) {
              final transactions = data[0] as List;
              final totalCount = data[1] as int;
              
              if (transactions.isEmpty) {
                return const AppEmptyState(
                  icon: Iconsax.receipt_minus,
                  title: 'No transactions yet',
                  subtitle: 'Add your first transaction to get started',
                );
              }

              return Column(
                children: [
                  // Transaction list
                  ...transactions.map((transaction) => Padding(
                    padding: EdgeInsets.only(bottom: responsive.spacing(scale: 0.5)),
                    child: _SimpleTransactionItem(
                      transaction: transaction,
                      responsive: responsive,
                    ),
                  )),
                  
                  // Show more indicator
                  if (totalCount > 5)
                    Padding(
                      padding: EdgeInsets.only(top: responsive.spacing()),
                      child: Text(
                        'and ${totalCount - 5} more transactions',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: responsive.fontSize(12),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Navigation helper to avoid repeated navigation logic
class _NavigationHelper {
  static void navigateToHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionHistoryScreen(),
      ),
    );
  }
}

/// Simple transaction item for dashboard - doesn't need category lookup
class _SimpleTransactionItem extends StatelessWidget {
  final dynamic transaction;
  final ResponsiveUtil responsive;

  const _SimpleTransactionItem({
    required this.transaction,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type.toString().contains('income');
    final amount = transaction.amount as double;
    final title = transaction.title as String;
    final category = transaction.category as String;
    
    return Container(
      padding: EdgeInsets.all(responsive.spacing()),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Transaction icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome ? Iconsax.arrow_up_2 : Iconsax.arrow_down_2,
              color: isIncome ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          
          SizedBox(width: responsive.spacing()),
          
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Amount
          Text(
            '${isIncome ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

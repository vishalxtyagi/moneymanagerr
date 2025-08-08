import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/constants/enums.dart';
import 'package:moneymanager/core/models/analytics_model.dart';
import 'package:moneymanager/core/providers/auth_provider.dart';
import 'package:moneymanager/core/providers/category_provider.dart';
import 'package:moneymanager/core/providers/transaction_provider.dart';
import 'package:moneymanager/core/utils/responsive_util.dart';
import 'package:moneymanager/screens/add_transaction_screen.dart';
import 'package:moneymanager/screens/transaction_history_screen.dart';
import 'package:moneymanager/widgets/common/card.dart';
import 'package:moneymanager/widgets/items/balance_card.dart';
import 'package:moneymanager/widgets/items/statistic_item.dart';
import 'package:moneymanager/widgets/header/section_header.dart';
import 'package:moneymanager/widgets/states/empty_state.dart';
import 'package:moneymanager/widgets/items/transaction_item.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Remove duplicate fetch: TransactionProvider.fetch is already triggered by auth changes
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (userId != null) {
      categoryProvider.load(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for keep alive
    final responsive = ResponsiveUtil.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6B8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header + Balance section
              Padding(
                padding: responsive.screenPadding(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Selector<AuthProvider, AuthProvider>(
                      selector: (_, a) => a,
                      builder: (context, authProvider, _) => _buildHeader(
                          context, authProvider, responsive),
                    ),
                    SizedBox(height: responsive.spacing(scale: 1.5)),
                    // Use lightweight totals to build analytics for the card
                    Selector<TransactionProvider, (double,double)>(
                      selector: (_, p) => (p.totalIncome, p.totalExpense),
                      builder: (_, totals, __) => RepaintBoundary(
                        child: BalanceCard(
                          analytics: AnalyticsModel.fromTotals(
                            income: totals.$1,
                            expense: totals.$2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing()),
                  ],
                ),
              ),

              // Content Section
              Container(
                color: Colors.grey[100]!,
                padding: responsive.screenPadding(),
                child: Column(
                  children: [
                    // Statistics Row: use provider counters
                    Selector<TransactionProvider, (int,int,String)>(
                      selector: (_, p) {
                        final top = p.getTopCategories(count: 1);
                        final topName = top.isNotEmpty ? top.first.key : 'None';
                        return (p.todayCount, p.monthCount, topName);
                      },
                      builder: (context, tuple, _) => _buildStatisticsRowFrom(
                          tuple.$1, tuple.$2, tuple.$3, responsive),
                    ),
                    SizedBox(height: responsive.spacing()),
                    // Recent Transactions: only 5 items
                    Selector<TransactionProvider, List<dynamic>>(
                      selector: (_, p) => p.all.take(5).toList(),
                      builder: (context, recentTransactions, _) =>
                          _buildRecentTransactions(
                              recentTransactions, context, responsive),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider authProvider,
      ResponsiveUtil responsive) {
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
                fontSize: responsive.fontSize(16),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hello, ${authProvider.user?.displayName?.split(' ').first ?? 'User'}!',
              style: TextStyle(
                color: Colors.black87,
                fontSize: responsive.fontSize(28),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: responsive.value(
            mobile: 20.0,
            tablet: 24.0,
            desktop: 28.0,
          ),
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

  // New helper to render statistics from precomputed tuple
  Widget _buildStatisticsRowFrom(
      int todayTransactions, int thisMonthTransactions, String topCategoryName,
      ResponsiveUtil responsive) {
    final stats = [
      ('Today', '$todayTransactions', Icons.today),
      ('This Month', '$thisMonthTransactions', Icons.calendar_month),
      ('Top Category', topCategoryName, Icons.category),
    ];

    if (responsive.isDesktop) {
      return Row(
        children: stats
            .map(
              (stat) => Expanded(
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
            )
            .toList(),
      );
    } else {
      return Row(
        children: [
          Expanded(
              child: StatisticCard(
                  title: stats[0].$1,
                  value: stats[0].$2,
                  icon: stats[0].$3,
                  color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(
              child: StatisticCard(
                  title: stats[1].$1,
                  value: stats[1].$2,
                  icon: stats[1].$3,
                  color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(
              child: StatisticCard(
                  title: stats[2].$1,
                  value: stats[2].$2,
                  icon: stats[2].$3,
                  color: AppColors.primary)),
        ],
      );
    }
  }

  Widget _buildRecentTransactions(List<dynamic> recentTransactions,
      BuildContext context, ResponsiveUtil responsive) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
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
                  fontSize: responsive.fontSize(14),
                ),
              ),
            ),
          ),
          if (recentTransactions.isEmpty)
            const AppEmptyState(
              icon: Icons.receipt_long,
              title: 'No transactions yet',
              subtitle: 'Start by adding your first transaction',
            )
          else
            Column(
              children: recentTransactions
                  .map((transaction) => Selector<CategoryProvider, dynamic>(
                        selector: (context, provider) => provider
                            .getCategoryByName(transaction.category,
                                isIncome: transaction.type ==
                                    TransactionType.income),
                        builder: (_, category, __) => TransactionItem(
                          transaction: transaction,
                          category: category,
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
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

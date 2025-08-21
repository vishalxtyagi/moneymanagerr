import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/models/analytics_model.dart';
import 'package:moneymanager/providers/auth_provider.dart';
import 'package:moneymanager/providers/category_provider.dart';
import 'package:moneymanager/providers/transaction_provider.dart';
import 'package:moneymanager/utils/context_util.dart';
import 'package:moneymanager/services/navigation_service.dart';
import 'package:moneymanager/widgets/common/card.dart';
import 'package:moneymanager/widgets/common/button.dart';
import 'package:moneymanager/widgets/items/balance_card.dart';
import 'package:moneymanager/widgets/items/insight_card.dart';
import 'package:moneymanager/widgets/items/statistic_item.dart';
import 'package:moneymanager/widgets/header/section_header.dart';
import 'package:moneymanager/widgets/states/empty_state.dart';
import 'package:moneymanager/widgets/items/transaction_item.dart';
import 'package:moneymanager/widgets/common/user_avatar.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

// Precomputed values for performance
class _DashboardConstants {
  static final DateTime _now = DateTime.now();
  static final String greeting = _getGreetingForHour(_now.hour);
  static final String formattedDate =
      DateFormat('EEEE, MMMM dd, yyyy').format(_now);
  static final String shortFormattedDate =
      DateFormat('EEEE, MMM d').format(_now);

  static String _getGreetingForHour(int hour) {
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  static DateTimeRange get todayRange => DateTimeRange(
        start: DateTime(_now.year, _now.month, _now.day),
        end: DateTime(_now.year, _now.month, _now.day, 23, 59, 59),
      );

  static DateTimeRange get weekRange {
    final startOfWeek = _now.subtract(Duration(days: _now.weekday - 1));
    return DateTimeRange(
      start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      end: _now,
    );
  }
}

// Navigation helper to reduce code duplication
class _NavigationHelper {
  static void navigateToHistory(
    BuildContext context, {
    DateTimeRange? range,
  }) {
    NavigationService.goToTransactionHistory(
      context,
      initialDateRange: range,
    );
  }

  static void navigateToAddTransaction(BuildContext context,
      [dynamic transaction]) {
    if (transaction != null) {
      NavigationService.openEditTransactionDrawer(context, transaction);
    } else {
      NavigationService.openTransactionDrawer(context);
    }
  }
}

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;

    final categoryProvider = context.read<CategoryProvider>();
    final userId = context.read<AuthProvider>().user?.uid;

    if (userId != null) {
      await categoryProvider.load(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return context.isDesktop ? const _DesktopLayout() : const _MobileLayout();
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.spacing(1.5)),
        child: context.constrain(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _WelcomeSection(),
              SizedBox(height: context.spacing(1.5)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        const _BalanceSection(),
                        SizedBox(height: context.spacing()),
                        const _QuickStatsGrid(),
                        SizedBox(height: context.spacing()),
                        const _InsightsCard()
                      ],
                    ),
                  ),
                  SizedBox(width: context.spacing(1.5)),
                  const Expanded(
                    flex: 3,
                    child: _RecentTransactionsSection(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFB8E6B8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _HeaderSection(),
              _ContentSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, String?>(
      selector: (_, provider) => provider.user?.displayName,
      builder: (context, displayName, _) {
        final firstName = displayName?.split(' ').first ?? 'User';

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(context.spacing(1.5)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${_DashboardConstants.greeting}!',
                        style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          color: Colors.white.withOpacity(0.9),
                          fontSize: context.fontSize(16),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome back, $firstName',
                        style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          color: Colors.white,
                          fontSize: context.fontSize(28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _DashboardConstants.formattedDate,
                        style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          color: Colors.white.withOpacity(0.8),
                          fontSize: context.fontSize(14),
                        ),
                      ),
                    ],
                  ),
                ),
                const _UserAvatar(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, String?>(
      selector: (_, provider) => provider.user?.photoURL,
      builder: (context, photoURL, _) => UserAvatar(
        photoURL: photoURL,
        size: 80,
        backgroundColor: Colors.white.withOpacity(0.2),
        iconColor: Colors.white.withOpacity(0.8),
        borderColor: Colors.white.withOpacity(0.3),
        showBorder: true,
      ),
    );
  }
}

class _BalanceSection extends StatelessWidget {
  const _BalanceSection();

  @override
  Widget build(BuildContext context) {
    return Selector<TransactionProvider, (double, double)>(
      selector: (_, provider) => (provider.totalIncome, provider.totalExpense),
      builder: (_, totals, __) => BalanceCard(
        analytics: AnalyticsModel.fromTotals(
          income: totals.$1,
          expense: totals.$2,
        ),
      ),
    );
  }
}

class _QuickStatsGrid extends StatelessWidget {
  const _QuickStatsGrid();

  @override
  Widget build(BuildContext context) {
    return Selector<TransactionProvider, _StatisticsData>(
      selector: (_, provider) {
        final topCategories = provider.getTopCategories(count: 1);
        final balance = provider.getBalance();
        final weekCount = _getWeekCount(provider);
        final expenseRatio = _getExpenseRatio(provider);

        return _StatisticsData(
          todayCount: provider.todayCount,
          monthCount: provider.monthCount,
          topCategoryName:
              topCategories.isNotEmpty ? topCategories.first.key : 'None',
          balance: balance,
          weekCount: weekCount,
          expenseRatio: expenseRatio,
        );
      },
      builder: (context, stats, _) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: context.spacing(),
          crossAxisSpacing: context.spacing(),
          childAspectRatio: 1.35,
          children: [
            StatisticCard(
              title: 'Today',
              value: '${stats.todayCount}',
              icon: Iconsax.calendar_1,
              color: Colors.blue,
              onTap: () => _NavigationHelper.navigateToHistory(
                context,
                range: _DashboardConstants.todayRange,
              ),
            ),
            StatisticCard(
              title: 'This Week',
              value: '${stats.weekCount}',
              icon: Iconsax.calendar_tick,
              color: Colors.green,
              onTap: () => _NavigationHelper.navigateToHistory(
                context,
                range: _DashboardConstants.weekRange,
              ),
            ),
          ],
        );
      },
    );
  }

  int _getWeekCount(TransactionProvider provider) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekRange = DateTimeRange(
      start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      end: now,
    );

    return provider.all
        .where((txn) =>
            !txn.date.isBefore(weekRange.start) &&
            !txn.date.isAfter(weekRange.end))
        .length;
  }

  double _getExpenseRatio(TransactionProvider provider) {
    if (provider.totalIncome == 0) return 0.0;
    return (provider.totalExpense / provider.totalIncome) * 100;
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Recent Transactions',
            action: AppButton(
              text: 'View All',
              icon: Iconsax.arrow_right_3,
              type: ButtonType.outlined,
              size: ButtonSize.sm,
              onPressed: () => _NavigationHelper.navigateToHistory(context),
            ),
          ),
          Selector<TransactionProvider, List<dynamic>>(
            selector: (_, provider) => provider.all.take(7).toList(),
            builder: (context, recentTransactions, _) {
              if (recentTransactions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: AppEmptyState(
                    icon: Iconsax.receipt_item,
                    title: 'No transactions yet',
                    subtitle: 'Start by adding your first transaction',
                  ),
                );
              }

              return Column(
                children: recentTransactions
                    .map(
                      (transaction) => Selector<CategoryProvider, dynamic>(
                        selector: (_, provider) => provider.getCategoryByName(
                          transaction.category,
                          isIncome: transaction.type == TransactionType.income,
                        ),
                        builder: (_, category, __) => TransactionItem(
                          transaction: transaction,
                          category: category,
                          onTap: () =>
                              _NavigationHelper.navigateToAddTransaction(
                            context,
                            transaction,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights',
            style: TextStyle(
              overflow: TextOverflow.ellipsis,
              fontSize: context.fontSize(18),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: context.spacing()),
          Selector<TransactionProvider, _InsightData>(
            selector: (_, provider) => _InsightData(
              todayCount: provider.todayCount,
              balance: provider.getBalance(),
              topCategories: provider.getTopCategories(count: 1),
            ),
            builder: (context, data, _) {
              final insights = _generateInsights(data);

              return Column(
                children: insights
                    .map((insight) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InsightCard(
                            title: insight.title,
                            description: insight.description,
                            icon: insight.icon,
                            color: insight.color,
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  List<_Insight> _generateInsights(_InsightData data) {
    final insights = <_Insight>[];

    if (data.todayCount > 0) {
      insights.add(_Insight(
        icon: Iconsax.flash_1,
        title: 'Active Day',
        description: 'You have ${data.todayCount} transactions today',
        color: AppColors.success,
      ));
    }

    if (data.balance > 10000) {
      insights.add(const _Insight(
        icon: Iconsax.medal_star,
        title: 'Great Balance',
        description: 'Your balance looks healthy!',
        color: AppColors.primary,
      ));
    } else {
      insights.add(
        const _Insight(
          icon: Iconsax.medal_star,
          title: 'Low Balance',
          description: 'Your balance is below average.',
          color: AppColors.error,
        ),
      );
    }

    if (data.topCategories.isNotEmpty) {
      insights.add(_Insight(
        icon: Iconsax.category_2,
        title: 'Top Spending',
        description: 'Most spent on ${data.topCategories.first.key}',
        color: AppColors.warning,
      ));
    }

    if (insights.isEmpty) {
      insights.add(const _Insight(
        icon: Iconsax.info_circle,
        title: 'Getting Started',
        description: 'Add transactions to see insights',
        color: AppColors.textSecondary,
      ));
    }

    return insights;
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFB8E6B8)),
      child: Padding(
        padding: context.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Selector<AuthProvider, String?>(
              selector: (_, provider) => provider.user?.displayName,
              builder: (context, displayName, _) {
                final firstName = displayName?.split(' ').first ?? 'User';

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _DashboardConstants.shortFormattedDate,
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            color: Colors.black54,
                            fontSize: context.fontSize(16),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hello, $firstName!',
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            color: Colors.black87,
                            fontSize: context.fontSize(28),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Selector<AuthProvider, String?>(
                      selector: (_, provider) => provider.user?.photoURL,
                      builder: (context, photoURL, _) => UserAvatar(
                        photoURL: photoURL,
                        size: context.responsiveValue(
                            mobile: 40.0, tablet: 48.0, desktop: 56.0),
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        iconColor: AppColors.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: context.spacing(1.5)),
            const _BalanceSection(),
            SizedBox(height: context.spacing()),
          ],
        ),
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.grey[100]!),
      child: Padding(
        padding: context.screenPadding,
        child: Column(
          children: [
            const _StatisticsRow(),
            SizedBox(height: context.spacing()),
            const _RecentTransactionsMobile(),
          ],
        ),
      ),
    );
  }
}

class _StatisticsRow extends StatelessWidget {
  const _StatisticsRow();

  @override
  Widget build(BuildContext context) {
    return Selector<TransactionProvider, _StatisticsData>(
      selector: (_, provider) {
        final topCategories = provider.getTopCategories(count: 1);
        final balance = provider.getBalance();
        final weekCount = _getWeekCount(provider);
        final expenseRatio = _getExpenseRatio(provider);

        return _StatisticsData(
          todayCount: provider.todayCount,
          monthCount: provider.monthCount,
          topCategoryName:
              topCategories.isNotEmpty ? topCategories.first.key : 'None',
          balance: balance,
          weekCount: weekCount,
          expenseRatio: expenseRatio,
        );
      },
      builder: (context, stats, _) {
        const spacing = SizedBox(width: 12);

        final cards = [
          StatisticCard(
            title: 'Today',
            value: '${stats.todayCount}',
            icon: Icons.today,
            color: AppColors.primary,
            onTap: () => _NavigationHelper.navigateToHistory(
              context,
              range: _DashboardConstants.todayRange,
            ),
          ),
          StatisticCard(
            title: 'This Week',
            value: '${stats.weekCount}',
            icon: Icons.calendar_view_week,
            color: AppColors.primary,
            onTap: () => _NavigationHelper.navigateToHistory(
              context,
              range: _DashboardConstants.weekRange,
            ),
          ),
        ];

        return Row(
          children: [
            Expanded(child: cards[0]),
            spacing,
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }

  int _getWeekCount(TransactionProvider provider) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekRange = DateTimeRange(
      start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      end: now,
    );

    return provider.all
        .where((txn) =>
            !txn.date.isBefore(weekRange.start) &&
            !txn.date.isAfter(weekRange.end))
        .length;
  }

  double _getExpenseRatio(TransactionProvider provider) {
    if (provider.totalIncome == 0) return 0.0;
    return (provider.totalExpense / provider.totalIncome) * 100;
  }
}

class _RecentTransactionsMobile extends StatelessWidget {
  const _RecentTransactionsMobile();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Recent Transactions',
            action: AppButton(
              text: 'View All',
              type: ButtonType.outlined,
              size: ButtonSize.sm,
              onPressed: () => _NavigationHelper.navigateToHistory(context),
            ),
          ),
          Selector<TransactionProvider, List<dynamic>>(
            selector: (_, provider) => provider.all.take(5).toList(),
            builder: (context, transactions, _) {
              if (transactions.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.receipt_long,
                  title: 'No transactions yet',
                  subtitle: 'Start by adding your first transaction',
                );
              }

              return Column(
                children: transactions
                    .map(
                      (transaction) => Selector<CategoryProvider, dynamic>(
                        selector: (_, provider) => provider.getCategoryByName(
                          transaction.category,
                          isIncome: transaction.type == TransactionType.income,
                        ),
                        builder: (_, category, __) => TransactionItem(
                          transaction: transaction,
                          category: category,
                          onTap: () =>
                              _NavigationHelper.navigateToAddTransaction(
                            context,
                            transaction,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Helper data classes
class _StatisticsData {
  const _StatisticsData({
    required this.todayCount,
    required this.monthCount,
    required this.topCategoryName,
    required this.balance,
    required this.weekCount,
    required this.expenseRatio,
  });

  final int todayCount;
  final int monthCount;
  final String topCategoryName;
  final double balance;
  final int weekCount;
  final double expenseRatio;
}

class _InsightData {
  const _InsightData({
    required this.todayCount,
    required this.balance,
    required this.topCategories,
  });

  final int todayCount;
  final double balance;
  final List<MapEntry<String, double>> topCategories;
}

class _Insight {
  const _Insight({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}

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
    // Defer category loading to avoid blocking initial render
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
    super.build(context); // for keep alive
    final responsive = ResponsiveUtil.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6B8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header + Balance section with const colors
              _HeaderSection(responsive: responsive),
              
              // Content Section
              _ContentSection(responsive: responsive),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.responsive});
  
  final ResponsiveUtil responsive;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFB8E6B8),
      padding: responsive.screenPadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) => _DashboardHeader(
              authProvider: authProvider,
              responsive: responsive,
            ),
          ),
          SizedBox(height: responsive.spacing(scale: 1.5)),
          // Optimized balance card with minimal rebuild scope
          Selector<TransactionProvider, (double, double)>(
            selector: (_, provider) => (provider.totalIncome, provider.totalExpense),
            builder: (_, totals, __) => BalanceCard(
              analytics: AnalyticsModel.fromTotals(
                income: totals.$1,
                expense: totals.$2,
              ),
            ),
          ),
          SizedBox(height: responsive.spacing()),
        ],
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection({required this.responsive});
  
  final ResponsiveUtil responsive;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100]!,
      padding: responsive.screenPadding(),
      child: Column(
        children: [
          // Statistics Row with optimized selector
          Selector<TransactionProvider, _StatisticsData>(
            selector: (_, provider) {
              final topCategories = provider.getTopCategories(count: 1);
              return _StatisticsData(
                todayCount: provider.todayCount,
                monthCount: provider.monthCount,
                topCategoryName: topCategories.isNotEmpty ? topCategories.first.key : 'None',
              );
            },
            builder: (context, stats, _) => _StatisticsRow(
              stats: stats,
              responsive: responsive,
            ),
          ),
          SizedBox(height: responsive.spacing()),
          // Recent Transactions with limited items
          Selector<TransactionProvider, List<dynamic>>(
            selector: (_, provider) => provider.all.take(5).toList(),
            builder: (context, recentTransactions, _) => _RecentTransactionsSection(
              transactions: recentTransactions,
              responsive: responsive,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper data classes for optimized selectors
class _StatisticsData {
  final int todayCount;
  final int monthCount;
  final String topCategoryName;

  const _StatisticsData({
    required this.todayCount,
    required this.monthCount,
    required this.topCategoryName,
  });
}

// Optimized header widget
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.authProvider,
    required this.responsive,
  });

  final AuthProvider authProvider;
  final ResponsiveUtil responsive;

  @override
  Widget build(BuildContext context) {
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
}

// Optimized statistics row widget
class _StatisticsRow extends StatelessWidget {
  const _StatisticsRow({
    required this.stats,
    required this.responsive,
  });

  final _StatisticsData stats;
  final ResponsiveUtil responsive;

  @override
  Widget build(BuildContext context) {
    const spacing = SizedBox(width: 12);
    
    final cards = [
      StatisticCard(
        title: 'Today',
        value: '${stats.todayCount}',
        icon: Icons.today,
        color: AppColors.primary,
        onTap: () => _navigateToTodayTransactions(context),
      ),
      StatisticCard(
        title: 'This Month',
        value: '${stats.monthCount}',
        icon: Icons.calendar_month,
        color: AppColors.primary,
        onTap: () => _navigateToMonthTransactions(context),
      ),
      StatisticCard(
        title: 'Top Category',
        value: stats.topCategoryName,
        icon: Icons.category,
        color: AppColors.primary,
        onTap: () => _navigateToTopCategory(context, stats.topCategoryName),
      ),
    ];

    if (responsive.isDesktop) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) spacing,
          ],
        ],
      );
    }
    
    return Row(
      children: [
        Expanded(child: cards[0]),
        spacing,
        Expanded(child: cards[1]),
        spacing,
        Expanded(child: cards[2]),
      ],
    );
  }

  void _navigateToTodayTransactions(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionHistoryScreen(
          initialRange: DateTimeRange(start: start, end: start),
          ephemeralFilters: true,
        ),
      ),
    );
  }

  void _navigateToMonthTransactions(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionHistoryScreen(
          initialRange: DateTimeRange(start: start, end: end),
          ephemeralFilters: true,
        ),
      ),
    );
  }

  void _navigateToTopCategory(BuildContext context, String categoryName) {
    if (categoryName != 'None') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionHistoryScreen(
            initialCategory: categoryName,
            ephemeralFilters: true,
          ),
        ),
      );
    }
  }
}

// Optimized recent transactions section
class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({
    required this.transactions,
    required this.responsive,
  });

  final List<dynamic> transactions;
  final ResponsiveUtil responsive;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Recent Transactions',
            action: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionHistoryScreen(),
                ),
              ),
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
          if (transactions.isEmpty)
            const AppEmptyState(
              icon: Icons.receipt_long,
              title: 'No transactions yet',
              subtitle: 'Start by adding your first transaction',
            )
          else
            ...transactions.map((transaction) => 
              Selector<CategoryProvider, dynamic>(
                selector: (_, provider) => provider.getCategoryByName(
                  transaction.category,
                  isIncome: transaction.type == TransactionType.income,
                ),
                builder: (_, category, __) => TransactionItem(
                  transaction: transaction,
                  category: category,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddTransactionScreen(
                        transaction: transaction,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

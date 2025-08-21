import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/providers/transaction_provider.dart';
import 'package:moneymanager/providers/category_provider.dart';
import 'package:moneymanager/utils/currency_util.dart';
import 'package:moneymanager/utils/context_util.dart';
import 'package:moneymanager/utils/category_util.dart';
import 'package:moneymanager/widgets/common/card.dart';
import 'package:moneymanager/widgets/common/filter_chip.dart';
import 'package:moneymanager/widgets/header/section_header.dart';
import 'package:moneymanager/widgets/items/insight_card.dart';
import 'package:moneymanager/widgets/items/summary_cards.dart';
import 'package:moneymanager/widgets/states/empty_state.dart';
import 'package:moneymanager/screens/transaction_history_screen.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with AutomaticKeepAliveClientMixin {
  int _touchedIndex = -1;
  late final DateTimeRange _defaultDateRange;
  DateTimeRange? _selectedDateRange;
  bool _showAllCategories = false;

  // Pre-computed date labels to avoid computation in build
  late final Map<String, DateTimeRange> _quickDateRanges;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _defaultDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    _selectedDateRange = _defaultDateRange;
    _quickDateRanges = _buildQuickDateRanges(now);
  }

  Map<String, DateTimeRange> _buildQuickDateRanges(DateTime now) {
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    return {
      'This Month': DateTimeRange(start: startOfMonth, end: now),
      'Last Month': DateTimeRange(start: lastMonthStart, end: lastMonthEnd),
      'This Year': DateTimeRange(start: startOfYear, end: now),
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: context.isDesktop
          ? null
          : AppBar(
              title: Text(
                'Analytics',
                style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontSize: context.fontSize(20),
                  fontWeight: FontWeight.bold,
                ),
              ),
              elevation: 0,
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: context.spacing()),
                  child: Material(
                    borderRadius: BorderRadius.circular(8),
                    child: Ink(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _showDateRangeOptions,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.calendar,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                _getDateRangeLabel(),
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: context.fontSize(12),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Iconsax.arrow_down_2,
                                  size: 14, color: Colors.grey.shade600),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final range = _selectedDateRange;
          final balance = transactionProvider.getBalance(range: range);
          final income = transactionProvider.getTotalIncome(range: range);
          final expense = transactionProvider.getTotalExpense(range: range);
          final categoryExpenses =
              transactionProvider.getExpensesByCategory(range: range);
          final timeSeriesData = _getTimeSeriesData(transactionProvider);

          if (context.isDesktop) {
            return _buildDesktopLayout(
                balance, income, expense, categoryExpenses, timeSeriesData);
          } else {
            return _buildMobileLayout(
                balance, income, expense, categoryExpenses, timeSeriesData);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(
    double balance,
    double income,
    double expense,
    Map<String, double> categoryExpenses,
    List<Map<String, dynamic>> timeSeriesData,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing(1.5)),
      child: context.constrain(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector for desktop (no header since top bar exists)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _DateRangeSelector(
                  selectedRange: _selectedDateRange,
                  onRangeSelected: (range) {
                    setState(() {
                      _selectedDateRange = range;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: context.spacing(1.5)),

            // Summary cards
            _buildSummarySection(balance, income, expense),
            SizedBox(height: context.spacing(2)),

            // Charts section - Desktop layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Expense breakdown
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildExpenseBreakdownChart(categoryExpenses),
                      SizedBox(height: context.spacing(1.5)),
                      _buildCategoryInsightsCard(categoryExpenses),
                    ],
                  ),
                ),

                SizedBox(width: context.spacing(1.5)),

                // Right column - Spending trend
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildSpendingTrendChart(timeSeriesData),
                      SizedBox(height: context.spacing(1.5)),
                      _buildTrendInsightsCard(timeSeriesData),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    double balance,
    double income,
    double expense,
    Map<String, double> categoryExpenses,
    List<Map<String, dynamic>> timeSeriesData,
  ) {
    return SingleChildScrollView(
      padding: context.screenPadding,
      child: Column(
        children: [
          // Summary Cards
          _buildSummarySection(balance, income, expense),
          SizedBox(height: context.spacing(1.5)),

          // Charts Section
          _buildExpenseBreakdownChart(categoryExpenses),
          SizedBox(height: context.spacing(1.5)),
          _buildSpendingTrendChart(timeSeriesData),
        ],
      ),
    );
  }

  Widget _buildSummarySection(double balance, double income, double expense) {
    return AppSummaryCards(
      balance: balance,
      income: income,
      expense: expense,
      isDesktop: context.isDesktop,
    );
  }

  Widget _buildExpenseBreakdownChart(Map<String, double> categoryExpenses) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Expense Breakdown',
            fontSize: context.fontSize(18),
          ),
          categoryExpenses.isEmpty
              ? AppEmptyState(
                  icon: Iconsax.chart_21,
                  title: 'No expense data available',
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (context.isDesktop) {
                      return Column(
                        children: [
                          SizedBox(
                            height: 250,
                            child: _buildPieChart(categoryExpenses),
                          ),
                          SizedBox(height: context.spacing()),
                          _buildLegendList(categoryExpenses),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: _buildPieChart(categoryExpenses),
                          ),
                          SizedBox(height: context.spacing()),
                          _buildLegendList(categoryExpenses),
                        ],
                      );
                    }
                  },
                )
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> categoryExpenses) {
    if (categoryExpenses.isEmpty) return const SizedBox.shrink();

    final total =
        categoryExpenses.values.fold(0.0, (sum, value) => sum + value);
    final entries = categoryExpenses.entries.toList();

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sectionsSpace: 2,
        centerSpaceRadius:
            context.responsiveValue(mobile: 40, tablet: 50, desktop: 60),
        sections: entries.asMap().entries.map((entry) {
          final index = entry.key;
          final categoryEntry = entry.value;
          final isTouched = index == _touchedIndex;
          final radius = isTouched
              ? context.responsiveValue(
                  mobile: 65.0, tablet: 75.0, desktop: 85.0)
              : context.responsiveValue(
                  mobile: 55.0, tablet: 65.0, desktop: 75.0);

          return PieChartSectionData(
            color: _resolveCategoryColor(categoryEntry.key),
            value: categoryEntry.value,
            title:
                '${((categoryEntry.value / total) * 100).toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              overflow: TextOverflow.ellipsis,
              fontSize: context.fontSize(10),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titlePositionPercentageOffset: 0.55,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendList(Map<String, double> categoryExpenses) {
    final entries = categoryExpenses.entries.toList();
    const maxInitialItems = 3;
    final hasMoreItems = entries.length > maxInitialItems;
    final itemsToShow =
        _showAllCategories ? entries : entries.take(maxInitialItems).toList();

    return Column(
      children: [
        ...itemsToShow.asMap().entries.map((entry) {
          final categoryEntry = entry.value;
          final color = _resolveCategoryColor(categoryEntry.key);
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openCategoryHistory(categoryEntry.key),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          categoryEntry.key,
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            fontSize: context.fontSize(14),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        CurrencyUtil.formatCompact(categoryEntry.value),
                        style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w600,
                          fontSize: context.fontSize(14),
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Iconsax.arrow_right_3,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (hasMoreItems) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() {
                _showAllCategories = !_showAllCategories;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showAllCategories ? 'Show Less' : 'Show More',
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: context.fontSize(14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _showAllCategories
                        ? Iconsax.arrow_up_2
                        : Iconsax.arrow_down_2,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpendingTrendChart(List<Map<String, dynamic>> timeSeriesData) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Spending Trend',
            fontSize: context.fontSize(18),
          ),
          SizedBox(
            height: context.responsiveValue(
                mobile: 250.0, tablet: 300.0, desktop: 350.0),
            child: timeSeriesData.isEmpty
                ? AppEmptyState(
                    icon: Iconsax.chart_1,
                    title: 'No transaction data available',
                  )
                : _buildLineChart(timeSeriesData),
          ),
          if (timeSeriesData.isNotEmpty) ...[
            SizedBox(height: context.spacing()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Income', Colors.green),
                SizedBox(width: context.spacing(1.5)),
                _buildLegendItem('Expense', Colors.red),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> timeSeriesData) {
    final maxYVal = _getMaxValue(timeSeriesData);
    final minYVal = _getMinValue(timeSeriesData);
    final range = (maxYVal - minYVal).abs();
    final pad = range == 0 ? (maxYVal.abs() * 0.1 + 1) : range * 0.1;
    final minY = minYVal - pad;
    final maxY = maxYVal + pad;

    final total = timeSeriesData.length;
    final step = total <= 6 ? 1 : (total / 6).ceil();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (total - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineTouchData: const LineTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 0,
              color: Colors.grey.withOpacity(0.5),
              strokeWidth: 1,
            ),
          ],
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final idx = value.round();
                if (idx < 0 || idx >= total) return const SizedBox.shrink();
                final isEdge = idx == 0 || idx == total - 1;
                if (isEdge || idx % step == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      timeSeriesData[idx]['label'],
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        fontSize: context.fontSize(10),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                CurrencyUtil.formatCompact(value),
                style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontSize: context.fontSize(10),
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: timeSeriesData
                .asMap()
                .entries
                .map((e) => FlSpot(
                      e.key.toDouble(),
                      (e.value['income'] as num).toDouble(),
                    ))
                .toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3.0,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.green,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.1),
            ),
          ),
          LineChartBarData(
            spots: timeSeriesData
                .asMap()
                .entries
                .map((e) => FlSpot(
                      e.key.toDouble(),
                      (e.value['expense'] as num).toDouble(),
                    ))
                .toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 3.0,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.red,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            overflow: TextOverflow.ellipsis,
            fontSize: context.fontSize(12),
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryInsightsCard(Map<String, double> categoryExpenses) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Category Insights',
            fontSize: context.fontSize(16),
          ),
          if (categoryExpenses.isEmpty)
            Text(
              'No category data available',
              style: TextStyle(
                overflow: TextOverflow.ellipsis,
                color: Colors.grey.shade600,
                fontSize: context.fontSize(14),
              ),
            )
          else
            Column(
              children: [
                InsightCard(
                  title: 'Highest Spending',
                  description: categoryExpenses.entries.first.key,
                  icon: Iconsax.arrow_up_2,
                  color: Colors.red,
                ),
                SizedBox(width: context.spacing()),
                InsightCard(
                  title: 'Total Categories',
                  description: '${categoryExpenses.length}',
                  icon: Iconsax.category,
                  color: Colors.blue,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTrendInsightsCard(List<Map<String, dynamic>> timeSeriesData) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Trend Insights',
            fontSize: context.fontSize(16),
          ),
          if (timeSeriesData.isEmpty)
            Text(
              'No trend data available',
              style: TextStyle(
                overflow: TextOverflow.ellipsis,
                color: Colors.grey.shade600,
                fontSize: context.fontSize(14),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: InsightCard(
                    title: 'Data Points',
                    description: '${timeSeriesData.length}',
                    icon: Iconsax.chart_1,
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: context.spacing()),
                Expanded(
                  child: InsightCard(
                    title: 'Period Range',
                    description: _getDateRangeString(),
                    icon: Iconsax.calendar,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _resolveCategoryColor(String categoryName) {
    final provider = context.read<CategoryProvider>();
    final cat = provider.getCategoryByName(categoryName, isIncome: false);
    return _stableCategoryColor(categoryName, cat.color);
  }

  Color _stableCategoryColor(String name, Color fallback) {
    try {
      const palette = CategoryUtil.categoryColors;
      if (palette.isEmpty) return fallback;
      final hash =
          name.codeUnits.fold<int>(0, (acc, c) => (acc * 31 + c) & 0x7fffffff);
      return palette[hash % palette.length];
    } catch (_) {
      return fallback;
    }
  }

  void _openCategoryHistory(String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionHistoryScreen(
          initialType: TransactionType.expense,
          initialCategory: categoryName,
          initialRange: _selectedDateRange,
          ephemeralFilters: true,
        ),
      ),
    );
  }

  double _getMaxValue(List<Map<String, dynamic>> data) {
    double max = 0;
    for (var item in data) {
      if (item['income'] > max) max = item['income'];
      if (item['expense'] > max) max = item['expense'];
    }
    return max;
  }

  double _getMinValue(List<Map<String, dynamic>> data) {
    double min = double.infinity;
    for (var item in data) {
      final income = (item['income'] as num).toDouble();
      final expense = (item['expense'] as num).toDouble();
      if (income < min) min = income;
      if (expense < min) min = expense;
    }
    return min == double.infinity ? 0 : min;
  }

  List<Map<String, dynamic>> _getTimeSeriesData(TransactionProvider provider) {
    if (_selectedDateRange == null) return [];

    final transactions = provider.all;
    final startDate = _selectedDateRange!.start;
    final endDate = _selectedDateRange!.end;
    final daysDifference = endDate.difference(startDate).inDays + 1;

    List<Map<String, dynamic>> data = [];

    if (daysDifference <= 7) {
      // Daily view
      for (int i = 0; i < daysDifference; i++) {
        final date = startDate.add(Duration(days: i));
        final dayTransactions = transactions
            .where((t) =>
                t.date.year == date.year &&
                t.date.month == date.month &&
                t.date.day == date.day)
            .toList();

        final income = dayTransactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (total, t) => total + t.amount);
        final expense = dayTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (total, t) => total + t.amount);

        data.add({
          'label': DateFormat('MMM d').format(date),
          'income': income,
          'expense': expense,
        });
      }
    } else if (daysDifference <= 35) {
      // Weekly view
      final weekStart =
          startDate.subtract(Duration(days: startDate.weekday - 1));
      final weeks = ((endDate.difference(weekStart).inDays) / 7).ceil();

      for (int i = 0; i < weeks; i++) {
        final weekStartDate = weekStart.add(Duration(days: i * 7));
        final weekEndDate = weekStartDate.add(const Duration(days: 6));

        // Only include weeks that overlap with the selected range
        if (weekEndDate.isBefore(startDate) || weekStartDate.isAfter(endDate)) {
          continue;
        }

        final weekTransactions = transactions
            .where((t) =>
                t.date
                    .isAfter(weekStartDate.subtract(const Duration(days: 1))) &&
                t.date.isBefore(weekEndDate.add(const Duration(days: 1))))
            .toList();

        final income = weekTransactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (total, t) => total + t.amount);
        final expense = weekTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (total, t) => total + t.amount);

        data.add({
          'label': 'W${i + 1}',
          'income': income,
          'expense': expense,
        });
      }
    } else {
      // Monthly view
      final monthStart = DateTime(startDate.year, startDate.month, 1);
      final monthEnd = DateTime(endDate.year, endDate.month + 1, 0);
      final months = (monthEnd.year - monthStart.year) * 12 +
          (monthEnd.month - monthStart.month) +
          1;

      for (int i = 0; i < months; i++) {
        final month = DateTime(monthStart.year, monthStart.month + i, 1);
        final monthTransactions = transactions
            .where(
                (t) => t.date.year == month.year && t.date.month == month.month)
            .toList();

        final income = monthTransactions
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (total, t) => total + t.amount);
        final expense = monthTransactions
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (total, t) => total + t.amount);

        data.add({
          'label': DateFormat('MMM').format(month),
          'income': income,
          'expense': expense,
        });
      }
    }

    return data;
  }

  Future<void> _showDateRangeOptions() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildDateRangeBottomSheet(),
    );

    if (result != null) {
      if (result == 'custom') {
        await _selectCustomDateRange();
      } else {
        _setQuickDateRange(result);
      }
    }
  }

  Widget _buildDateRangeBottomSheet() {
    final quickOptions = _quickDateRanges.entries.map((entry) {
      final icon = _getIconForDateRange(entry.key);
      return _buildDateOption(entry.key, icon, entry.key);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.calendar, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Select Time Period',
                style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontSize: context.fontSize(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_selectedDateRange != null) ...[
            const SizedBox(height: 8),
            Text(
              _formatFullRange(_selectedDateRange!),
              style: TextStyle(
                overflow: TextOverflow.ellipsis,
                fontSize: context.fontSize(12),
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 20),
          ...quickOptions,
          const Divider(height: 30),
          _buildDateOption('Custom Range', Iconsax.calendar_edit, 'custom'),
        ],
      ),
    );
  }

  IconData _getIconForDateRange(String rangeName) {
    switch (rangeName) {
      case 'This Month':
        return Iconsax.calendar;
      case 'Last Month':
        return Iconsax.calendar_tick;
      case 'This Year':
        return Iconsax.calendar_search;
      default:
        return Iconsax.calendar;
    }
  }

  Widget _buildDateOption(String title, IconData icon, String value) {
    final isSelected = _isCurrentSelection(value);

    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppColors.primary.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontSize: context.fontSize(14),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(Iconsax.tick_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  bool _isCurrentSelection(String value) {
    if (_selectedDateRange == null) return false;

    final ranges = _quickDateRanges;
    final selectedRange = ranges[value];

    if (selectedRange != null) {
      return _datesEqual(_selectedDateRange!.start, selectedRange.start) &&
          _datesEqual(_selectedDateRange!.end, selectedRange.end);
    }

    // Custom range check
    if (value == 'custom') {
      return !ranges.values.any((range) =>
          _datesEqual(_selectedDateRange!.start, range.start) &&
          _datesEqual(_selectedDateRange!.end, range.end));
    }

    return false;
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _setQuickDateRange(String type) {
    final newRange = _quickDateRanges[type];
    if (newRange != null) {
      setState(() {
        _selectedDateRange = newRange;
      });
    }
  }

  String _getDateRangeLabel() {
    if (_selectedDateRange == null) return 'Select Period';

    // Check for common ranges
    for (final entry in _quickDateRanges.entries) {
      if (_datesEqual(_selectedDateRange!.start, entry.value.start) &&
          _datesEqual(_selectedDateRange!.end, entry.value.end)) {
        return entry.key;
      }
    }

    // Custom range format
    final formatter = DateFormat('MMM d');
    return '${formatter.format(_selectedDateRange!.start)} - ${formatter.format(_selectedDateRange!.end)}';
  }

  String _getDateRangeString() {
    if (_selectedDateRange == null) return 'All Time';
    return '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}';
  }

  bool _datesEqual(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatFullRange(DateTimeRange range) {
    final s = range.start;
    final e = range.end;
    final sameYear = s.year == e.year;
    final sameMonth = sameYear && s.month == e.month;

    if (sameMonth) {
      final month = DateFormat('MMM').format(s);
      return '$month ${s.day}–${e.day}, ${s.year}';
    }
    if (sameYear) {
      return '${DateFormat('MMM d').format(s)} – ${DateFormat('MMM d, y').format(e)}';
    }
    return '${DateFormat('MMM d, y').format(s)} – ${DateFormat('MMM d, y').format(e)}';
  }
}

class _DateRangeSelector extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final Function(DateTimeRange?) onRangeSelected;

  const _DateRangeSelector(
      {required this.selectedRange, required this.onRangeSelected});

  @override
  Widget build(BuildContext context) {
    final ranges = _getDateRanges();
    final selectedLabel = _getRangeLabel(selectedRange);

    return Wrap(
      spacing: 8,
      children: [
        ...ranges.keys.map((label) {
          return AppFilterChip(
            label: label,
            isSelected: selectedLabel == label,
            onTap: () => onRangeSelected(ranges[label]),
          );
        }),
        AppFilterChip(
          label: 'Custom',
          isSelected: selectedLabel == 'Custom',
          onTap: () => _selectCustomDateRange(context),
        ),
      ],
    );
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onRangeSelected(picked);
    }
  }

  String _getRangeLabel(DateTimeRange? range) {
    if (range == null) return 'This Month';

    final ranges = _getDateRanges();
    for (final entry in ranges.entries) {
      if (entry.value.start.isAtSameMomentAs(range.start) &&
          entry.value.end.isAtSameMomentAs(range.end)) {
        return entry.key;
      }
    }
    return 'Custom';
  }

  Map<String, DateTimeRange> _getDateRanges() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    return {
      'This Month': DateTimeRange(start: startOfMonth, end: now),
      'Last Month': DateTimeRange(start: lastMonthStart, end: lastMonthEnd),
      'This Year': DateTimeRange(start: startOfYear, end: now),
    };
  }
}

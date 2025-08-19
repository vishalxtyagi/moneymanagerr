import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/models/analytics_model.dart';
import 'package:moneymanager/core/providers/analytics_provider.dart';
import 'package:moneymanager/core/providers/category_provider.dart';
import 'package:moneymanager/core/utils/currency_util.dart';
import 'package:moneymanager/core/utils/responsive_util.dart';
import 'package:moneymanager/widgets/common/card.dart';
import 'package:moneymanager/widgets/common/date_range_selector.dart';
import 'package:moneymanager/widgets/common/summary_cards.dart';

/// Optimized Analytics Screen with proper Provider usage and minimal rebuilds
class AnalyticsScreenOptimized extends StatefulWidget {
  const AnalyticsScreenOptimized({super.key});

  @override
  State<AnalyticsScreenOptimized> createState() => _AnalyticsScreenOptimizedState();
}

class _AnalyticsScreenOptimizedState extends State<AnalyticsScreenOptimized>
    with AutomaticKeepAliveClientMixin {
  
  // Pre-computed default range
  late final DateTimeRange _defaultRange;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _defaultRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    
    // Initialize analytics provider with default range
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().updateDateRange(_defaultRange);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final responsive = ResponsiveUtil.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: responsive.isDesktop ? null : AppBar(
        title: Text(
          'Analytics',
          style: TextStyle(
            fontSize: responsive.fontSize(20),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: responsive.spacing()),
            child: Selector<AnalyticsProvider, DateTimeRange?>(
              selector: (_, provider) => provider.currentRange,
              builder: (context, range, _) => AppDateRangeSelector(
                selectedRange: range ?? _defaultRange,
                onRangeSelected: (newRange) {
                  context.read<AnalyticsProvider>().updateDateRange(newRange);
                },
                responsive: responsive,
              ),
            ),
          ),
        ],
      ),
      body: Selector<AnalyticsProvider, AnalyticsModel?>(
        selector: (_, provider) => provider.analytics,
        builder: (context, analytics, _) {
          if (analytics == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return responsive.isDesktop
              ? _DesktopLayout(analytics: analytics, responsive: responsive)
              : _MobileLayout(analytics: analytics, responsive: responsive);
        },
      ),
    );
  }
}

/// Desktop layout with optimized two-column structure
class _DesktopLayout extends StatelessWidget {
  final AnalyticsModel analytics;
  final ResponsiveUtil responsive;

  const _DesktopLayout({
    required this.analytics,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.spacing(scale: 1.5)),
      child: responsive.constrain(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _AnalyticsHeader(responsive: responsive),
            SizedBox(height: responsive.spacing(scale: 2)),
            
            // Summary cards
            AppSummaryCards(
              balance: analytics.balance,
              income: analytics.income,
              expense: analytics.expense,
              responsive: responsive,
              isDesktop: true,
            ),
            SizedBox(height: responsive.spacing(scale: 2)),

            // Charts section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _ExpenseBreakdownChart(
                        categoryExpenses: analytics.categoryExpenses,
                        responsive: responsive,
                      ),
                      SizedBox(height: responsive.spacing(scale: 1.5)),
                      _CategoryInsights(
                        categoryExpenses: analytics.categoryExpenses,
                        responsive: responsive,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: responsive.spacing(scale: 1.5)),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _SpendingTrendChart(
                        timeSeriesData: analytics.timeSeriesData,
                        responsive: responsive,
                      ),
                      SizedBox(height: responsive.spacing(scale: 1.5)),
                      _TrendInsights(
                        timeSeriesData: analytics.timeSeriesData,
                        responsive: responsive,
                      ),
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
}

/// Mobile layout with vertical stacking
class _MobileLayout extends StatelessWidget {
  final AnalyticsModel analytics;
  final ResponsiveUtil responsive;

  const _MobileLayout({
    required this.analytics,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: responsive.screenPadding(),
      child: Column(
        children: [
          // Summary Cards
          AppSummaryCards(
            balance: analytics.balance,
            income: analytics.income,
            expense: analytics.expense,
            responsive: responsive,
          ),
          SizedBox(height: responsive.spacing(scale: 1.5)),

          // Charts Section
          _ExpenseBreakdownChart(
            categoryExpenses: analytics.categoryExpenses,
            responsive: responsive,
          ),
          SizedBox(height: responsive.spacing(scale: 1.5)),
          
          _SpendingTrendChart(
            timeSeriesData: analytics.timeSeriesData,
            responsive: responsive,
          ),
        ],
      ),
    );
  }
}

/// Optimized header component
class _AnalyticsHeader extends StatelessWidget {
  final ResponsiveUtil responsive;

  const _AnalyticsHeader({required this.responsive});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Analytics',
              style: TextStyle(
                fontSize: responsive.fontSize(32),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Insights into your spending patterns',
              style: TextStyle(
                fontSize: responsive.fontSize(16),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Selector<AnalyticsProvider, DateTimeRange?>(
          selector: (_, provider) => provider.currentRange,
          builder: (context, range, _) => AppDateRangeSelector(
            selectedRange: range,
            onRangeSelected: (newRange) {
              context.read<AnalyticsProvider>().updateDateRange(newRange);
            },
            responsive: responsive,
          ),
        ),
      ],
    );
  }
}

/// Optimized expense breakdown chart
class _ExpenseBreakdownChart extends StatelessWidget {
  final Map<String, double> categoryExpenses;
  final ResponsiveUtil responsive;

  const _ExpenseBreakdownChart({
    required this.categoryExpenses,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expense Breakdown',
            style: TextStyle(
              fontSize: responsive.fontSize(18),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(scale: 1.5)),
          
          categoryExpenses.isEmpty
              ? _EmptyChart(responsive: responsive)
              : _PieChartSection(
                  categoryExpenses: categoryExpenses,
                  responsive: responsive,
                ),
        ],
      ),
    );
  }
}

/// Pie chart section with legend
class _PieChartSection extends StatefulWidget {
  final Map<String, double> categoryExpenses;
  final ResponsiveUtil responsive;

  const _PieChartSection({
    required this.categoryExpenses,
    required this.responsive,
  });

  @override
  State<_PieChartSection> createState() => _PieChartSectionState();
}

class _PieChartSectionState extends State<_PieChartSection> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return responsive.isDesktop
        ? Column(
            children: [
              SizedBox(
                height: 250,
                child: _buildPieChart(),
              ),
              SizedBox(height: widget.responsive.spacing()),
              _buildLegend(),
            ],
          )
        : Column(
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: _buildPieChart(),
              ),
              SizedBox(height: widget.responsive.spacing()),
              _buildLegend(),
            ],
          );
  }

  Widget _buildPieChart() {
    if (widget.categoryExpenses.isEmpty) return const SizedBox.shrink();

    final total = widget.categoryExpenses.values.fold(0.0, (sum, value) => sum + value);
    final entries = widget.categoryExpenses.entries.toList();

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            if (!mounted) return;
            setState(() {
              if (!event.isInterestedForInteractions ||
                  response == null ||
                  response.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex = response.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: entries.asMap().entries.map((mapEntry) {
          final index = mapEntry.key;
          final entry = mapEntry.value;
          final isTouch = index == _touchedIndex;
          final percentage = (entry.value / total) * 100;
          
          return PieChartSectionData(
            color: _getCategoryColor(entry.key),
            value: entry.value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: isTouch ? 65.0 : 55.0,
            titleStyle: TextStyle(
              fontSize: widget.responsive.fontSize(12),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.categoryExpenses.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: _getCategoryColor(entry.key),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const SizedBox(width: 12, height: 12),
            ),
            const SizedBox(width: 6),
            Text(
              entry.key,
              style: TextStyle(
                fontSize: widget.responsive.fontSize(12),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String categoryName) {
    // Use the same logic from the original analytics screen
    return context.read<CategoryProvider>().getCategoryByName(categoryName, isIncome: false).color;
  }

  ResponsiveUtil get responsive => widget.responsive;
}

/// Empty state for charts
class _EmptyChart extends StatelessWidget {
  final ResponsiveUtil responsive;

  const _EmptyChart({required this.responsive});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Iconsax.chart_21,
            size: responsive.value(mobile: 48.0, tablet: 56.0, desktop: 64.0),
            color: Colors.grey,
          ),
          SizedBox(height: responsive.spacing()),
          Text(
            'No expense data available',
            style: TextStyle(
              color: Colors.grey,
              fontSize: responsive.fontSize(16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Spending trend chart component
class _SpendingTrendChart extends StatelessWidget {
  final List<TimeSeriesItem> timeSeriesData;
  final ResponsiveUtil responsive;

  const _SpendingTrendChart({
    required this.timeSeriesData,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Trend',
            style: TextStyle(
              fontSize: responsive.fontSize(18),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(scale: 1.5)),
          
          SizedBox(
            height: responsive.value(mobile: 250.0, tablet: 300.0, desktop: 350.0),
            child: timeSeriesData.isEmpty
                ? _EmptyChart(responsive: responsive)
                : _LineChart(timeSeriesData: timeSeriesData, responsive: responsive),
          ),
        ],
      ),
    );
  }
}

/// Line chart implementation
class _LineChart extends StatelessWidget {
  final List<TimeSeriesItem> timeSeriesData;
  final ResponsiveUtil responsive;

  const _LineChart({
    required this.timeSeriesData,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) => Text(
                CurrencyUtil.formatCompact(value),
                style: TextStyle(fontSize: responsive.fontSize(10)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < timeSeriesData.length) {
                  return Text(
                    timeSeriesData[index].label,
                    style: TextStyle(fontSize: responsive.fontSize(10)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          // Income line
          LineChartBarData(
            spots: timeSeriesData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.income);
            }).toList(),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
          // Expense line
          LineChartBarData(
            spots: timeSeriesData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.expense);
            }).toList(),
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

/// Category insights component
class _CategoryInsights extends StatelessWidget {
  final Map<String, double> categoryExpenses;
  final ResponsiveUtil responsive;

  const _CategoryInsights({
    required this.categoryExpenses,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryExpenses.isEmpty) return const SizedBox.shrink();

    final topCategory = categoryExpenses.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Insights',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: responsive.spacing()),
          Text(
            'Your highest spending category is ${topCategory.key} with ${CurrencyUtil.formatCompact(topCategory.value)}',
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Trend insights component
class _TrendInsights extends StatelessWidget {
  final List<TimeSeriesItem> timeSeriesData;
  final ResponsiveUtil responsive;

  const _TrendInsights({
    required this.timeSeriesData,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    if (timeSeriesData.length < 2) return const SizedBox.shrink();

    final current = timeSeriesData.last;
    final previous = timeSeriesData[timeSeriesData.length - 2];
    final expenseChange = current.expense - previous.expense;
    final isIncreasing = expenseChange > 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Insights',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: responsive.spacing()),
          Text(
            'Your spending has ${isIncreasing ? 'increased' : 'decreased'} by ${CurrencyUtil.formatCompact(expenseChange.abs())} compared to the previous period',
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: isIncreasing ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

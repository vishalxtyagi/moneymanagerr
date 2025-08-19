import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/providers/transaction_provider.dart';
import 'package:moneymanager/core/providers/category_provider.dart';
import 'package:moneymanager/core/utils/currency_util.dart';
import 'package:moneymanager/core/utils/responsive_util.dart';
import 'package:moneymanager/widgets/common/card.dart';
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _defaultDateRange = _getDateRanges()['This Month']!;
    _selectedDateRange = _defaultDateRange;
  }

  Map<String, DateTimeRange> _getDateRanges() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    return {
      'This Month': DateTimeRange(
        start: startOfMonth,
        end: now,
      ),
      'Last Month': DateTimeRange(
        start: lastMonthStart,
        end: lastMonthEnd,
      ),
      'This Year': DateTimeRange(
        start: startOfYear,
        end: now,
      ),
    };
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
          _DateRangeSelector(
            selectedRange: _selectedDateRange,
            onRangeSelected: (range) {
              setState(() {
                _selectedDateRange = range;
              });
            },
            responsive: responsive,
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final range = _selectedDateRange;
          final balance = transactionProvider.getBalance(range: range);
          final income = transactionProvider.getTotalIncome(range: range);
          final expense = transactionProvider.getTotalExpense(range: range);
          final categoryExpenses = transactionProvider.getExpensesByCategory(range: range);
          final timeSeriesData = _getTimeSeriesData(transactionProvider);

          if (responsive.isDesktop) {
            return _buildDesktopLayout(
              balance, income, expense, categoryExpenses, timeSeriesData, responsive
            );
          } else {
            return _buildMobileLayout(
              balance, income, expense, categoryExpenses, timeSeriesData, responsive
            );
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
    ResponsiveUtil responsive,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.spacing(scale: 1.5)),
      child: responsive.constrain(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date selector
            if (responsive.isDesktop) ...[
              Row(
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
                  _DateRangeSelector(
                    selectedRange: _selectedDateRange,
                    onRangeSelected: (range) {
                      setState(() {
                        _selectedDateRange = range;
                      });
                    },
                    responsive: responsive,
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(scale: 2)),
            ],
            
            // Summary cards
            _buildSummarySection(balance, income, expense, responsive),
            SizedBox(height: responsive.spacing(scale: 2)),

            // Charts section - Desktop layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Expense breakdown
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildExpenseBreakdownChart(categoryExpenses, responsive),
                      SizedBox(height: responsive.spacing(scale: 1.5)),
                      _buildCategoryInsightsCard(categoryExpenses, responsive),
                    ],
                  ),
                ),
                
                SizedBox(width: responsive.spacing(scale: 1.5)),
                
                // Right column - Spending trend
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildSpendingTrendChart(timeSeriesData, responsive),
                      SizedBox(height: responsive.spacing(scale: 1.5)),
                      _buildTrendInsightsCard(timeSeriesData, responsive),
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
    ResponsiveUtil responsive,
  ) {
    return SingleChildScrollView(
      padding: responsive.screenPadding(),
      child: Column(
        children: [
          // Summary Cards
          _buildSummarySection(balance, income, expense, responsive),
          SizedBox(height: responsive.spacing(scale: 1.5)),

          // Charts Section
          _buildExpenseBreakdownChart(categoryExpenses, responsive),
          SizedBox(height: responsive.spacing(scale: 1.5)),
          _buildSpendingTrendChart(timeSeriesData, responsive),
        ],
      ),
    );
  }

  Widget _buildSummarySection(double balance, double income, double expense, ResponsiveUtil responsive) {
    final consumptionRate = income > 0 ? (expense / income) * 100 : 0;
    
    final summaryCards = [
      _buildSummaryCard(
        'Balance',
        balance,
        balance >= 0 ? Colors.green : Colors.red,
        Iconsax.wallet_3,
        responsive,
      ),
      _buildSummaryCard(
        'Income',
        income,
        Colors.green,
        Iconsax.arrow_up_2,
        responsive,
      ),
      _buildSummaryCard(
        'Expense',
        expense,
        Colors.red,
        Iconsax.arrow_down_2,
        responsive,
      ),
      _buildSummaryCard(
        'Spend Rate',
        consumptionRate.toDouble(),
        Colors.orange,
        Iconsax.percentage_circle,
        responsive,
        isPercentage: true,
      ),
    ];

    if (responsive.isDesktop) {
      return Row(
        children: [
          for (int i = 0; i < summaryCards.length; i++) ...[
            Expanded(child: summaryCards[i]),
            if (i < summaryCards.length - 1) SizedBox(width: responsive.spacing()),
          ],
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: summaryCards[0]),
              SizedBox(width: responsive.spacing()),
              Expanded(child: summaryCards[1]),
            ],
          ),
          SizedBox(height: responsive.spacing()),
          Row(
            children: [
              Expanded(child: summaryCards[2]),
              SizedBox(width: responsive.spacing()),
              Expanded(child: summaryCards[3]),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildSummaryCard(
    String title,
    double value,
    Color color,
    IconData icon,
    ResponsiveUtil responsive, {
    bool isPercentage = false,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing()),
          Text(
            isPercentage
                ? '${value.toStringAsFixed(1)}%'
                : CurrencyUtil.formatCompact(value),
            style: TextStyle(
              fontSize: responsive.fontSize(24),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseBreakdownChart(Map<String, double> categoryExpenses, ResponsiveUtil responsive) {
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
              ? Center(
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
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (responsive.isDesktop) {
                      return Column(
                        children: [
                          SizedBox(
                            height: 250,
                            child: _buildPieChart(categoryExpenses, responsive),
                          ),
                          SizedBox(height: responsive.spacing()),
                          _buildLegendList(categoryExpenses, responsive),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: _buildPieChart(categoryExpenses, responsive),
                          ),
                          SizedBox(height: responsive.spacing()),
                          _buildLegendList(categoryExpenses, responsive),
                        ],
                      );
                    }
                  },
                )
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> categoryExpenses, ResponsiveUtil responsive) {
    if (categoryExpenses.isEmpty) return const SizedBox.shrink();

    final total = categoryExpenses.values.fold(0.0, (sum, value) => sum + value);
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
              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        sectionsSpace: 2,
        centerSpaceRadius: responsive.value(mobile: 40, tablet: 50, desktop: 60),
        sections: entries.asMap().entries.map((entry) {
          final index = entry.key;
          final categoryEntry = entry.value;
          final isTouched = index == _touchedIndex;
          final radius = isTouched 
              ? responsive.value(mobile: 65.0, tablet: 75.0, desktop: 85.0)
              : responsive.value(mobile: 55.0, tablet: 65.0, desktop: 75.0);
          
          return PieChartSectionData(
            color: _resolveCategoryColor(categoryEntry.key),
            value: categoryEntry.value,
            title: '${((categoryEntry.value / total) * 100).toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: responsive.fontSize(10),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titlePositionPercentageOffset: 0.55,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendList(Map<String, double> categoryExpenses, ResponsiveUtil responsive) {
    final entries = categoryExpenses.entries.toList();
    final maxInitialItems = responsive.isDesktop ? 6 : 4;
    final hasMoreItems = entries.length > maxInitialItems;
    final itemsToShow = _showAllCategories ? entries : entries.take(maxInitialItems).toList();

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
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                            fontSize: responsive.fontSize(14),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        CurrencyUtil.formatCompact(categoryEntry.value),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: responsive.fontSize(14),
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
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: responsive.fontSize(14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _showAllCategories ? Iconsax.arrow_up_2 : Iconsax.arrow_down_2,
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

  Widget _buildSpendingTrendChart(List<Map<String, dynamic>> timeSeriesData, ResponsiveUtil responsive) {
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.chart_1,
                          size: responsive.value(mobile: 48.0, tablet: 56.0, desktop: 64.0),
                          color: Colors.grey,
                        ),
                        SizedBox(height: responsive.spacing()),
                        Text(
                          'No transaction data available',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: responsive.fontSize(16),
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildLineChart(timeSeriesData, responsive),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> timeSeriesData, ResponsiveUtil responsive) {
    // Implementation of line chart would go here
    // For now, return a placeholder
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.chart_1,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Spending Trend Chart',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chart implementation coming soon',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryInsightsCard(Map<String, double> categoryExpenses, ResponsiveUtil responsive) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Insights',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing()),
          
          if (categoryExpenses.isEmpty)
            Text(
              'No category data available',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: responsive.fontSize(14),
              ),
            )
          else
            Column(
              children: [
                _buildInsightItem(
                  'Highest Spending',
                  categoryExpenses.entries.first.key,
                  Iconsax.arrow_up_2,
                  Colors.red,
                  responsive,
                ),
                const SizedBox(height: 12),
                _buildInsightItem(
                  'Total Categories',
                  '${categoryExpenses.length}',
                  Iconsax.category,
                  Colors.blue,
                  responsive,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTrendInsightsCard(List<Map<String, dynamic>> timeSeriesData, ResponsiveUtil responsive) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Insights',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing()),
          
          if (timeSeriesData.isEmpty)
            Text(
              'No trend data available',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: responsive.fontSize(14),
              ),
            )
          else
            Column(
              children: [
                _buildInsightItem(
                  'Data Points',
                  '${timeSeriesData.length}',
                  Iconsax.chart_1,
                  Colors.green,
                  responsive,
                ),
                const SizedBox(height: 12),
                _buildInsightItem(
                  'Period Range',
                  _getDateRangeString(),
                  Iconsax.calendar,
                  Colors.purple,
                  responsive,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    String title,
    String value,
    IconData icon,
    Color color,
    ResponsiveUtil responsive,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveCategoryColor(String categoryName) {
    return context.read<CategoryProvider>().getCategoryByName(categoryName, isIncome: false).color;
  }

  void _openCategoryHistory(String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionHistoryScreen(
          initialCategory: categoryName,
          initialRange: _selectedDateRange,
          ephemeralFilters: true,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getTimeSeriesData(TransactionProvider provider) {
    // Simplified time series data generation
    return [];
  }

  String _getDateRangeString() {
    if (_selectedDateRange == null) return 'All Time';
    return '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}';
  }
}

class _DateRangeSelector extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final Function(DateTimeRange?) onRangeSelected;
  final ResponsiveUtil responsive;

  const _DateRangeSelector({
    required this.selectedRange,
    required this.onRangeSelected,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _getRangeLabel(selectedRange),
          items: ['This Month', 'Last Month', 'This Year', 'Custom'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              final ranges = _getDateRanges();
              onRangeSelected(ranges[newValue]);
            }
          },
          icon: Icon(
            Iconsax.arrow_down_2,
            size: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
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
      'This Month': DateTimeRange(
        start: startOfMonth,
        end: now,
      ),
      'Last Month': DateTimeRange(
        start: lastMonthStart,
        end: lastMonthEnd,
      ),
      'This Year': DateTimeRange(
        start: startOfYear,
        end: now,
      ),
    };
  }
}

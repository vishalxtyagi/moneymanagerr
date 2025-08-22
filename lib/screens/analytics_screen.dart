import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/providers/transaction_provider.dart';
import 'package:moneymanager/services/analytics_service.dart';
import 'package:moneymanager/services/navigation_service.dart';
import 'package:moneymanager/utils/currency_util.dart';
import 'package:moneymanager/utils/context_util.dart';
import 'package:moneymanager/widgets/common/card.dart';
import 'package:moneymanager/widgets/header/section_header.dart';
import 'package:moneymanager/widgets/items/summary_cards.dart';
import 'package:moneymanager/widgets/states/empty_state.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class AnalyticsScreen extends StatefulWidget {
  final String? title;
  final String? subtitle;
  
  const AnalyticsScreen({
    super.key,
    this.title,
    this.subtitle,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with AutomaticKeepAliveClientMixin {
  int _touchedIndex = -1;
  DateTimeRange? _selectedDateRange;
  List<DateRangeOption> _quickRanges = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _quickRanges = AnalyticsService.getQuickDateRanges();
    _selectedDateRange = _quickRanges.first.range;
  }

  void _onCategoryTap(String categoryName) {
    NavigationService.goToTransactionHistory(
      context,
      initialType: TransactionType.expense,
      initialCategory: categoryName,
      initialDateRange: _selectedDateRange,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: context.isMobile ? AppBar(
        title: Text(widget.title ?? 'Analytics',),
      ) : null,
      body: Column(
        children: [
          // Custom App Bar (only for desktop)
          if (context.isDesktop)
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title ?? 'Analytics',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          widget.subtitle ?? 'Insights and financial trends',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: context.spacing()),
                      child: _DateRangeSelector(
                        selectedRange: _selectedDateRange,
                        quickRanges: _quickRanges,
                        onRangeSelected: (range) {
                          setState(() {
                            _selectedDateRange = range;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ),
          // Main Content
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                final analyticsData = AnalyticsService.calculateAnalytics(
                  transactionProvider.all,
            _selectedDateRange,
          );

                return SingleChildScrollView(
                  padding: context.screenPadding,
                  child: Column(
                    children: [
                      _buildSummarySection(analyticsData),
                      SizedBox(height: context.spacing(1.5)),
                      _buildExpenseBreakdownChart(analyticsData.expensesByCategory),
                      SizedBox(height: context.spacing(1.5)),
                      _buildSpendingTrendChart(analyticsData.timeSeriesData),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(AnalyticsData data) {
    return AppSummaryCards(
      balance: data.balance,
      income: data.income,
      expense: data.expense,
      isDesktop: false,
      onIncomeCardTap: () => _onSummaryCardTap(TransactionType.income),
      onExpenseCardTap: () => _onSummaryCardTap(TransactionType.expense),
    );
  }

  void _onSummaryCardTap(TransactionType type) {
    NavigationService.goToTransactionHistory(
      context,
      initialType: type,
      initialDateRange: _selectedDateRange,
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
              ? const AppEmptyState(
                  icon: Iconsax.chart_21,
                  title: 'No expense data available',
                )
              : Column(
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: _buildPieChart(categoryExpenses),
                    ),
                    SizedBox(height: context.spacing()),
                    _buildLegendList(categoryExpenses),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> categoryExpenses) {
    if (categoryExpenses.isEmpty) return const SizedBox.shrink();

    final entries = categoryExpenses.entries.take(8).toList();
    final colors = [
      const Color(0xFFF44336),
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFFFFEB3B),
      const Color(0xFF795548),
    ];

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

              final sectionIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
              _touchedIndex = sectionIndex;

              // Handle tap to navigate to category transactions
              if (event is FlTapUpEvent && sectionIndex < entries.length) {
                final categoryName = entries[sectionIndex].key;
                _onCategoryTap(categoryName);
              }
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: entries.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final isTouched = index == _touchedIndex;
          final fontSize = isTouched ? 14.0 : 12.0;
          final radius = isTouched ? 65.0 : 55.0;

          return PieChartSectionData(
            color: colors[index % colors.length],
            value: data.value,
            title:
                '${(data.value / categoryExpenses.values.fold(0.0, (a, b) => a + b) * 100).toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendList(Map<String, double> categoryExpenses) {
    final entries = categoryExpenses.entries.take(8).toList();
    final colors = [
      const Color(0xFFF44336),
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFFFFEB3B),
      const Color(0xFF795548),
    ];

    return Column(
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: InkWell(
            onTap: () => _onCategoryTap(data.key),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    CurrencyUtil.format(data.value),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
          timeSeriesData.isEmpty
              ? const AppEmptyState(
                  icon: Iconsax.chart,
                  title: 'No spending data available',
                )
              : SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: null,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value.toInt() >= timeSeriesData.length) {
                                return const Text('');
                              }
                              final date = timeSeriesData[value.toInt()]['date']
                                  as DateTime;
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  DateFormat('M/d').format(date),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: null,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                CurrencyUtil.formatCompact(value),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            },
                            reservedSize: 42,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      minX: 0,
                      maxX: (timeSeriesData.length - 1).toDouble(),
                      minY: 0,
                      maxY: timeSeriesData.isNotEmpty
                          ? timeSeriesData
                                  .map<double>((data) => data['amount'])
                                  .reduce((a, b) => a > b ? a : b) *
                              1.1
                          : 0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: timeSeriesData.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value['amount'],
                            );
                          }).toList(),
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.error.withOpacity(0.3),
                              AppColors.error,
                            ],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.error.withOpacity(0.1),
                                AppColors.error.withOpacity(0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final List<DateRangeOption> quickRanges;
  final Function(DateTimeRange) onRangeSelected;

  const _DateRangeSelector({
    required this.selectedRange,
    required this.quickRanges,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showDateRangeOptions(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.calendar, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  _getDateRangeLabel(),
                  style: TextStyle(
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
    );
  }

  String _getDateRangeLabel() {
    if (selectedRange == null) return 'Select Range';

    for (final range in quickRanges) {
      if (range.range.start == selectedRange!.start &&
          range.range.end == selectedRange!.end) {
        return range.label;
      }
    }

    return '${DateFormat('MMM d').format(selectedRange!.start)} - ${DateFormat('MMM d').format(selectedRange!.end)}';
  }

  void _showDateRangeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Date Range',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...quickRanges.map((option) => ListTile(
                  title: Text(option.label),
                  trailing: selectedRange != null &&
                          option.range.start == selectedRange!.start &&
                          option.range.end == selectedRange!.end
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    onRangeSelected(option.range);
                    Navigator.pop(context);
                  },
                )),
            const Divider(),
            ListTile(
              title: const Text('Custom Range'),
              leading: const Icon(Icons.date_range),
              onTap: () => _selectCustomRange(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCustomRange(BuildContext context) async {
    Navigator.pop(context);

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: selectedRange,
    );

    if (picked != null) {
      onRangeSelected(picked);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/providers/transaction_provider.dart';
import 'package:moneymanager/utils/currency_helper.dart';
import 'package:moneymanager/utils/responsive_helper.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _touchedIndex = -1;
  DateTimeRange? _selectedDateRange;
  bool _showAllCategories = false;

  @override
  void initState() {
    super.initState();
    // Set default date range to current month
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( 
        title: Text(
          'Analytics', 
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: EdgeInsets.only(
              right: ResponsiveHelper.getSpacing(context),
            ),
            child: Material(
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _showDateRangeOptions,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.date_range, size: 18, color: Colors.black),
                        const SizedBox(width: 6),
                        Text(
                          _getDateRangeLabel(),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getFontSize(context, 12),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black),
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
          final balance = transactionProvider.getBalance(dateRange: _selectedDateRange);
          final income = transactionProvider.getTotalIncome(dateRange: _selectedDateRange);
          final expense = transactionProvider.getTotalExpense(dateRange: _selectedDateRange);
          final categoryExpenses = transactionProvider.getCategoryWiseExpenses(dateRange: _selectedDateRange);
          final timeSeriesData = _getTimeSeriesData(transactionProvider);
          final consumptionRate = transactionProvider.getConsumptionRate(dateRange: _selectedDateRange);

          return ResponsiveHelper.constrainWidth(
            context,
            SingleChildScrollView(
              padding: ResponsiveHelper.getScreenPadding(context),
              child: Column(
                children: [
                  // Summary Cards Row
                  _buildSummarySection(balance, income, expense, consumptionRate),
                  SizedBox(height: ResponsiveHelper.getSpacing(context, scale: 1.5)),

                  // Charts Section
                  if (ResponsiveHelper.isDesktop(context)) 
                    _buildDesktopLayout(categoryExpenses, timeSeriesData)
                  else 
                    _buildMobileLayout(categoryExpenses, timeSeriesData),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummarySection(double balance, double income, double expense, double consumptionRate) {
    if (ResponsiveHelper.isDesktop(context)) {
      return Row(
        children: [
          Expanded(child: _buildSummaryCard('Balance', balance, balance >= 0 ? Colors.green : Colors.red, Icons.account_balance_wallet)),
          SizedBox(width: ResponsiveHelper.getSpacing(context)),
          Expanded(child: _buildSummaryCard('Income', income, Colors.green, Icons.arrow_upward)),
          SizedBox(width: ResponsiveHelper.getSpacing(context)),
          Expanded(child: _buildSummaryCard('Expense', expense, Colors.red, Icons.arrow_downward)),
          SizedBox(width: ResponsiveHelper.getSpacing(context)),
          Expanded(child: _buildSummaryCard('Consumption Rate', consumptionRate, Colors.orange, Icons.trending_up, isSavingsRate: true)),
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Balance', balance, balance >= 0 ? Colors.green : Colors.red, Icons.account_balance_wallet)),
              SizedBox(width: ResponsiveHelper.getSpacing(context)),
              Expanded(child: _buildSummaryCard('Income', income, Colors.green, Icons.arrow_upward)),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Expense', expense, Colors.red, Icons.arrow_downward)),
              SizedBox(width: ResponsiveHelper.getSpacing(context)),
              Expanded(child: _buildSummaryCard('Consumption Rate', consumptionRate, Colors.orange, Icons.trending_up, isSavingsRate: true)),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildDesktopLayout(Map<String, double> categoryExpenses, List<Map<String, dynamic>> timeSeriesData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: _buildExpenseBreakdownChart(categoryExpenses),
        ),
        SizedBox(width: ResponsiveHelper.getSpacing(context, scale: 1.5)),
        Expanded(
          flex: 2,
          child: _buildSpendingTrendChart(timeSeriesData),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Map<String, double> categoryExpenses, List<Map<String, dynamic>> timeSeriesData) {
    return Column(
      children: [
        _buildExpenseBreakdownChart(categoryExpenses),
        SizedBox(height: ResponsiveHelper.getSpacing(context, scale: 1.5)),
        _buildSpendingTrendChart(timeSeriesData),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon, {bool isSavingsRate = false}) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(icon, color: color, size: 20),
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: ResponsiveHelper.getFontSize(context, 12),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context, scale: 0.75)),
          Text(
            isSavingsRate 
                ? '${amount.toStringAsFixed(1)}%'
                : CurrencyHelper.formatCompact(amount),
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context, 24),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseBreakdownChart(Map<String, double> categoryExpenses) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expense Breakdown',
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context, scale: 1.5)),
          categoryExpenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pie_chart,
                        size: ResponsiveHelper.responsive(context, mobile: 48.0, tablet: 56.0, desktop: 64.0),
                        color: Colors.grey,
                      ),
                      SizedBox(height: ResponsiveHelper.getSpacing(context)),
                      Text(
                        'No expense data available',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: ResponsiveHelper.getFontSize(context, 16),
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (ResponsiveHelper.isDesktop(context)) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: SizedBox(
                              width: 200,
                              height: 200,
                              child: _buildPieChart(categoryExpenses),
                            ),
                          ),
                          const SizedBox(width: 20),
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
                          const SizedBox(height: 20),
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
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: ResponsiveHelper.responsive(context, mobile: 30.0, tablet: 35.0, desktop: 40.0),
        sections: _generatePieChartSections(categoryExpenses),
      ),
    );
  }

  Widget _buildLegendList(Map<String, double> categoryExpenses) {
    final entries = categoryExpenses.entries.toList();
    final maxInitialItems = ResponsiveHelper.isDesktop(context) ? 5 : 3;
    final hasMoreItems = entries.length > maxInitialItems;
    final itemsToShow = _showAllCategories ? entries : entries.take(maxInitialItems).toList();
    
    return Column(
      children: [
        // Legend items
        ...itemsToShow.asMap().entries.map((entry) {
          final index = entries.indexOf(entry.value);
          final categoryEntry = entry.value;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Material(
                  color: _getCategoryColor(index),
                  borderRadius: BorderRadius.circular(6),
                  child: const SizedBox(width: 12, height: 12),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryEntry.key,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(context, 12),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  CurrencyHelper.formatCompact(categoryEntry.value),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getFontSize(context, 12),
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }),
        
        // Show more/less button
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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _showAllCategories 
                        ? 'Show Less' 
                        : 'Show ${entries.length - maxInitialItems} More',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.getFontSize(context, 12),
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showAllCategories ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blue,
                    size: 18,
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
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Trend',
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context, scale: 1.5)),
          SizedBox(
            height: ResponsiveHelper.responsive(context, mobile: 250.0, tablet: 300.0, desktop: 350.0),
            child: timeSeriesData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart, 
                          size: ResponsiveHelper.responsive(context, mobile: 48.0, tablet: 56.0, desktop: 64.0), 
                          color: Colors.grey,
                        ),
                        SizedBox(height: ResponsiveHelper.getSpacing(context)),
                        Text(
                          'No transaction data available', 
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: ResponsiveHelper.getFontSize(context, 16),
                          ),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxValue(timeSeriesData) * 1.2,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < timeSeriesData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    timeSeriesData[value.toInt()]['label'],
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getFontSize(context, 10),
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                CurrencyHelper.formatCompact(value),
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getFontSize(context, 10),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: timeSeriesData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: data['income'],
                              color: Colors.green,
                              width: ResponsiveHelper.responsive(context, mobile: 8.0, tablet: 10.0, desktop: 12.0),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: data['expense'],
                              color: Colors.red,
                              width: ResponsiveHelper.responsive(context, mobile: 8.0, tablet: 10.0, desktop: 12.0),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
          SizedBox(height: ResponsiveHelper.getSpacing(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Income', Colors.green),
              SizedBox(width: ResponsiveHelper.getSpacing(context, scale: 1.5)),
              _buildLegendItem('Expense', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Material(
          color: color,
          borderRadius: BorderRadius.circular(2),
          child: const SizedBox(width: 12, height: 12),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveHelper.getFontSize(context, 12), 
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _generatePieChartSections(Map<String, double> categoryExpenses) {
    return categoryExpenses.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 70.0 : 60.0;
      
      return PieChartSectionData(
        color: _getCategoryColor(index),
        value: category.value,
        title: isTouched ? category.key : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          backgroundColor: Colors.black87
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(int index) {
    const List<Color> colors = [
      Color(0xFFF44336), Color(0xFF4CAF50), Color(0xFFFFEB3B), Color(0xFFFF9800),
      Color(0xFF2196F3), Color(0xFF9C27B0), Color(0xFF795548), Color(0xFF607D8B),
      Color(0xFFE91E63), Color(0xFF00BCD4),
    ];
    return colors[index % colors.length];
  }

  double _getMaxValue(List<Map<String, dynamic>> data) {
    double max = 0;
    for (var item in data) {
      if (item['income'] > max) max = item['income'];
      if (item['expense'] > max) max = item['expense'];
    }
    return max;
  }

  List<Map<String, dynamic>> _getTimeSeriesData(TransactionProvider provider) {
    if (_selectedDateRange == null) return [];
    
    final transactions = provider.transactions;
    final startDate = _selectedDateRange!.start;
    final endDate = _selectedDateRange!.end;
    final daysDifference = endDate.difference(startDate).inDays + 1;
    
    List<Map<String, dynamic>> data = [];

    if (daysDifference <= 7) {
      // Daily view for 7 days or less
      for (int i = 0; i < daysDifference; i++) {
        final date = startDate.add(Duration(days: i));
        final dayTransactions = transactions.where((t) =>
            t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day).toList();

        final income = dayTransactions
            .where((t) => t.type == 'income')
            .fold(0.0, (sum, t) => sum + t.amount);
        final expense = dayTransactions
            .where((t) => t.type == 'expense')
            .fold(0.0, (sum, t) => sum + t.amount);

        data.add({
          'label': DateFormat('MMM d').format(date),
          'income': income,
          'expense': expense,
        });
      }
    } else if (daysDifference <= 35) {
      // Weekly view for up to 5 weeks
      final weekStart = startDate.subtract(Duration(days: startDate.weekday - 1));
      final weeks = ((endDate.difference(weekStart).inDays) / 7).ceil();
      
      for (int i = 0; i < weeks; i++) {
        final weekStartDate = weekStart.add(Duration(days: i * 7));
        final weekEndDate = weekStartDate.add(const Duration(days: 6));
        
        // Only include weeks that overlap with the selected range
        if (weekEndDate.isBefore(startDate) || weekStartDate.isAfter(endDate)) continue;
        
        final weekTransactions = transactions.where((t) =>
            t.date.isAfter(weekStartDate.subtract(const Duration(days: 1))) &&
            t.date.isBefore(weekEndDate.add(const Duration(days: 1)))).toList();

        final income = weekTransactions
            .where((t) => t.type == 'income')
            .fold(0.0, (sum, t) => sum + t.amount);
        final expense = weekTransactions
            .where((t) => t.type == 'expense')
            .fold(0.0, (sum, t) => sum + t.amount);

        data.add({
          'label': 'W${i + 1}',
          'income': income,
          'expense': expense,
        });
      }
    } else {
      // Monthly view for longer periods
      final monthStart = DateTime(startDate.year, startDate.month, 1);
      final monthEnd = DateTime(endDate.year, endDate.month + 1, 0);
      final months = (monthEnd.year - monthStart.year) * 12 + (monthEnd.month - monthStart.month) + 1;
      
      for (int i = 0; i < months; i++) {
        final month = DateTime(monthStart.year, monthStart.month + i, 1);
        final monthTransactions = transactions.where((t) =>
            t.date.year == month.year && t.date.month == month.month).toList();

        final income = monthTransactions
            .where((t) => t.type == 'income')
            .fold(0.0, (sum, t) => sum + t.amount);
        final expense = monthTransactions
            .where((t) => t.type == 'expense')
            .fold(0.0, (sum, t) => sum + t.amount);

        data.add({
          'label': DateFormat('MMM yyyy').format(month),
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
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Select Time Period',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(context, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Quick options
          _buildDateOption('This Month', Icons.calendar_month, 'This Month'),
          _buildDateOption('Last Month', Icons.calendar_today, 'Last Month'),
          _buildDateOption('This Year', Icons.calendar_view_month, 'This Year'),

          const Divider(height: 30),
          
          // Custom range option
          _buildDateOption('Custom Range', Icons.edit_calendar, 'custom'),
          
          const SizedBox(height: 10),
        ],
      ),
    );
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
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.blue.withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              color: isSelected ? Colors.blue : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getFontSize(context, 14),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.black87,
                ),
              ),
            ),
            if (isSelected) 
              const Icon(Icons.check, color: Colors.blue, size: 20),
          ],
        ),
      ),
    );
  }

  bool _isCurrentSelection(String value) {
    if (_selectedDateRange == null) return false;
    
    final now = DateTime.now();
    final start = _selectedDateRange!.start;
    final end = _selectedDateRange!.end;
    
    switch (value) {
      case 'This Month':
        final thisMonth = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
        return _datesEqual(start, thisMonth.start) && _datesEqual(end, thisMonth.end);
        
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0);
        return _datesEqual(start, lastMonth) && _datesEqual(end, lastMonthEnd);
        
      case 'This Year':
        final thisYear = DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
        return _datesEqual(start, thisYear.start) && _datesEqual(end, thisYear.end);

      default:
        return false;
    }
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
              primary: Colors.blue,
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
    final now = DateTime.now();
    DateTimeRange? newRange;
    
    switch (type) {
      case 'This Month':
        newRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
        break;
        
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        newRange = DateTimeRange(
          start: lastMonth,
          end: DateTime(now.year, now.month, 0),
        );
        break;
        
      case 'This Year':
        newRange = DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
        break;
    }
    
    if (newRange != null) {
      setState(() {
        _selectedDateRange = newRange;
      });
    }
  }

  String _getDateRangeLabel() {
    if (_selectedDateRange == null) return 'Select Period';
    
    final start = _selectedDateRange!.start;
    final end = _selectedDateRange!.end;
    final now = DateTime.now();
    
    // Check for common ranges
    final thisMonth = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    
    final thisYear = DateTimeRange(
      start: DateTime(now.year, 1, 1),
      end: DateTime(now.year, 12, 31),
    );
    
    if (_datesEqual(start, thisMonth.start) && _datesEqual(end, thisMonth.end)) {
      return 'This Month';
    } else if (_datesEqual(start, thisYear.start) && _datesEqual(end, thisYear.end)) {
      return 'This Year';
    } else if (start.year == end.year && start.month == end.month) {
      return DateFormat('MMM yyyy').format(start);
    } else if (start.year == end.year) {
      return '${DateFormat('MMM').format(start)} - ${DateFormat('MMM yyyy').format(end)}';
    } else {
      return '${DateFormat('MMM y').format(start)} - ${DateFormat('MMM y').format(end)}';
    }
  }

  bool _datesEqual(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}

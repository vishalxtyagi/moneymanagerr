import 'package:flutter/material.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/providers/category_provider.dart';
import 'package:moneymanager/screens/add_transaction_screen.dart';
import 'package:moneymanager/widgets/common/card.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/models/transaction_model.dart';
import 'package:moneymanager/providers/transaction_provider.dart';
import 'package:moneymanager/widgets/items/transaction_item.dart';
import 'package:moneymanager/utils/currency_util.dart';
import 'package:moneymanager/utils/context_util.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:provider/provider.dart';

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen>
    with AutomaticKeepAliveClientMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Cache for expensive computations
  final Map<String, List<TransactionModel>> _transactionCache = {};
  final Map<String, double> _totalCache = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  List<TransactionModel> _getTransactionsForDay(
      DateTime day, List<TransactionModel> transactions) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    if (_transactionCache.containsKey(key)) {
      return _transactionCache[key]!;
    }
    
    final dayTransactions = transactions.where((transaction) {
      return isSameDay(transaction.date, day);
    }).toList();
    
    _transactionCache[key] = dayTransactions;
    return dayTransactions;
  }

  double _getTotalForDay(DateTime day, List<TransactionModel> transactions) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    if (_totalCache.containsKey(key)) {
      return _totalCache[key]!;
    }
    
    final dayTransactions = _getTransactionsForDay(day, transactions);
    final total = dayTransactions.fold(0.0, (total, transaction) {
      if (transaction.type == TransactionType.expense) {
        return total - transaction.amount;
      } else {
        return total + transaction.amount;
      }
    });
    
    _totalCache[key] = total;
    return total;
  }

  void _clearCache() {
    _transactionCache.clear();
    _totalCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for keep alive    
    return Scaffold(
      backgroundColor: context.isDesktop ? Colors.grey.shade50 : null,
      appBar: context.isDesktop ? null : AppBar(
        title: const Text('Calendar View'),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final transactions = transactionProvider.all;
          final selectedDayTransactions = _selectedDay != null
              ? _getTransactionsForDay(_selectedDay!, transactions)
              : <TransactionModel>[];

          // Clear cache when transactions change
          if (transactions.isNotEmpty) {
            _clearCache();
          }

          return context.isDesktop
              ? _buildDesktopLayout(transactions, selectedDayTransactions)
              : _buildMobileLayout(transactions, selectedDayTransactions);
        },
      ),
    );
  }

  Widget _buildDesktopLayout(
    List<TransactionModel> transactions,
    List<TransactionModel> selectedDayTransactions,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing(1.5)),
      child: context.constrain(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main content - Two column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column - Calendar and day summary
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Calendar Widget
                      _CalendarWidget(
                        focusedDay: _focusedDay,
                        selectedDay: _selectedDay,
                        calendarFormat: _calendarFormat,
                        transactions: transactions,
                        onDaySelected: (selectedDay, focusedDay) {
                          if (!isSameDay(_selectedDay, selectedDay)) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          }
                        },
                        onFormatChanged: (format) {
                          if (_calendarFormat != format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          }
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        getTransactionsForDay: _getTransactionsForDay,
                        isDesktop: true,
                      ),
                      SizedBox(height: context.spacing()),
                      
                      // Day Summary Card
                      if (_selectedDay != null)
                        _DayInfoHeader(
                          selectedDay: _selectedDay!,
                          totalForDay: _getTotalForDay(_selectedDay!, transactions),
                          transactionCount: selectedDayTransactions.length,
                          isDesktop: true,
                        ),
                    ],
                  ),
                ),
                
                SizedBox(width: context.spacing(1.5)),
                
                // Right column - Transaction list
                Expanded(
                  flex: 3,
                  child: AppCard(
                    child: SizedBox(
                      height: 600, // Fixed height for consistent layout
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section header
                          Text(
                            _selectedDay != null 
                                ? 'Transactions for ${DateFormat('MMM d, y').format(_selectedDay!)}'
                                : 'Select a date to view transactions',
                            style: TextStyle(
                              fontSize: context.fontSize(20),
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: context.spacing()),
                          
                          // Transaction list
                          Expanded(
                            child: selectedDayTransactions.isEmpty
                                ? const _EmptyDayState(isDesktop: true)
                                : _TransactionsList(
                                    transactions: selectedDayTransactions,
                                    isDesktop: true,
                                  ),
                          ),
                        ],
                      ),
                    ),
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
    List<TransactionModel> transactions,
    List<TransactionModel> selectedDayTransactions,
  ) {
    return Column(
      children: [
        // Optimized Calendar Widget
        _CalendarWidget(
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          calendarFormat: _calendarFormat,
          transactions: transactions,
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          getTransactionsForDay: _getTransactionsForDay,
          isDesktop: false,
        ),

        // Optimized Selected Day Section
        Expanded(
          child: _SelectedDaySection(
            selectedDay: _selectedDay,
            transactions: selectedDayTransactions,
            allTransactions: transactions,
            getTotalForDay: _getTotalForDay,
          ),
        ),
      ],
    );
  }
}

// Optimized Calendar Widget Component
class _CalendarWidget extends StatelessWidget {
  const _CalendarWidget({
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.transactions,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
    required this.getTransactionsForDay,
    this.isDesktop = false,
  });

  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final List<TransactionModel> transactions;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;
  final List<TransactionModel> Function(DateTime, List<TransactionModel>) getTransactionsForDay;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop ? BorderRadius.circular(12) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar<TransactionModel>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDay,
        calendarFormat: calendarFormat,
        eventLoader: (day) => getTransactionsForDay(day, transactions),
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: onDaySelected,
        onFormatChanged: onFormatChanged,
        onPageChanged: onPageChanged,
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: Colors.red),
          holidayTextStyle: TextStyle(color: Colors.red),
          selectedDecoration: BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Color(0xFF81C784),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Color(0xFF2E7D32),
            shape: BoxShape.circle,
          ),
          markersMaxCount: 4,
          canMarkersOverflow: false,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: Color(0xFF4CAF50),
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          formatButtonTextStyle: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

// Optimized Selected Day Section Component
class _SelectedDaySection extends StatelessWidget {
  const _SelectedDaySection({
    required this.selectedDay,
    required this.transactions,
    required this.allTransactions,
    required this.getTotalForDay,
  });

  final DateTime? selectedDay;
  final List<TransactionModel> transactions;
  final List<TransactionModel> allTransactions;
  final double Function(DateTime, List<TransactionModel>) getTotalForDay;

  @override
  Widget build(BuildContext context) {
    if (selectedDay == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Selected Day Info
        _DayInfoHeader(
          selectedDay: selectedDay!,
          totalForDay: getTotalForDay(selectedDay!, allTransactions),
          transactionCount: transactions.length,
        ),
        
        // Transactions List
        Expanded(
          child: transactions.isEmpty
              ? const _EmptyDayState()
              : _TransactionsList(transactions: transactions),
        ),
      ],
    );
  }
}

// Day Info Header Component
class _DayInfoHeader extends StatelessWidget {
  const _DayInfoHeader({
    required this.selectedDay,
    required this.totalForDay,
    required this.transactionCount,
    this.isDesktop = false,
  });

  final DateTime selectedDay;
  final double totalForDay;
  final int transactionCount;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(isDesktop ? 0 : 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDesktop 
                ? DateFormat('EEEE, MMMM d, y').format(selectedDay)
                : DateFormat('EEEE, MMMM d, y').format(selectedDay),
            style: TextStyle(
              fontSize: isDesktop ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total for day:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                CurrencyUtil.format(totalForDay),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: totalForDay >= 0 ? const Color(0xFF4CAF50) : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$transactionCount transaction${transactionCount != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Empty Day State Component
class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState({this.isDesktop = false});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions for this day',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Transactions List Component
class _TransactionsList extends StatelessWidget {
  const _TransactionsList({
    required this.transactions,
    this.isDesktop = false,
  });

  final List<TransactionModel> transactions;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isDesktop ? BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ) : null,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: isDesktop ? 0 : 1,
            child: Selector<CategoryProvider, dynamic>(
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
          );
        },
      ),
    );
  }
}

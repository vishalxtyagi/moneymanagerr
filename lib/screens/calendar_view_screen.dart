import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/enums.dart';
import 'package:moneymanager/core/constants/styles.dart';
import 'package:moneymanager/screens/add_transaction_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/core/models/transaction_model.dart';
import 'package:moneymanager/core/providers/transaction_provider.dart';
import 'package:moneymanager/widgets/transaction_item.dart';
import 'package:moneymanager/core/utils/currency_util.dart';
import 'package:provider/provider.dart';

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  List<TransactionModel> _getTransactionsForDay(DateTime day, List<TransactionModel> transactions) {
    return transactions.where((transaction) {
      return isSameDay(transaction.date, day);
    }).toList();
  }

  double _getTotalForDay(DateTime day, List<TransactionModel> transactions) {
    final dayTransactions = _getTransactionsForDay(day, transactions);
    return dayTransactions.fold(0.0, (total, transaction) {
      if (transaction.type == TransactionType.expense) {
        return total - transaction.amount;
      } else {
        return total + transaction.amount;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar View'),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          final transactions = transactionProvider.all;
          final selectedDayTransactions = _selectedDay != null 
              ? _getTransactionsForDay(_selectedDay!, transactions)
              : <TransactionModel>[];

          return Column(
            children: [
              // Calendar Widget
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
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
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  eventLoader: (day) => _getTransactionsForDay(day, transactions),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
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
                    _focusedDay = focusedDay;
                  },
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
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: Color(0xFF4CAF50),
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              // Date Summary
              if (_selectedDay != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppStyles.borderRadius),
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
                        DateFormat('EEEE, MMMM d, y').format(_selectedDay!),
                        style: const TextStyle(
                          fontSize: 18,
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
                            CurrencyUtil.format(_getTotalForDay(_selectedDay!, transactions)),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getTotalForDay(_selectedDay!, transactions) >= 0 
                                  ? const Color(0xFF4CAF50) 
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${selectedDayTransactions.length} transaction${selectedDayTransactions.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

              // Transactions List
              Expanded(
                child: selectedDayTransactions.isEmpty
                    ? Center(
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
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: selectedDayTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = selectedDayTransactions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: TransactionItem(
                              transaction: transaction,
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
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

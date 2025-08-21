import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moneymanager/utils/context_util.dart';

/// Optimized date range selector widget - extracted from analytics screen
class AppDateRangeSelector extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final Function(DateTimeRange) onRangeSelected;

  const AppDateRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeSelected,
  });

  // Pre-computed date ranges for performance
  static Map<String, DateTimeRange> _buildDateRanges() {
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

  String _getDateRangeLabel() {
    if (selectedRange == null) return 'Select Range';

    final ranges = _buildDateRanges();
    for (final entry in ranges.entries) {
      if (entry.value.start.isAtSameMomentAs(selectedRange!.start) &&
          entry.value.end.isAtSameMomentAs(selectedRange!.end)) {
        return entry.key;
      }
    }

    return 'Custom Range';
  }

  void _showDateRangeOptions(BuildContext context) {
    final ranges = _buildDateRanges();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _DateRangeBottomSheet(
        ranges: ranges,
        onRangeSelected: onRangeSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showDateRangeOptions(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.date_range, size: 18),
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
              const Icon(Icons.arrow_drop_down, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optimized bottom sheet for date range selection
class _DateRangeBottomSheet extends StatelessWidget {
  final Map<String, DateTimeRange> ranges;
  final Function(DateTimeRange) onRangeSelected;

  const _DateRangeBottomSheet({
    required this.ranges,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.spacing()),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Date Range',
            style: TextStyle(
              overflow: TextOverflow.ellipsis,
              fontSize: context.fontSize(18),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.spacing()),

          // Pre-built quick date options
          ...ranges.entries.map((entry) => ListTile(
                title: Text(entry.key),
                onTap: () {
                  onRangeSelected(entry.value);
                  context.pop();
                },
              )),

          // Custom date picker option
          ListTile(
            title: const Text('Custom Range'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              context.pop();
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: ranges['This Month'],
              );
              if (range != null) {
                onRangeSelected(range);
              }
            },
          ),
        ],
      ),
    );
  }
}

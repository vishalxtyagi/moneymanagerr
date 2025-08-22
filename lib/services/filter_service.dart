import 'package:flutter/material.dart';
import 'package:moneymanager/constants/enums.dart';

class FilterState {
  final TransactionType type;
  final String? category;
  final DateTimeRange? dateRange;
  final String query;

  const FilterState({
    this.type = TransactionType.all,
    this.category,
    this.dateRange,
    this.query = '',
  });

  FilterState copyWith({
    TransactionType? type,
    String? category,
    DateTimeRange? dateRange,
    String? query,
    bool clearCategory = false,
    bool clearDateRange = false,
  }) {
    return FilterState(
      type: type ?? this.type,
      category: clearCategory ? null : (category ?? this.category),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      query: query ?? this.query,
    );
  }

  bool get hasActiveFilters =>
      type != TransactionType.all ||
      category != null ||
      dateRange != null ||
      query.isNotEmpty;

  FilterState clear() => const FilterState();
}

class FilterService {
  static FilterState createDefault() => const FilterState();

  static FilterState setType(FilterState current, TransactionType type) {
    // If changing from a specific type to 'all' or between income/expense,
    // clear the category since it may not be valid for the new type
    if (current.type != type &&
        (type == TransactionType.all ||
            (current.type != TransactionType.all &&
                type != TransactionType.all))) {
      return current.copyWith(type: type, clearCategory: true);
    }
    return current.copyWith(type: type);
  }

  static FilterState setCategory(FilterState current, String? category) {
    return current.copyWith(category: category);
  }

  static FilterState setDateRange(FilterState current, DateTimeRange? range) {
    if (range == null) {
      return current.copyWith(clearDateRange: true);
    }
    return current.copyWith(dateRange: range);
  }

  static FilterState setQuery(FilterState current, String query) {
    return current.copyWith(query: query);
  }

  static FilterState clearAll(FilterState current) {
    return current.clear();
  }
}

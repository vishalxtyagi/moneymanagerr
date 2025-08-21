import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../screens/auth_screen.dart';
import '../../screens/main_navigation_screen.dart';
import '../../screens/add_transaction_screen.dart';
import '../../screens/transaction_history_screen.dart';
import '../../screens/settings/category_manager_screen.dart';
import '../models/transaction_model.dart';

class AppRouter {
  static const String auth = '/auth';
  static const String dashboard = '/';
  static const String analytics = '/analytics';
  static const String calendar = '/calendar';
  static const String settings = '/settings';
  static const String addTransaction = '/add-transaction';
  static const String editTransaction = '/edit-transaction';
  static const String transactionHistory = '/history';
  static const String categoryManager = '/settings/categories';
  
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: dashboard,
      redirect: (BuildContext context, GoRouterState state) {
        final authProvider = context.read<AuthProvider>();
        final isSignedIn = authProvider.isSignedIn;
        final isAuthRoute = state.matchedLocation == auth;

        // If not signed in and not on auth route, redirect to auth
        if (!isSignedIn && !isAuthRoute) {
          return auth;
        }

        // If signed in and on auth route, redirect to dashboard
        if (isSignedIn && isAuthRoute) {
          return dashboard;
        }

        // No redirect needed
        return null;
      },
      routes: [
        GoRoute(
          path: auth,
          name: 'auth',
          builder: (context, state) => const AuthScreen(),
        ),
        // Main navigation routes
        GoRoute(
          path: dashboard,
          name: 'dashboard',
          builder: (context, state) => const MainNavigationScreen(),
        ),
        GoRoute(
          path: analytics,
          name: 'analytics',
          builder: (context, state) => const MainNavigationScreen(initialIndex: 1),
        ),
        GoRoute(
          path: calendar,
          name: 'calendar',
          builder: (context, state) => const MainNavigationScreen(initialIndex: 2),
        ),
        GoRoute(
          path: settings,
          name: 'settings',
          builder: (context, state) => const MainNavigationScreen(initialIndex: 3),
        ),
        // Modal/overlay routes
        GoRoute(
          path: addTransaction,
          name: 'add-transaction',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return AddTransactionScreen(
              onClose: extra?['onClose'],
            );
          },
        ),
        GoRoute(
          path: editTransaction,
          name: 'edit-transaction',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final transaction = extra?['transaction'] as TransactionModel?;
            return AddTransactionScreen(
              transaction: transaction,
              onClose: extra?['onClose'],
            );
          },
        ),
        GoRoute(
          path: transactionHistory,
          name: 'transaction-history',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return TransactionHistoryScreen(
              initialRange: extra?['initialRange'],
              initialCategory: extra?['initialCategory'],
              ephemeralFilters: extra?['ephemeralFilters'] ?? false,
            );
          },
        ),
        GoRoute(
          path: categoryManager,
          name: 'category-manager',
          builder: (context, state) => const CategoryManagerScreen(),
        ),
      ],
    );
  }
}

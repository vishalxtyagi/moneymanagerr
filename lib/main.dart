import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'constants/themes.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/analytics_provider.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    final notificationService = NotificationService();
    await notificationService.initialize();

    runApp(const MoneyManagerApp());
  } catch (e) {
    debugPrint('App initialization failed: $e');
    runApp(const _ErrorApp());
  }
}

class MoneyManagerApp extends StatelessWidget {
  const MoneyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (_) => TransactionProvider(),
          update: (_, auth, transaction) {
            transaction?.updateAuth(auth.user);
            return transaction ?? TransactionProvider();
          },
        ),
        ChangeNotifierProxyProvider<TransactionProvider, AnalyticsProvider>(
          create: (context) =>
              AnalyticsProvider(context.read<TransactionProvider>()),
          update: (_, transaction, analytics) =>
              analytics ?? AnalyticsProvider(transaction),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: 'Money Manager',
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme,
            routerConfig: AppRouter.createRouter(authProvider),
          );
        },
      ),
    );
  }
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('App failed to initialize. Please restart.')),
      ),
    );
  }
}

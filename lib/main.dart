import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/constants/themes.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/category_provider.dart';
import 'core/providers/transaction_provider.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'core/services/notification_service.dart';

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
      ],
      child: MaterialApp(
        title: 'Money Manager',
        debugShowCheckedModeBanner: false,
        theme: AppThemes.lightTheme,
        home: const _AuthChecker(),
      ),
    );
  }
}

class _AuthChecker extends StatelessWidget {
  const _AuthChecker();

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, bool>(
      selector: (_, auth) => auth.isSignedIn,
      builder: (_, isSignedIn, __) =>
          isSignedIn ? const MainNavigationScreen() : const AuthScreen(),
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

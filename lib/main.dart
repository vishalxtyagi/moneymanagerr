import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:moneymanager/constants/constants.dart';
import 'package:moneymanager/firebase_options.dart';
import 'package:moneymanager/providers/auth_provider.dart';
import 'package:moneymanager/providers/category_provider.dart';
import 'package:moneymanager/providers/transaction_provider.dart';
import 'package:moneymanager/screens/auth_screen.dart';
import 'package:moneymanager/shared/services/notification_service.dart';
import 'package:moneymanager/shared/widgets/main_navigation.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        Provider.value(value: notificationService),
      ],
      child: const MoneyManagerApp(),
    ),
  );
}

class MoneyManagerApp extends StatelessWidget {
  const MoneyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Manager',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: ThemeMode.system,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return authProvider.user == null
              ? const AuthScreen()
              : const MainNavigation();
        },
      ),
    );
  }
}

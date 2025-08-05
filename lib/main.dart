import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'widgets/main_navigation.dart';
import 'core/constants/themes.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/category_provider.dart';
import 'core/providers/transaction_provider.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'core/services/notification_service.dart';

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

class MoneyManagerApp extends StatefulWidget {
  const MoneyManagerApp({super.key});

  @override
  State<MoneyManagerApp> createState() => _MoneyManagerAppState();
}


class _MoneyManagerAppState extends State<MoneyManagerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.ensurePersistentNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Manager',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      themeMode: ThemeMode.light,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return authProvider.isSignedIn
              ? const MainNavigation()
              : const AuthScreen();
        },
      ),
    );
  }
}

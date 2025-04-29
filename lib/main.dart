import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mybudget/presentation/screens/accounts_screen.dart';
import 'package:mybudget/presentation/screens/dashboard_screen.dart';
import 'package:mybudget/presentation/screens/expenses_screen.dart';
import 'package:mybudget/presentation/screens/login_screen.dart';
import 'package:mybudget/presentation/screens/register_screen.dart';
import 'package:mybudget/presentation/screens/revenues_screen.dart';
import 'package:mybudget/presentation/screens/settings_screen.dart';
import 'package:mybudget/presentation/screens/splash_screen.dart';
import 'package:mybudget/core/services/hive_service.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/data/models/category_model.dart';
import 'package:mybudget/data/models/user_model.dart';
import 'package:mybudget/presentation/providers/auth_provider.dart';
import 'package:mybudget/presentation/providers/account_provider.dart';
import 'package:mybudget/presentation/providers/category_provider.dart';
import 'package:mybudget/presentation/providers/expense_provider.dart';
import 'package:mybudget/presentation/providers/revenue_provider.dart';
import 'package:mybudget/presentation/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Fichier .env non trouvé, mais ce n'est pas bloquant
  }

  final hiveService = HiveService();
  await hiveService.init();
  
  // Enregistrer les adaptateurs
  hiveService.registerAdapter(CategoryModelAdapter());
  hiveService.registerAdapter(UserModelAdapter());

  final container = ProviderContainer();
  
  // Précharger les données au démarrage
  container.read(accountNotifierProvider.notifier).getAccounts();
  container.read(expenseNotifierProvider.notifier).getExpenses();
  container.read(revenueNotifierProvider.notifier).getRevenues();
  container.read(categoryNotifierProvider.notifier).getCategories();
  container.read(authProvider.notifier).getCurrentUser();

  runApp(ProviderScope(parent: container, child: const MyApp()));
}

// On utilise le routeurProvider défini dans auth_middleware.dart

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Budget',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const DashboardScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/expenses': (context) => const ExpensesScreen(),
        '/revenues': (context) => const RevenuesScreen(),
        '/accounts': (context) => const AccountsScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

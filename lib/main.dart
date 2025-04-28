import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/presentation/screens/accounts_screen.dart';
import 'package:mybudget/presentation/screens/dashboard_screen.dart';
import 'package:mybudget/presentation/screens/expenses_screen.dart';
import 'package:mybudget/presentation/screens/revenues_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    GoRoute(path: '/expenses', builder: (context, state) => const ExpensesScreen()),
    GoRoute(path: '/revenues', builder: (context, state) => const RevenuesScreen()),
    GoRoute(path: '/accounts', builder: (context, state) => const AccountsScreen()),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});



  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'My Budget',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: _router,

    );
  }
}



import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mybudget/ui/splash/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:mybudget/core/services/objectbox_service.dart';

import 'package:mybudget/ui/accounts/accounts_viewmodel.dart';
import 'package:mybudget/ui/expenses/expenses_viewmodel.dart';
import 'package:mybudget/ui/loans/loans_viewmodel.dart';
import 'package:mybudget/ui/revenues/revenues_viewmodel.dart';
import 'package:mybudget/ui/settings/settings_viewmodel.dart';
import 'package:mybudget/ui/settings/category_viewmodel.dart';
import 'package:mybudget/ui/settings/data_viewmodel.dart';
import 'package:mybudget/ui/settings/update_viewmodel.dart';
import 'package:mybudget/core/theme/theme_viewmodel.dart';
import 'package:mybudget/ui/dashboard/dashboard_viewmodel.dart';
import 'package:mybudget/core/repositories/expense_repository.dart';
import 'package:mybudget/core/repositories/revenue_repository.dart';
import 'package:mybudget/core/repositories/account_repository.dart';
import 'package:mybudget/core/repositories/loan_repository.dart';
import 'package:mybudget/core/repositories/category_repository.dart';

import 'package:mybudget/core/services/preferences_service.dart';

import 'package:mybudget/utils/restart_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PreferencesService.init();

  await initializeDateFormatting('fr_FR', null);

  runApp(
    RestartWidget(
      onRestart: () async {
        await ObjectBoxService.resetInstance();
        await ObjectBoxService.getInstance();
      },
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ObjectBoxService>(
      future: ObjectBoxService.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Directionality(
            textDirection: TextDirection.ltr,
            child: ColoredBox(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              color: Colors.red,
              child: Center(
                child: Text(
                  'Erreur critique: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          );
        }

        final objectBoxService = snapshot.data!;

        return MultiProvider(
          providers: [
            Provider<ObjectBoxService>.value(value: objectBoxService),

            Provider<ExpenseRepository>(
              create: (_) => ExpenseRepository(objectBoxService.expenseBox),
            ),
            Provider<RevenueRepository>(
              create: (_) => RevenueRepository(objectBoxService.revenueBox),
            ),
            Provider<AccountRepository>(
              create: (_) => AccountRepository(objectBoxService.accountBox),
            ),
            Provider<LoanRepository>(
              create: (_) => LoanRepository(objectBoxService.loanBox),
            ),
            Provider<CategoryRepository>(
              create: (_) => CategoryRepository(objectBoxService.categoryBox),
            ),

            ChangeNotifierProvider(create: (_) => SettingsViewModel()),
            ChangeNotifierProvider(create: (_) => UpdateViewModel()),
            ChangeNotifierProvider(create: (_) => ThemeViewModel()),

            ChangeNotifierProvider(
              create:
                  (context) =>
                      CategoryViewModel(context.read<CategoryRepository>()),
            ),
            ChangeNotifierProvider(
              create:
                  (context) => ExpenseViewModel(
                    context.read<ExpenseRepository>(),
                    context.read<CategoryRepository>(),
                  ),
            ),
            ChangeNotifierProvider(
              create:
                  (context) =>
                      RevenueViewModel(context.read<RevenueRepository>()),
            ),
            ChangeNotifierProvider(
              create:
                  (context) => LoanViewModel(context.read<LoanRepository>()),
            ),

            ChangeNotifierProxyProvider4<
              AccountRepository,
              ExpenseViewModel,
              RevenueViewModel,
              LoanViewModel,
              AccountViewModel
            >(
              create:
                  (context) => AccountViewModel(
                    context.read<AccountRepository>(),
                    context.read<ExpenseViewModel>(),
                    context.read<RevenueViewModel>(),
                    context.read<LoanViewModel>(),
                  ),
              update:
                  (
                    context,
                    accountRepo,
                    expenseVM,
                    revenueVM,
                    loanVM,
                    previous,
                  ) =>
                      previous ??
                      AccountViewModel(
                        accountRepo,
                        expenseVM,
                        revenueVM,
                        loanVM,
                      ),
            ),

            ChangeNotifierProvider(
              create:
                  (context) => DataViewModel(
                    context.read<AccountRepository>(),
                    context.read<ExpenseRepository>(),
                    context.read<RevenueRepository>(),
                    context.read<LoanRepository>(),
                    context.read<CategoryRepository>(),
                    context.read<AccountViewModel>(),
                    context.read<ExpenseViewModel>(),
                    context.read<RevenueViewModel>(),
                    context.read<LoanViewModel>(),
                  ),
            ),

            ChangeNotifierProvider(
              create:
                  (context) => DashboardViewModel(
                    context.read<AccountViewModel>(),
                    context.read<ExpenseViewModel>(),
                    context.read<RevenueViewModel>(),
                    context.read<LoanViewModel>(),
                    context.read<SettingsViewModel>(),
                  ),
            ),
          ],
          child: DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              return Consumer<ThemeViewModel>(
                builder: (context, themeViewModel, child) {
                  return MaterialApp(
                    debugShowCheckedModeBanner: false,
                    title: 'My Budget',
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: const [Locale('fr')],
                    theme: themeViewModel.getLightTheme(
                      dynamicColorScheme: lightDynamic,
                    ),
                    darkTheme: themeViewModel.getDarkTheme(
                      dynamicColorScheme: darkDynamic,
                    ),
                    themeMode: themeViewModel.themeMode,
                    home: const SplashScreen(),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

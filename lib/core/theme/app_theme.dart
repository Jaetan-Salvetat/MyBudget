import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/finance_colors.dart';
import 'package:mybudget/core/theme/text_styles.dart';

class AppTheme {
  AppTheme._();

  static const Color seedColor = Color(0xFF2A55D3);
  static const Color secondaryColor = Color(0xFF6750A4);

  static ThemeData light() => _appearance(
    FrostedTheme.light(seedColor: seedColor),
    FinanceColors.light,
  );

  static ThemeData dark() =>
      _appearance(FrostedTheme.dark(seedColor: seedColor), FinanceColors.dark);

  static ThemeData _appearance(ThemeData frosted, FinanceColors finance) {
    return frosted.copyWith(
      colorScheme: frosted.colorScheme.copyWith(secondary: secondaryColor),
      textTheme: AppTextStyles.buildTextTheme(frosted.brightness),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      extensions: <ThemeExtension<dynamic>>[
        frosted.extension<FrostedTokens>()!,
        finance,
      ],
    );
  }
}

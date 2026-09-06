import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mybudget/core/theme/flutter_material_mapper.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextTheme buildTextTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.whiteMountainView
        : Typography.blackMountainView;
    return FlutterMaterialMapper.toTextTheme(
      GoogleFonts.interTextTheme(FlutterMaterialMapper.toLegacyTextTheme(base)),
    ).apply(
      bodyColor: brightness == Brightness.dark
          ? const Color(0xFFE5E1E6)
          : const Color(0xFF1C1B1F),
      displayColor: brightness == Brightness.dark
          ? const Color(0xFFE5E1E6)
          : const Color(0xFF1C1B1F),
    );
  }

  static TextStyle displaySerifItalic({
    double fontSize = 48,
    double? height,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.ptSerif(
      fontSize: fontSize,
      fontStyle: FontStyle.italic,
      fontWeight: fontWeight,
      height: height,
      color: color,
      letterSpacing: -0.02 * fontSize,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle eyebrowMono({Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 10,
      height: 14 / 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.0,
      color: color,
    );
  }

  static TextStyle mono({
    required double fontSize,
    double? lineHeight,
    FontWeight fontWeight = FontWeight.w500,
    double letterSpacingEm = 0,
    Color? color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: (lineHeight ?? 14) / fontSize,
      letterSpacing: letterSpacingEm * fontSize,
      color: color,
    );
  }

  static TextStyle amount({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: -0.01 * fontSize,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle heroAmount({Color? color}) {
    return displaySerifItalic(fontSize: 56, height: 1, color: color);
  }
}

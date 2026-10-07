import 'package:flutter/material.dart';

/// Dizayn tokenlari. Qiymatlar landing sahifadagi (imlogo.uz) `globals.css`
/// bilan bir xil — ikkalasi birga o'zgartirilishi kerak.
class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F5FC);
  static const foreground = Color(0xFF171717);
  static const muted = Color(0xFF5B6072);
  static const line = Color(0x246750A4);

  static const primary = Color(0xFF6750A4);
  static const primaryAccent = Color(0xFF3107A3);
  static const secondary = Color(0xFF304FFF);
  static const tertiary = Color(0xFFFDE096);

  static const success = Color(0xFF2E9E5B);
  static const error = Color(0xFFE5484D);
  static const errorDeep = Color(0xFF9F1D2C);

  /// Logotip ranglari (faqat `AppLogo` uchun).
  static const logoPurple = Color(0xFFAF6EFF);
  static const logoBlack = Color(0xFF000000);

  static const brandGradient = LinearGradient(colors: [primary, secondary]);
}

/// Soyalar har doim binafsha/ko'k tusda — sof qora soya ishlatilmaydi.
class AppShadows {
  static const glow = [
    BoxShadow(color: Color(0x806750A4), blurRadius: 20, spreadRadius: -5),
  ];
  static const glowLarge = [
    BoxShadow(color: Color(0x8C304FFF), blurRadius: 30, spreadRadius: -5),
  ];
  static const glowCard = [
    BoxShadow(color: Color(0x596750A4), blurRadius: 30, spreadRadius: -10),
  ];
  static const glowSoft = [
    BoxShadow(color: Color(0x2E6750A4), blurRadius: 50, spreadRadius: -10),
  ];
}

class AppRadius {
  static const double card = 16;
  static const double input = 12;
  static const double pill = 999;
}

/// Sarlavhalar — Space Grotesk, matn — Inter, raqam va yorliqlar — JetBrains Mono.
class AppText {
  static const _heading = 'SpaceGrotesk';
  static const _body = 'Inter';
  static const monoFamily = 'JetBrainsMono';

  static TextStyle _style(
    String family,
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      // O'zgaruvchan shriftda qalinlik `wght` o'qi orqali beriladi.
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle heading(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.foreground,
  }) =>
      _style(_heading, size, weight, color, height: 1.2);

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.foreground,
    double height = 1.5,
  }) =>
      _style(_body, size, weight, color, height: height);

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.foreground,
    double? height,
    double? letterSpacing,
  }) =>
      _style(monoFamily, size, weight, color,
          height: height, letterSpacing: letterSpacing);

  /// Bosh harflarda yoziladigan kichik texnik yorliq.
  static TextStyle label({
    double size = 11,
    Color color = AppColors.muted,
  }) =>
      mono(size, color: color, letterSpacing: size * 0.14);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.background,
    error: AppColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Inter',
    splashFactory: NoSplash.splashFactory,
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.primary),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.foreground,
      contentTextStyle: AppText.body(14, color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: Color(0x336750A4),
      selectionHandleColor: AppColors.primary,
    ),
  );
}

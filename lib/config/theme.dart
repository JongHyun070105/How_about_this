import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';

class AppTheme {
  static ThemeData light() {
    return _buildLightTheme();
  }

  static ThemeData dark() {
    return _buildDarkTheme();
  }

  static ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: Colors.black,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: Colors.blue,
        surface: Colors.white,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: _buildAppBarTheme(Brightness.light),
      elevatedButtonTheme: _buildElevatedButtonTheme(Brightness.light),
      inputDecorationTheme: _buildInputDecorationTheme(Brightness.light),
      chipTheme: _buildChipTheme(Brightness.light),
      cardTheme: _buildCardTheme(Brightness.light),
      snackBarTheme: _buildSnackBarTheme(Brightness.light),
      dialogTheme: _buildDialogTheme(Brightness.light),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    final darkSurface = Colors.grey[900]!;
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      primaryColor: Colors.white,
      colorScheme: ColorScheme.dark(
        primary: Colors.white,
        secondary: Colors.blue.shade300,
        surface: darkSurface,
        error: Colors.red.shade400,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: _buildAppBarTheme(Brightness.dark),
      elevatedButtonTheme: _buildElevatedButtonTheme(Brightness.dark),
      inputDecorationTheme: _buildInputDecorationTheme(Brightness.dark),
      chipTheme: _buildChipTheme(Brightness.dark),
      cardTheme: _buildCardTheme(Brightness.dark),
      snackBarTheme: _buildSnackBarTheme(Brightness.dark),
      dialogTheme: _buildDialogTheme(Brightness.dark),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    const fontFamily = 'SCDream';
    final textColor = brightness == Brightness.light
        ? Colors.black
        : Colors.white;
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w300,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w400,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w300,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w400,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        color: textColor,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return AppBarTheme(
      backgroundColor: isLight ? Colors.white : Colors.black,
      foregroundColor: isLight ? Colors.black : Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'SCDream',
        color: isLight ? Colors.black : Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    Brightness brightness,
  ) {
    final isLight = brightness == Brightness.light;
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isLight ? Colors.black : Colors.white,
        foregroundColor: isLight ? Colors.white : Colors.black,
        disabledBackgroundColor: isLight ? Colors.grey : Colors.grey.shade800,
        disabledForegroundColor: isLight ? Colors.white : Colors.white60,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'SCDream',
        ),
        elevation: 2,
        shadowColor: isLight ? Colors.black26 : Colors.black87,
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(
    Brightness brightness,
  ) {
    final isLight = brightness == Brightness.light;
    return InputDecorationTheme(
      labelStyle: TextStyle(
        color: isLight ? Colors.black54 : Colors.white70,
        fontFamily: 'SCDream',
        fontWeight: FontWeight.w400,
      ),
      hintStyle: TextStyle(
        color: isLight ? Colors.black38 : Colors.white38,
        fontFamily: 'SCDream',
        fontWeight: FontWeight.w300,
      ),
      filled: true,
      fillColor: isLight ? const Color(0xFFF5F5F5) : Colors.grey[850],
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: isLight ? const Color(0xFFE0E0E0) : Colors.grey[800]!,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: isLight ? Colors.black : Colors.white,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  static ChipThemeData _buildChipTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return ChipThemeData(
      backgroundColor: isLight ? const Color(0xFFF5F5F5) : Colors.grey[850],
      selectedColor: isLight ? Colors.black : Colors.white,
      disabledColor: isLight ? Colors.grey.shade300 : Colors.grey.shade800,
      labelStyle: TextStyle(
        color: isLight ? Colors.black : Colors.white,
        fontFamily: 'SCDream',
        fontWeight: FontWeight.w400,
      ),
      secondaryLabelStyle: TextStyle(
        color: isLight ? Colors.white : Colors.black,
        fontFamily: 'SCDream',
        fontWeight: FontWeight.w400,
      ),
      checkmarkColor: isLight ? Colors.white : Colors.black,
      deleteIconColor: isLight ? Colors.black54 : Colors.white70,
      brightness: brightness,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isLight ? const Color(0xFFE0E0E0) : Colors.grey[800]!,
        ),
      ),
    );
  }

  static CardThemeData _buildCardTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return CardThemeData(
      color: isLight ? Colors.white : Colors.grey[900],
      shadowColor: isLight ? Colors.black12 : Colors.black38,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLight ? const Color(0xFFF0F0F0) : Colors.grey[800]!,
        ),
      ),
    );
  }

  static SnackBarThemeData _buildSnackBarTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return SnackBarThemeData(
      backgroundColor: isLight ? Colors.black87 : Colors.grey[850],
      contentTextStyle: TextStyle(
        color: isLight ? Colors.white : Colors.white,
        fontFamily: 'SCDream',
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: isLight ? Colors.blue.shade300 : Colors.blue.shade200,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  static DialogThemeData _buildDialogTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return DialogThemeData(
      backgroundColor: isLight ? Colors.white : Colors.grey[900],
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: TextStyle(
        color: isLight ? Colors.black : Colors.white,
        fontFamily: 'SCDream',
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      contentTextStyle: TextStyle(
        color: isLight ? Colors.black87 : Colors.white70,
        fontFamily: 'SCDream',
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

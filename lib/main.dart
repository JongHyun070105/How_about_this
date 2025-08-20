import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reviewai_flutter/screens/today_recommendation_screen.dart';
import 'package:reviewai_flutter/config/security_config.dart'; // 보안 설정 import
import 'package:reviewai_flutter/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SecurityInitializer.initialize();
    await MobileAds.instance.initialize();
    await NotificationService.initializeNotifications(); // Add this line
    await _configureSystemUI();
    runApp(const ProviderScope(child: ReviewAIApp()));
  } catch (e) {
    debugPrint('앱 초기화 실패: ${SecurityConfig.sanitizeErrorMessage(e.toString())}');
    runApp(const ProviderScope(child: ReviewAIApp()));
  }
}

Future<void> _configureSystemUI() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
}

class ReviewAIApp extends StatelessWidget {
  const ReviewAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Review AI',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      locale: const Locale('ko', 'KR'),
      home: const TodayRecommendationScreen(),
      navigatorKey: GlobalKey<NavigatorState>(),
      builder: (context, child) {
        ErrorWidget.builder = (errorDetails) {
          return _buildErrorWidget(context, errorDetails);
        };
        return child ?? const SizedBox.shrink();
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: Colors.black,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: Colors.blue,
        surface: Colors.white,
        background: Color(0xFFF5F5F5),
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
        onBackground: Colors.black,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      chipTheme: _buildChipTheme(),
      cardTheme: _buildCardTheme(),
      snackBarTheme: _buildSnackBarTheme(),
      dialogTheme: _buildDialogTheme(),
    );
  }

  TextTheme _buildTextTheme() {
    const fontFamily = 'Do Hyeon';
    const textColor = Colors.black;
    return const TextTheme(
      displayLarge: TextStyle(fontFamily: fontFamily, color: textColor),
      displayMedium: TextStyle(fontFamily: fontFamily, color: textColor),
      displaySmall: TextStyle(fontFamily: fontFamily, color: textColor),
      headlineLarge: TextStyle(fontFamily: fontFamily, color: textColor),
      headlineMedium: TextStyle(fontFamily: fontFamily, color: textColor),
      headlineSmall: TextStyle(fontFamily: fontFamily, color: textColor),
      titleLarge: TextStyle(fontFamily: fontFamily, color: textColor),
      titleMedium: TextStyle(fontFamily: fontFamily, color: textColor),
      titleSmall: TextStyle(fontFamily: fontFamily, color: textColor),
      bodyLarge: TextStyle(fontFamily: fontFamily, color: textColor),
      bodyMedium: TextStyle(fontFamily: fontFamily, color: textColor),
      bodySmall: TextStyle(fontFamily: fontFamily, color: textColor),
      labelLarge: TextStyle(fontFamily: fontFamily, color: textColor),
      labelMedium: TextStyle(fontFamily: fontFamily, color: textColor),
      labelSmall: TextStyle(fontFamily: fontFamily, color: textColor),
    );
  }

  AppBarTheme _buildAppBarTheme() {
    return const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Do Hyeon',
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey,
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Do Hyeon',
        ),
        elevation: 2,
        shadowColor: Colors.black26,
      ),
    );
  }

  InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      labelStyle: const TextStyle(
        color: Colors.black54,
        fontFamily: 'Do Hyeon',
      ),
      hintStyle: const TextStyle(color: Colors.black38, fontFamily: 'Do Hyeon'),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black, width: 2),
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

  ChipThemeData _buildChipTheme() {
    return ChipThemeData(
      backgroundColor: const Color(0xFFF5F5F5),
      selectedColor: Colors.black,
      disabledColor: Colors.grey.shade300,
      labelStyle: const TextStyle(color: Colors.black, fontFamily: 'Do Hyeon'),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Do Hyeon',
      ),
      checkmarkColor: Colors.white,
      deleteIconColor: Colors.black54,
      brightness: Brightness.light,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
    );
  }

  CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: Colors.white,
      shadowColor: Colors.black12,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFF0F0F0)),
      ),
    );
  }

  SnackBarThemeData _buildSnackBarTheme() {
    return SnackBarThemeData(
      backgroundColor: Colors.black87,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Do Hyeon',
        fontSize: 14,
      ),
      actionTextColor: Colors.blue.shade300,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  DialogThemeData _buildDialogTheme() {
    return DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        color: Colors.black,
        fontFamily: 'Do Hyeon',
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: Colors.black87,
        fontFamily: 'Do Hyeon',
        fontSize: 14,
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, FlutterErrorDetails errorDetails) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!SecurityConfig.shouldLogDetailed) {
      return Material(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                '일시적인 오류가 발생했습니다.\n앱을 다시 시작해주세요.',
                style: TextStyle(
                  fontFamily: 'Do Hyeon',
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bug_report, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Development Error',
                style: TextStyle(
                  fontFamily: 'Do Hyeon',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                SecurityConfig.sanitizeErrorMessage(
                  errorDetails.exception.toString(),
                ),
                style: TextStyle(
                  fontFamily: 'Do Hyeon',
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
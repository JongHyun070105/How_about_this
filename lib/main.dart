import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reviewai_flutter/screens/today_recommendation_screen.dart';

Future<void> main() async {
  // .env 파일 로드
  await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  runApp(
    // Riverpod 사용을 위한 ProviderScope 추가
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Review AI',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Do Hyeon', color: Colors.black),
          displayMedium: TextStyle(fontFamily: 'Do Hyeon', color: Colors.black),
          displaySmall: TextStyle(fontFamily: 'Do Hyeon', color: Colors.black),
          headlineLarge: TextStyle(fontFamily: 'Do Hyeon', color: Colors.black),
          headlineMedium: TextStyle(
            fontFamily: 'Do Hyeon',
            color: Colors.black,
          ),
          headlineSmall: TextStyle(fontFamily: 'Do Hyeon', color: Colors.black),
          titleLarge: TextStyle(fontFamily: 'Do Hyeon', color: Colors.black),
          titleMedium: TextStyle(fontFamily: 'Do Hyeon', color: Colors.black),
          titleSmall: TextStyle(fontFamily: 'Do Hyeon', color: Colors.black),
          bodyLarge: TextStyle(fontFamily: 'Do Hyeon', color: Colors.black),
          bodyMedium: TextStyle(fontFamily: 'Do Hyeon', color: Colors.black),
          bodySmall: TextStyle(fontFamily: 'Do Hyeon', color: Colors.black),
          labelLarge: TextStyle(fontFamily: 'Do Hyeon', color: Colors.black),
          labelMedium: TextStyle(fontFamily: 'Do Hyeon', color: Colors.black),
          labelSmall: TextStyle(fontFamily: 'Do Hyeon', color: Colors.black),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Do Hyeon',
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(
            color: Colors.black54,
            fontFamily: 'Do Hyeon',
          ),
          filled: true,
          fillColor: const Color(0xFFF1F1F1),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF1F1F1),
          selectedColor: Colors.black,
          labelStyle: const TextStyle(
            color: Colors.black,
            fontFamily: 'Do Hyeon',
          ),
          secondaryLabelStyle: const TextStyle(
            color: Colors.white,
            fontFamily: 'Do Hyeon',
          ),
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFBDBDBD)),
          ),
        ),
      ),
      home: const TodayRecommendationScreen(),
    );
  }
}

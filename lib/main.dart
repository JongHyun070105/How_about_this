import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reviewai_flutter/config/theme.dart';
import 'package:reviewai_flutter/screens/today_recommendation_screen.dart';
import 'package:reviewai_flutter/config/security_config.dart';
import 'package:clarity_flutter/clarity_flutter.dart';
import 'dart:async'; // unawaited를 위해 추가
import 'package:reviewai_flutter/widgets/common/error_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add dotenv import
import 'package:http/http.dart' as http; // Add http import
import 'package:reviewai_flutter/services/gemini_api_client.dart'; // Add gemini_api_client import
import 'package:reviewai_flutter/services/gemini_service.dart'; // Add gemini_service import

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final geminiServiceProvider = Provider<GeminiService>((ref) {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey == null) {
    throw Exception('GEMINI_API_KEY not found in .env file');
  }
  final httpClient = http.Client();
  final apiClient = GeminiApiClient(httpClient, apiKey);
  return GeminiService(apiClient);
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load .env file

  final config = ClarityConfig(
    projectId: "sy9cat27ff",
    logLevel: LogLevel.None, // Or LogLevel.Verbose for debugging
  );

  try {
    await SecurityInitializer.initialize();
    await MobileAds.instance.initialize();
    await _configureSystemUI();
    runApp(
      ClarityWidget( // Wrapped with ClarityWidget
        app: const ProviderScope(child: ReviewAIApp()),
        clarityConfig: config,
      ),
    );
  } catch (e) {
    debugPrint(
      '앱 초기화 실패: ${SecurityConfig.sanitizeErrorMessage(e.toString())}',
    );
    runApp(const ProviderScope(child: ReviewAIApp())); // Fallback if Clarity fails
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
      theme: AppTheme.light(),
      locale: const Locale('ko', 'KR'),
      home: const TodayRecommendationScreen(),
      navigatorKey: navigatorKey,
      builder: (context, child) {
        ErrorWidget.builder = (errorDetails) {
          return buildErrorWidget(context, errorDetails);
        };
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
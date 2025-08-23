import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/config/theme.dart';
import 'package:review_ai/config/security_config.dart';
import 'package:clarity_flutter/clarity_flutter.dart';
import 'dart:async';
import 'package:review_ai/widgets/common/error_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:review_ai/services/gemini_service.dart';
import 'package:review_ai/screens/loading_screen.dart';
import 'package:review_ai/services/usage_tracking_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final geminiServiceProvider = Provider<GeminiService>((ref) {
  final apiKey = dotenv.env['GEMINI_API_KEY'];
  if (apiKey == null) {
    throw Exception('GEMINI_API_KEY not found in .env file');
  }
  final httpClient = http.Client();
  return GeminiService(httpClient, apiKey);
});

final usageTrackingServiceProvider = Provider((ref) => UsageTrackingService());

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
      ClarityWidget(
        // Wrapped with ClarityWidget
        app: const ProviderScope(child: ReviewAIApp()),
        clarityConfig: config,
      ),
    );
  } catch (e) {
    debugPrint(
      '앱 초기화 실패: ${SecurityConfig.sanitizeErrorMessage(e.toString())}',
    );
    runApp(
      const ProviderScope(child: ReviewAIApp()),
    ); // Fallback if Clarity fails
  }
}

Future<void> _configureSystemUI() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
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
      title: '이거 어때',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('ko', 'KR'),
      home: const LoadingScreen(),
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
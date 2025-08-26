import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/config/theme.dart';
import 'package:review_ai/config/security_config.dart';
import 'package:clarity_flutter/clarity_flutter.dart';
import 'dart:async';
import 'package:review_ai/providers/food_providers.dart';
import 'package:review_ai/screens/today_recommendation_screen.dart';
import 'package:review_ai/widgets/common/error_widget.dart';
import 'package:review_ai/widgets/common/app_dialogs.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:review_ai/services/gemini_service.dart';
import 'package:review_ai/services/usage_tracking_service.dart';
// import 'package:review_ai/widgets/dialogs/review_dialogs.dart'; // Removed as it's no longer needed

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

  // 환경 변수 로드
  await dotenv.load(fileName: ".env");

  final config = ClarityConfig(
    projectId: "sy9cat27ff",
    logLevel: LogLevel.None, // Or LogLevel.Verbose for debugging
  );

  try {
    // 1. 보안 설정 초기화
    debugPrint('앱 초기화 시작...');
    await SecurityInitializer.initialize();
    debugPrint('보안 초기화 완료');

    // 2. 광고 설정 상태 확인 및 로그 출력
    SecurityConfig.logAdConfiguration();

    // 3. 광고 SDK 초기화
    debugPrint('광고 SDK 초기화 중...');
    await MobileAds.instance.initialize();
    debugPrint('광고 SDK 초기화 완료');

    // 4. 시스템 UI 설정
    await _configureSystemUI();
    debugPrint('시스템 UI 설정 완료');

    // 5. 앱 실행
    runApp(
      ClarityWidget(
        app: const ProviderScope(child: ReviewAIApp()),
        clarityConfig: config,
      ),
    );

    debugPrint('앱 시작 완료');
  } catch (e, stackTrace) {
    final sanitizedError = SecurityConfig.sanitizeErrorMessage(e.toString());
    debugPrint('앱 초기화 실패: $sanitizedError');
    debugPrint('스택 트레이스: $stackTrace');

    // Clarity 초기화 실패 시 기본 앱으로 fallback
    runApp(const ProviderScope(child: ReviewAIApp()));
  }
}

Future<void> _configureSystemUI() async {
  try {
    // 상태바 및 네비게이션 바 스타일 설정
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // 세로 방향으로 고정
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    debugPrint('시스템 UI 설정: 상태바 투명, 세로 모드 고정');
  } catch (e) {
    debugPrint('시스템 UI 설정 실패: ${e.toString()}');
    // UI 설정 실패해도 앱은 계속 진행
  }
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
      home: const AppInitializer(), // AppInitializer가 모든 로딩을 처리
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

/// 앱 초기화, 보안 검증, 데이터 로딩을 모두 담당하는 통합 스플래시 위젯
class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 최소 로딩 시간 보장 (사용자 경험 향상)
    const minLoadingTime = Duration(milliseconds: 2000);
    final stopwatch = Stopwatch()..start();

    try {
      // 1. 런타임 보안 검증
      final securityResult =
          await SecurityInitializer.performRuntimeSecurityCheck();
      debugPrint('보안 검증 결과: ${securityResult.isSecure ? "안전" : "위험"}');

      if (!securityResult.isSecure) {
        await SecurityInitializer.handleSecurityThreat(securityResult);
      }

      // 2. 네트워크 연결 확인
      await _checkConnectivityWithTimeout();

      // 3. SVG 프리캐싱
      _startBackgroundCaching();

      // 4. 최소 로딩 시간 보장
      final elapsed = stopwatch.elapsed;
      if (elapsed < minLoadingTime) {
        await Future.delayed(minLoadingTime - elapsed);
      }

      // 5. 메인 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TodayRecommendationScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        '앱 초기화 중 오류: ${SecurityConfig.sanitizeErrorMessage(e.toString())}',
      );
      if (mounted) {
        _handleInitializationError();
      }
    }
  }

  Future<void> _checkConnectivityWithTimeout() async {
    try {
      final connectivityResult = await Future.any([
        Connectivity().checkConnectivity(),
        Future.delayed(
          const Duration(seconds: 3),
          () => throw TimeoutException(
            'Network check timeout',
            const Duration(seconds: 3),
          ),
        ),
      ]);

      if (connectivityResult.contains(ConnectivityResult.none)) {
        throw Exception('No internet connection');
      }
    } catch (e) {
      if (e.toString().contains('timeout') ||
          e.toString().contains('No internet')) {
        if (!mounted) return;
        showAppDialog(
          context,
          title: '네트워크 연결 오류',
          message: '인터넷 연결을 확인해주세요.',
          isError: true,
        );
        rethrow;
      }
      // 다른 에러는 무시하고 계속 진행
      debugPrint('Network check warning: $e');
    }
  }

  void _startBackgroundCaching() {
    // 백그라운드에서 SVG 캐싱 (UI 블로킹 없음)
    Future.microtask(() async {
      try {
        final foodCategories = ref.read(foodCategoriesProvider);

        // 배치 단위로 캐싱하여 메모리 사용량 제어
        const batchSize = 3;
        for (int i = 0; i < foodCategories.length; i += batchSize) {
          final batch = foodCategories.skip(i).take(batchSize).toList();

          await _cacheSVGBatch(batch);

          // 다음 배치 전에 잠깐 대기 (CPU 부하 분산)
          if (i + batchSize < foodCategories.length) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }

        debugPrint('SVG background caching completed');
      } catch (e) {
        debugPrint('Background caching error (non-critical): $e');
      }
    });
  }

  Future<void> _cacheSVGBatch(List<dynamic> categories) async {
    await Future.wait(
      categories.map((category) async {
        try {
          // 간단한 방식: SVG 문자열만 미리 로드
          // 실제 렌더링은 사용할 때 수행
          final assetBundle = DefaultAssetBundle.of(context);
          await assetBundle.loadString(category.imageUrl);
        } catch (e) {
          // 개별 SVG 로딩 실패는 무시
          debugPrint('SVG cache warning for ${category.imageUrl}: $e');
        }
      }),
      eagerError: false, // 하나 실패해도 계속 진행
    );
  }

  void _handleInitializationError() {
    showAppDialog(
      context,
      title: '초기화 오류',
      message: '앱을 시작하는 중 문제가 발생했습니다.',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final imageSize = screenSize.width * 0.6;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'icon/app_logo.png',
          width: imageSize,
          height: imageSize,
          filterQuality: FilterQuality.high,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  final Duration timeout;

  const TimeoutException(this.message, this.timeout);

  @override
  String toString() => 'TimeoutException: $message';
}

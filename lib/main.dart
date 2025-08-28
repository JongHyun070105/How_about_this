import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/config/theme.dart';
import 'package:review_ai/config/security_config.dart';
import 'package:review_ai/services/app_update_service.dart';
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
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:review_ai/utils/network_utils.dart';

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

  await dotenv.load(fileName: ".env");

  final config = ClarityConfig(
    projectId: "sy9cat27ff",
    logLevel: LogLevel.None,
  );

  try {
    await SecurityInitializer.initialize();
    SecurityConfig.logAdConfiguration();
    await MobileAds.instance.initialize();
    await _configureSystemUI();

    runApp(
      ClarityWidget(
        app: const ProviderScope(child: ReviewAIApp()),
        clarityConfig: config,
      ),
    );
  } catch (e, stackTrace) {
    final sanitizedError = SecurityConfig.sanitizeErrorMessage(e.toString());
    debugPrint('앱 초기화 실패: $sanitizedError');
    debugPrint('스택 트레이스: $stackTrace');
    runApp(const ProviderScope(child: ReviewAIApp()));
  }
}

Future<void> _configureSystemUI() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
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
      home: const AppInitializer(),
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
    const minLoadingTime = Duration(milliseconds: 2000);
    final stopwatch = Stopwatch()..start();

    try {
      final securityResult =
          await SecurityInitializer.performRuntimeSecurityCheck();
      if (!context.mounted) return;
      if (!securityResult.isSecure) {
        await SecurityInitializer.handleSecurityThreat(context, securityResult);
        return; // Stop initialization if threat detected
      }

      bool isConnected = await _checkInternetConnectivity();
      while (!isConnected) {
        if (!mounted) return;
        final shouldRetry = await _showConnectionErrorDialog();
        if (shouldRetry) {
          isConnected = await _checkInternetConnectivity();
        } else {
          // User chose to exit
          exit(0);
        }
      }

      _startBackgroundCaching();

      // Check for updates after main initialization but before navigating away
      await _checkForUpdate();

      final elapsed = stopwatch.elapsed;
      if (elapsed < minLoadingTime) {
        await Future.delayed(minLoadingTime - elapsed);
      }

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

  Future<bool> _showConnectionErrorDialog() async {
    if (!mounted) return false;
    return await showCupertinoDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: const Text(
                '네트워크 연결 오류',
                style: TextStyle(
                  fontFamily: 'SCDream',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  '인터넷 연결을 확인해주세요.',
                  style: TextStyle(fontFamily: 'SCDream', fontSize: 16),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('앱 종료'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // Don't retry
                  },
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('재시도'),
                  onPressed: () {
                    Navigator.of(context).pop(true); // Retry
                  },
                ),
              ],
            );
          },
        ) ??
        false; // Return false if dialog is dismissed
  }

  Future<bool> _checkInternetConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false; // No network interface
      }

      // Check for actual internet access by trying to connect to a reliable host
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true; // Internet is accessible
      }
      return false;
    } on TimeoutException catch (_) { // Catch TimeoutException first
      return false; // Lookup timed out
    } on SocketException catch (_) { // Then SocketException
      return false; // No internet access
    } catch (e) { // Then all other exceptions
      debugPrint('Error checking internet connectivity: $e');
      return false;
    }
  }

  Future<void> _checkForUpdate() async {
    final appUpdateService = AppUpdateService();
    final latestVersion = await appUpdateService.isUpdateAvailable();

    if (latestVersion != null && mounted) {
      showAppDialog(
        context,
        title: '업데이트 알림',
        message: '새로운 버전(v$latestVersion)이 출시되었습니다. 더 나은 경험을 위해 업데이트를 진행해주세요.',
        confirmButtonText: '업데이트',
        onConfirm: () {
          _launchStoreUrl();
        },
      );
    }
  }

  void _launchStoreUrl() async {
    // TODO: Replace with actual store URLs
    final url = Platform.isIOS
        ? 'https://apps.apple.com/app/your-app-id'
        : 'https://play.google.com/store/apps/details?id=com.jonghyun.reviewai_flutter';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch store URL');
    }
  }

  void _startBackgroundCaching() {
    Future.microtask(() async {
      try {
        final foodCategories = ref.read(foodCategoriesProvider);
        const batchSize = 3;
        for (int i = 0; i < foodCategories.length; i += batchSize) {
          final batch = foodCategories.skip(i).take(batchSize).toList();
          await _cacheSVGBatch(batch);
          if (i + batchSize < foodCategories.length) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
      } catch (e) {
        // Non-critical error
      }
    });
  }

  Future<void> _cacheSVGBatch(List<dynamic> categories) async {
    await Future.wait(
      categories.map((category) async {
        try {
          final assetBundle = DefaultAssetBundle.of(context);
          await assetBundle.loadString(category.imageUrl);
        } catch (e) {
          // Ignore individual SVG loading failure
        }
      }),
      eagerError: false,
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

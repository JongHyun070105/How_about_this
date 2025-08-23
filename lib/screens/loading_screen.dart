import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:review_ai/providers/food_providers.dart';
import 'package:review_ai/screens/today_recommendation_screen.dart';
import 'package:review_ai/widgets/dialogs/review_dialogs.dart';

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitialized = false; // 플래그 추가

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    if (_isInitialized) return; // 이미 초기화되었으면 중복 실행 방지
    _isInitialized = true; // 초기화 플래그 설정

    // 최소 로딩 시간 보장 (사용자 경험 향상)
    const minLoadingTime = Duration(milliseconds: 1200);
    final stopwatch = Stopwatch()..start();

    try {
      // 1. 빠른 네트워크 연결 확인 (타임아웃 설정)
      await _checkConnectivityWithTimeout();

      // 2. SVG 프리캐싱 없이 바로 진행
      // (필요시 백그라운드에서 캐싱하도록 변경)
      _startBackgroundCaching();

      // 3. 최소 로딩 시간 보장
      final elapsed = stopwatch.elapsed;
      if (elapsed < minLoadingTime) {
        await Future.delayed(minLoadingTime - elapsed);
      }

      // 4. 메인 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TodayRecommendationScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } catch (e) {
      debugPrint('App initialization error: $e');
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
        showAlertDialog(
          context,
          '네트워크 연결 오류',
          '인터넷 연결을 확인해주세요.',
          onConfirm: () => Navigator.of(context).pop(),
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
    showAlertDialog(
      context,
      '초기화 오류',
      '앱을 시작하는 중 문제가 발생했습니다.',
      onConfirm: () => Navigator.of(context).pop(),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 정보 가져오기
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 768;
    final isSmallScreen = screenSize.height < 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.08,
                  vertical: isSmallScreen ? 20 : 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'icon/app_logo.png',
                      width: isTablet ? 300 : 200,
                      height: isTablet ? 300 : 200,
                      filterQuality: FilterQuality.high,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
          ),
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
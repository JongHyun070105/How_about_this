import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/core/utils/logger_service.dart';

import '../../core/app_initializer.dart';
import '../../core/splash_helper.dart';
import '../../config/security_config.dart';
import '../../services/app_update_service.dart';
import '../../services/notification_service.dart';
import '../providers/food_providers.dart';
import '../providers/review_provider.dart';
import 'today_recommendation_screen.dart';
import 'onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/widgets/common/app_dialogs.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    const minLoadingTime = Duration(milliseconds: 2000);
    final stopwatch = Stopwatch()..start();

    try {
      // 인터넷 연결 시도 (최대 2회)
      int retryCount = 0;
      bool isConnected = await SplashHelper.checkInternetConnectivity();
      while (!isConnected && retryCount < 2) {
        if (!mounted) return;
        final shouldRetry = await _showConnectionErrorDialog();
        if (shouldRetry) {
          isConnected = await SplashHelper.checkInternetConnectivity();
          retryCount++;
        } else {
          unawaited(SystemNavigator.pop());
        }
      }

      // 무거운 비동기 초기화 작업 (Firebase, AdMob 등)
      await AppInitializer.initializePostRun();

      _startBackgroundCaching();

      final securityResult =
          await SecurityInitializer.performRuntimeSecurityCheck();
      if (!mounted) return;
      if (!securityResult.isSecure) {
        await SecurityInitializer.handleSecurityThreat(context, securityResult);
        return; // Halt initialization and stay on SecurityBlockScreen
      }

      _checkForUpdateInBackground();
      _updateNotificationMessages();

      final elapsed = stopwatch.elapsed;
      if (elapsed < minLoadingTime) {
        await Future.delayed(minLoadingTime - elapsed);
      }

      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      if (mounted) {
        unawaited(
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  hasSeenOnboarding
                  ? const TodayRecommendationScreen()
                  : const OnboardingScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          ),
        );
      }
    } catch (e) {
      LoggerService.e(
        '초기화 중 오류: ${SecurityConfig.sanitizeErrorMessage(e.toString())}',
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
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('재시도'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _updateNotificationMessages() {
    Future.microtask(() async {
      try {
        final history = ref.read(reviewHistoryProvider);
        if (history.isNotEmpty) {
          await NotificationService().updatePersonalizedMessages(history);
        }
      } catch (e) {
        LoggerService.e('Notification update failed: $e');
      }
    });
  }

  void _checkForUpdateInBackground() {
    Future.microtask(() async {
      try {
        final appUpdateService = AppUpdateService();

        if (Platform.isAndroid) {
          // Android: Play Store 공식 인앱 업데이트 수행 (Flexible)
          await appUpdateService.checkForInAppUpdate();
        } else {
          // iOS: Gist 기반 커스텀 버전 체크 후 다이얼로그
          final latestVersion = await appUpdateService.isUpdateAvailable();
          if (latestVersion != null && mounted) {
            showAppDialog(
              context,
              title: '업데이트 알림',
              message: '새로운 버전(v$latestVersion)이 출시되었습니다.',
              confirmButtonText: '업데이트',
              onConfirm: () => SplashHelper.launchStoreUrl(),
            );
          }
        }
      } catch (e) {
        LoggerService.e('Update check error: $e');
      }
    });
  }

  void _startBackgroundCaching() {
    Future.microtask(() async {
      try {
        final foodCategories = ref.read(foodCategoriesProvider);
        for (int i = 0; i < foodCategories.length; i += 3) {
          final batch = foodCategories.skip(i).take(3).toList();
          await Future.wait(
            batch.map(
              (c) => DefaultAssetBundle.of(context).loadString(c.imageUrl),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } catch (e) {
        // 캐싱 실패 시 무시
      }
    });
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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Image.asset(
            'icon/app_logo.png',
            width: imageSize,
            height: imageSize,
            filterQuality: FilterQuality.high,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

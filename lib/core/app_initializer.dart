import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:review_ai/services/crash_reporting_service.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'package:review_ai/config/security_config.dart';
import 'package:review_ai/services/auth_service.dart';
import 'package:review_ai/services/config_service.dart';
import 'package:review_ai/services/server_time_service.dart';
import 'package:review_ai/services/notification_service.dart';
import 'package:review_ai/core/utils/logger_service.dart';

class AppInitializer {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Crash Reporting 시스템 초기화 (내부적으로 Crashlytics 설정)
    await CrashReportingService().initialize();

    // Flutter 프레임워크 에러
    FlutterError.onError = (errorDetails) {
      CrashReportingService().recordError(
        errorDetails.exception,
        errorDetails.stack,
        fatal: true,
      );
    };

    // 잡히지 않은 비동기 에러
    PlatformDispatcher.instance.onError = (error, stack) {
      CrashReportingService().recordError(error, stack, fatal: true);
      return true;
    };

    // Firebase Performance & Analytics
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

    // 기타 서비스 동시 초기화
    await Future.wait([
      SecurityInitializer.initialize(),
      MobileAds.instance.initialize(),
      AuthService.initialize(),
      ConfigService.initialize(),
      ServerTimeService.initialize(),
      NotificationService().initialize(),
      DefaultFirebaseOptions.loadServerKeys(),
      _configureSystemUI(),
      _requestLocationPermission(),
      _requestAccessibilityPermission(),
      _requestNotificationPermission(),
    ]);

    SecurityConfig.logAdConfiguration();
  }

  static Future<void> _requestNotificationPermission() async {
    try {
      final service = NotificationService();
      // 앱 시작 시 권한이 없으면 요청하도록 함
      if (!await service.hasPermission()) {
        await service.requestPermissions();
      }
    } catch (e) {
      LoggerService.e('알림 권한 요청 실패', e);
    }
  }

  static Future<void> _configureSystemUI() async {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  static Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (e) {
      LoggerService.e('위치 권한 요청 실패', e);
    }
  }

  static Future<void> _requestAccessibilityPermission() async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('com.reviewai.keyevents');
        final isEnabled = await platform.invokeMethod(
          'isAccessibilityServiceEnabled',
        );
        if (!isEnabled) {
          await platform.invokeMethod('openAccessibilitySettings');
        }
      }
    } catch (e) {
      debugPrint('접근성 서비스 권한 확인 실패: $e');
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// 앱 전역 로깅 시스템
///
/// - 개발 모드: 콘솔에 시각적으로 구조화된 로그 출력
/// - 프로덕트 모드: 에러 로그를 Firebase Crashlytics로 전송
class LoggerService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

  /// 디버그 로그 - 개발 중에만 필요한 정보
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 정보성 로그 - 주요 이벤트 (API 호출 완료 등)
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// 경고 로그 - 예외 상황이지만 앱 실행에는 문제 없는 경우
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// 에러 로그 - 심각한 문제
  /// 프로덕션 환경에서는 Crashlytics에 자동으로 기록됩니다.
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);

    // 프로덕션 모드에서는 Crashlytics로 에러 전송
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error ?? message,
        stackTrace,
        reason: message,
        fatal: false,
      );
    }
  }

  /// 치명적 에러 로그
  static void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);

    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        error ?? message,
        stackTrace,
        reason: message,
        fatal: true,
      );
    }
  }
}

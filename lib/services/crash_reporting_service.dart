import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:review_ai/core/utils/logger_service.dart';

/// 앱 크래시 및 비정상 로그를 수집하고 관리하는 서비스
class CrashReportingService {
  static final CrashReportingService _instance =
      CrashReportingService._internal();

  factory CrashReportingService() => _instance;

  CrashReportingService._internal();

  bool _isInitialized = false;
  static bool _isTesting = false;

  @visibleForTesting
  static void setTesting(bool testing) {
    _isTesting = testing;
  }

  /// Crashlytics 초기화 및 설정
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (_isTesting) {
      _isInitialized = true;
      return;
    }

    // Crashlytics 데이터 수집 활성화 (디버그 모드에서는 수집 안 함, 하지만 자체적으로 끄고 켤 수 있음)
    // 원한다면 테스트 목적으로 디버그에서도 킬 수 있지만 기본은 릴리즈에서만 활성화하는 것이 좋습니다.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );

    // 로그인 관련 명확한 uid가 없다면 내부 기기 ID라도 식별자로 사용
    // AuthService에서 _getOrCreateDeviceId()를 외부에 노출하지 않았다면 초기화 시점에서는 생략하고 나중에 설정하도록 둘 수 있습니다.
    // 여기서는 일단 주석 처리 혹은 생략합니다.

    // 기본 커스텀 키 설정
    await FirebaseCrashlytics.instance.setCustomKey(
      'platform',
      defaultTargetPlatform.name,
    );
    await FirebaseCrashlytics.instance.setCustomKey('is_debug', kDebugMode);

    _isInitialized = true;
  }

  /// 강제 크래시 유발 (테스트 용도)
  void throwFatalCrash() {
    if (_isTesting) return;
    FirebaseCrashlytics.instance.crash();
  }

  /// 커스텀 로그 기록 (크래시가 발생할 때 함께 수집됨)
  Future<void> log(String message) async {
    if (_isTesting) return;
    await FirebaseCrashlytics.instance.log(message);
  }

  /// 잡힌 에러(Caught Error)를 Crashlytics로 전송
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool printDetails = true,
    bool fatal = false,
  }) async {
    if (_isTesting) {
      LoggerService.d('Mock recordError: $exception');
      return;
    }
    await FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason,
      information: information,
      printDetails: printDetails,
      fatal: fatal,
    );
  }

  /// 사용자 식별자 설정
  Future<void> setUserIdentifier(String identifier) async {
    if (_isTesting) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
  }

  /// 커스텀 키 설정
  Future<void> setCustomKey(String key, Object value) async {
    if (_isTesting) return;
    await FirebaseCrashlytics.instance.setCustomKey(key, value);
  }
}

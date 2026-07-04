import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// 앱 크래시 및 비정상 로그를 수집하고 관리하는 서비스
class CrashReportingService {
  static final CrashReportingService _instance =
      CrashReportingService._internal();

  factory CrashReportingService() => _instance;

  CrashReportingService._internal();

  bool _isInitialized = false;

  FirebaseCrashlytics? _customCrashlytics;
  FirebaseCrashlytics get _crashlytics =>
      _customCrashlytics ?? FirebaseCrashlytics.instance;

  @visibleForTesting
  set mockCrashlytics(FirebaseCrashlytics mock) => _customCrashlytics = mock;

  /// Crashlytics 초기화 및 설정
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Crashlytics 데이터 수집 활성화 (디버그 모드에서는 수집 안 함, 하지만 자체적으로 끄고 켤 수 있음)
    // 원한다면 테스트 목적으로 디버그에서도 킬 수 있지만 기본은 릴리즈에서만 활성화하는 것이 좋습니다.
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // 기본 커스텀 키 설정
    await _crashlytics.setCustomKey('platform', defaultTargetPlatform.name);
    await _crashlytics.setCustomKey('is_debug', kDebugMode);

    _isInitialized = true;
  }

  /// 강제 크래시 유발 (테스트 용도)
  void throwFatalCrash() {
    _crashlytics.crash();
  }

  /// 커스텀 로그 기록 (크래시가 발생할 때 함께 수집됨)
  Future<void> log(String message) async {
    await _crashlytics.log(message);
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
    await _crashlytics.recordError(
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
    await _crashlytics.setUserIdentifier(identifier);
  }

  /// 커스텀 키 설정
  Future<void> setCustomKey(String key, Object value) async {
    await _crashlytics.setCustomKey(key, value);
  }
}

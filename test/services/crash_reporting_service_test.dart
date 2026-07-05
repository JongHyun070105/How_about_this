import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/services/crash_reporting_service.dart';

// FirebaseCrashlytics를 모킹하기 위한 가짜 수집 델리게이트
class FakeFirebaseCrashlytics implements FirebaseCrashlytics {
  bool? isCollectionEnabled;
  final Map<String, Object> customKeys = {};
  bool isCrashCalled = false;
  final List<String> logs = [];

  dynamic recordedException;
  StackTrace? recordedStackTrace;
  dynamic recordedReason;
  bool? recordedFatal;

  String? userIdentifier;

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    isCollectionEnabled = enabled;
  }

  @override
  Future<void> setCustomKey(String key, Object value) async {
    customKeys[key] = value;
  }

  @override
  void crash() {
    isCrashCalled = true;
  }

  @override
  Future<void> log(String message) async {
    logs.add(message);
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool? printDetails = true,
    bool fatal = false,
  }) async {
    recordedException = exception;
    recordedStackTrace = stack;
    recordedReason = reason;
    recordedFatal = fatal;
  }

  @override
  Future<void> setUserIdentifier(String identifier) async {
    userIdentifier = identifier;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeFirebaseCrashlytics fakeCrashlytics;
  late CrashReportingService crashReportingService;

  setUp(() {
    fakeCrashlytics = FakeFirebaseCrashlytics();
    crashReportingService = CrashReportingService();
    crashReportingService.mockCrashlytics = fakeCrashlytics;
  });

  group('CrashReportingService - 크래시 리포팅 라이프사이클 및 전송 검증', () {
    test('initialize() 호출 시 수집기 활성화 및 기본 메타데이터 키들이 적재되어야 함', () async {
      await crashReportingService.initialize();

      // 1. 수집기 활성화 여부 검증 (kDebugMode 부정값 적용)
      expect(fakeCrashlytics.isCollectionEnabled, equals(!kDebugMode));

      // 2. 기본 세팅 커스텀 키 검증
      expect(
        fakeCrashlytics.customKeys['platform'],
        equals(defaultTargetPlatform.name),
      );
      expect(fakeCrashlytics.customKeys['is_debug'], equals(kDebugMode));
    });

    test('log(message) 호출 시 커스텀 로그가 누적되어 전송되어야 함', () async {
      await crashReportingService.log('test log trace 1');
      await crashReportingService.log('test log trace 2');

      expect(fakeCrashlytics.logs.length, equals(2));
      expect(fakeCrashlytics.logs[0], equals('test log trace 1'));
      expect(fakeCrashlytics.logs[1], equals('test log trace 2'));
    });

    test('recordError() 호출 시 에러 스택 정보 및 치명 여부가 델리게이트되어야 함', () async {
      final exception = Exception('Simulated fatal business error');
      final stackTrace = StackTrace.current;

      await crashReportingService.recordError(
        exception,
        stackTrace,
        reason: 'Order submission failed',
        fatal: true,
      );

      expect(fakeCrashlytics.recordedException, equals(exception));
      expect(fakeCrashlytics.recordedStackTrace, equals(stackTrace));
      expect(fakeCrashlytics.recordedReason, equals('Order submission failed'));
      expect(fakeCrashlytics.recordedFatal, isTrue);
    });

    test('setUserIdentifier() 호출 시 올바른 사용자 키 식별 정보가 설정되어야 함', () async {
      await crashReportingService.setUserIdentifier('user_id_100293');

      expect(fakeCrashlytics.userIdentifier, equals('user_id_100293'));
    });

    test('setCustomKey() 호출 시 디버깅용 임의의 메타 정보가 적재되어야 함', () async {
      await crashReportingService.setCustomKey('active_screen', 'HomeScreen');
      await crashReportingService.setCustomKey('network_status', 'cellular');

      expect(fakeCrashlytics.customKeys['active_screen'], equals('HomeScreen'));
      expect(fakeCrashlytics.customKeys['network_status'], equals('cellular'));
    });

    test('throwFatalCrash() 구동 시 즉각 크래시 메소드를 실행해야 함', () {
      crashReportingService.throwFatalCrash();

      expect(fakeCrashlytics.isCrashCalled, isTrue);
    });
  });
}

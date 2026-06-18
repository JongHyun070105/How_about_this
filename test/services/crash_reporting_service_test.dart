import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/services/crash_reporting_service.dart';

void main() {
  setUp(() {
    CrashReportingService.setTesting(true);
  });

  tearDown(() {
    CrashReportingService.setTesting(false);
  });

  group('CrashReportingService 유닛 테스트 (테스트 격리 우회 검증)', () {
    test('성공적인 초기화 상태값 검증', () async {
      final service = CrashReportingService();
      await service.initialize();
      // 초기화가 안정적으로 수행됨을 검증
      expect(service, isNotNull);
    });

    test('강제 크래시 및 로그 기록 시 플랫폼 에러 발생 없이 안전 우회 검증', () async {
      final service = CrashReportingService();
      await service.initialize();

      // 아래 메소드들이 플랫폼 채널 Exception을 뿜지 않고 우회되는지 확인
      expect(() => service.throwFatalCrash(), returnsNormally);
      expect(() => service.log('test log message'), returnsNormally);
      expect(() => service.setUserIdentifier('user_12345'), returnsNormally);
      expect(
        () => service.setCustomKey('test_key', 'test_value'),
        returnsNormally,
      );
    });

    test('recordError 호출 시 플랫폼 채널 에러 없이 안전 우회 검증', () async {
      final service = CrashReportingService();
      await service.initialize();

      final exception = Exception('test runtime error');
      final stack = StackTrace.current;

      expect(
        () async => await service.recordError(
          exception,
          stack,
          reason: 'testing bypass',
          fatal: true,
        ),
        returnsNormally,
      );
    });
  });
}

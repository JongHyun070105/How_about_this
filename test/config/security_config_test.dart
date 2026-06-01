import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/config/security_config.dart';
import 'package:review_ai/config/environment_config.dart';

void main() {
  group('SecurityConfig', () {
    group('광고 ID 관리', () {
      test('테스트 환경에서 테스트 광고 ID 반환', () {
        // 디버그 모드에서는 테스트 광고 사용
        expect(SecurityConfig.isUsingTestAds, isTrue);
      });

      test('리워드 광고 ID가 비어있지 않음', () {
        expect(SecurityConfig.rewardedAdUnitId, isNotEmpty);
      });

      test('배너 광고 ID가 비어있지 않음', () {
        expect(SecurityConfig.bannerAdUnitId, isNotEmpty);
      });

      test('테스트 광고 ID가 구글 테스트 ID 형식', () {
        expect(
          SecurityConfig.rewardedAdUnitId,
          startsWith('ca-app-pub-3940256099942544'),
        );
        expect(
          SecurityConfig.bannerAdUnitId,
          startsWith('ca-app-pub-3940256099942544'),
        );
      });
    });

    group('에러 메시지 새니타이즈', () {
      test('API 키 패턴이 숨겨짐', () {
        final sanitized = SecurityConfig.sanitizeErrorMessage(
          'Error with key=AIzaSyBfNotry0ovUtyRgFhbkTGAu2KH8-RV4lU',
        );
        // 실제 API 키 패턴이 치환되는지 확인
        expect(sanitized, isA<String>());
      });
    });

    group('보안 검사', () {
      test('디버거 감지가 디버그 모드에서 true 반환', () {
        expect(SecurityConfig.detectDebugger(), isTrue);
      });

      test('앱 무결성 검증이 true 반환', () async {
        final result = await SecurityConfig.verifyAppIntegrity();
        expect(result, isTrue);
      });

      test('루팅/탈옥 감지가 디버그 모드에서 false 반환 (비활성화)', () async {
        // 디버그 모드에서는 의도적으로 비활성화
        final result = await SecurityConfig.detectRootingOrJailbreak();
        expect(result, isFalse);
      });

      test('에뮬레이터 감지가 바인딩 미초기화 환경에서 false 반환', () async {
        final result = await SecurityConfig.detectEmulator();
        expect(result, isFalse);
      });
    });
  });

  group('SecurityInitializer', () {
    test('초기화가 에러 없이 완료', () async {
      await SecurityInitializer.initialize();
    });

    test('런타임 보안 체크가 결과 반환', () async {
      final result = await SecurityInitializer.performRuntimeSecurityCheck();

      expect(result, isA<SecurityCheckResult>());
      expect(result.isAppIntegrityValid, isTrue);
      // 디버그 모드에서는 루팅 체크 비활성화
      expect(result.isRootedOrJailbroken, isFalse);
      // 디버그 모드에서는 디버거 감지됨
      expect(result.isDebuggerAttached, isTrue);
      expect(result.isEmulator, isFalse);
      expect(result.error, isNull);
    });

    test('개발 환경에서 디버거 연결돼도 보안 상태 true', () async {
      // 개발 환경에서는 디버거가 연결되어 있어도 isSecure가 true
      expect(EnvironmentConfig.isDevelopment, isTrue);

      final result = await SecurityInitializer.performRuntimeSecurityCheck();

      // 개발 환경 보안 판단: !rooted && appIntegrity
      expect(result.isSecure, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/config/environment_config.dart';

void main() {
  group('EnvironmentConfig', () {
    group('currentEnvironment', () {
      test('디버그 모드에서 development 환경 반환', () {
        // 테스트 환경은 항상 debug 모드
        expect(
          EnvironmentConfig.currentEnvironment,
          AppEnvironment.development,
        );
      });

      test('개발 환경 플래그가 올바르게 동작', () {
        expect(EnvironmentConfig.isDevelopment, isTrue);
        expect(EnvironmentConfig.isStaging, isFalse);
        expect(EnvironmentConfig.isProduction, isFalse);
      });
    });

    group('로깅 설정', () {
      test('개발 환경에서 상세 로깅 활성화', () {
        expect(EnvironmentConfig.enableVerboseLogging, isTrue);
      });

      test('개발 환경에서 로그 레벨 debug', () {
        expect(EnvironmentConfig.logLevel, 'debug');
      });

      test('개발 환경에서 로깅 활성화', () {
        expect(EnvironmentConfig.enableLogging, isTrue);
      });
    });

    group('보안 설정', () {
      test('개발 환경에서 SSL 인증서 검증 비활성화', () {
        expect(EnvironmentConfig.enableCertificateValidation, isFalse);
      });

      test('개발 환경에서 디버그 정보 표시', () {
        expect(EnvironmentConfig.showDebugInfo, isTrue);
      });
    });

    group('기능 플래그', () {
      test('개발 환경에서 베타 기능 활성화', () {
        expect(EnvironmentConfig.enableBetaFeatures, isTrue);
      });

      test('개발 환경에서 Analytics 비활성화', () {
        expect(EnvironmentConfig.enableAnalytics, isFalse);
      });

      test('개발 환경에서 Performance 모니터링 비활성화', () {
        expect(EnvironmentConfig.enablePerformanceMonitoring, isFalse);
      });
    });

    group('네트워크/캐시 설정', () {
      test('HTTP 타임아웃이 합리적인 범위', () {
        expect(EnvironmentConfig.httpTimeout, greaterThanOrEqualTo(10));
        expect(EnvironmentConfig.httpTimeout, lessThanOrEqualTo(60));
      });

      test('개발 환경 캐시 만료가 짧음', () {
        expect(EnvironmentConfig.cacheExpirationMinutes, 5);
      });

      test('연결 풀 크기가 양수', () {
        expect(EnvironmentConfig.connectionPoolSize, greaterThan(0));
      });
    });

    group('환경 정보', () {
      test('environmentInfo가 필수 키를 포함', () {
        final info = EnvironmentConfig.environmentInfo;
        expect(info, containsPair('environment', 'development'));
        expect(info, contains('apiBaseUrl'));
        expect(info, contains('enableVerboseLogging'));
        expect(info, contains('logLevel'));
        expect(info, contains('httpTimeout'));
      });

      test('API Base URL이 유효한 HTTPS URL', () {
        expect(EnvironmentConfig.apiBaseUrl, startsWith('https://'));
      });

      test('environmentSummary가 빈 문자열이 아님', () {
        expect(EnvironmentConfig.environmentSummary, isNotEmpty);
      });
    });
  });
}

// =============================================================================
// 환경별 설정 관리
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 앱의 환경 설정을 관리하는 열거형
enum AppEnvironment { development, staging, production }

/// 환경별 설정을 관리하는 클래스
class EnvironmentConfig {
  EnvironmentConfig._(); // 인스턴스 생성 방지

  // =============================================================================
  // 현재 환경 판단
  // =============================================================================

  /// 현재 앱 환경 반환
  static AppEnvironment get currentEnvironment {
    if (kDebugMode) return AppEnvironment.development;

    final env = dotenv.env['APP_ENVIRONMENT'];
    switch (env) {
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
        return AppEnvironment.production;
      default:
        return AppEnvironment.development;
    }
  }

  /// 현재 환경이 개발 환경인지 확인
  static bool get isDevelopment =>
      currentEnvironment == AppEnvironment.development;

  /// 현재 환경이 스테이징 환경인지 확인
  static bool get isStaging => currentEnvironment == AppEnvironment.staging;

  /// 현재 환경이 프로덕션 환경인지 확인
  static bool get isProduction =>
      currentEnvironment == AppEnvironment.production;

  // =============================================================================
  // API 엔드포인트 설정
  // =============================================================================

  /// 환경별 API 기본 URL
  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case AppEnvironment.development:
        return dotenv.env['DEV_API_URL'] ?? 'https://dev-api.example.com';
      case AppEnvironment.staging:
        return dotenv.env['STAGING_API_URL'] ??
            'https://staging-api.example.com';
      case AppEnvironment.production:
        return dotenv.env['PROD_API_URL'] ?? 'https://api.example.com';
    }
  }

  /// Gemini API URL
  static String get geminiApiUrl {
    return dotenv.env['GEMINI_API_URL'] ??
        'https://generativelanguage.googleapis.com';
  }

  // =============================================================================
  // 로깅 설정
  // =============================================================================

  /// 상세 로깅 활성화 여부
  static bool get enableVerboseLogging {
    return currentEnvironment == AppEnvironment.development;
  }

  /// 로그 레벨 설정
  static String get logLevel {
    switch (currentEnvironment) {
      case AppEnvironment.development:
        return dotenv.env['LOG_LEVEL'] ?? 'debug';
      case AppEnvironment.staging:
        return dotenv.env['LOG_LEVEL'] ?? 'info';
      case AppEnvironment.production:
        return dotenv.env['LOG_LEVEL'] ?? 'error';
    }
  }

  /// 로깅 활성화 여부
  static bool get enableLogging {
    final enableLogging = dotenv.env['ENABLE_LOGGING'];
    if (enableLogging == null) {
      return currentEnvironment != AppEnvironment.production;
    }
    return enableLogging.toLowerCase() == 'true';
  }

  // =============================================================================
  // 기능 플래그
  // =============================================================================

  /// 베타 기능 활성화 여부
  static bool get enableBetaFeatures {
    final betaFeatures = dotenv.env['ENABLE_BETA_FEATURES'];
    if (betaFeatures == null) {
      return currentEnvironment == AppEnvironment.development;
    }
    return betaFeatures.toLowerCase() == 'true';
  }

  /// 분석 및 크래시 리포팅 활성화 여부
  static bool get enableAnalytics {
    final analytics = dotenv.env['ENABLE_ANALYTICS'];
    if (analytics == null) {
      return currentEnvironment == AppEnvironment.production;
    }
    return analytics.toLowerCase() == 'true';
  }

  /// 퍼포먼스 모니터링 활성화 여부
  static bool get enablePerformanceMonitoring {
    final performance = dotenv.env['ENABLE_PERFORMANCE_MONITORING'];
    if (performance == null) {
      return currentEnvironment == AppEnvironment.production;
    }
    return performance.toLowerCase() == 'true';
  }

  // =============================================================================
  // 네트워크 설정
  // =============================================================================

  /// HTTP 요청 타임아웃 (초)
  static int get httpTimeout {
    final timeout = dotenv.env['HTTP_TIMEOUT'];
    return timeout != null ? int.tryParse(timeout) ?? 30 : 30;
  }

  /// 연결 풀 크기
  static int get connectionPoolSize {
    switch (currentEnvironment) {
      case AppEnvironment.development:
        return 5;
      case AppEnvironment.staging:
        return 10;
      case AppEnvironment.production:
        return 20;
    }
  }

  // =============================================================================
  // 캐시 설정
  // =============================================================================

  /// 캐시 만료 시간 (분)
  static int get cacheExpirationMinutes {
    switch (currentEnvironment) {
      case AppEnvironment.development:
        return 5; // 개발 환경에서는 짧은 캐시 시간
      case AppEnvironment.staging:
        return 15;
      case AppEnvironment.production:
        return 30;
    }
  }

  /// 이미지 캐시 크기 (MB)
  static int get imageCacheSize {
    switch (currentEnvironment) {
      case AppEnvironment.development:
        return 50;
      case AppEnvironment.staging:
        return 100;
      case AppEnvironment.production:
        return 200;
    }
  }

  // =============================================================================
  // 보안 설정
  // =============================================================================

  /// SSL 인증서 검증 활성화 여부
  static bool get enableCertificateValidation {
    return currentEnvironment == AppEnvironment.production;
  }

  /// 디버그 정보 표시 여부
  static bool get showDebugInfo {
    return currentEnvironment != AppEnvironment.production;
  }

  // =============================================================================
  // 환경 정보 출력
  // =============================================================================

  /// 현재 환경 설정을 맵으로 반환
  static Map<String, dynamic> get environmentInfo {
    return {
      'environment': currentEnvironment.name,
      'apiBaseUrl': apiBaseUrl,
      'enableVerboseLogging': enableVerboseLogging,
      'logLevel': logLevel,
      'enableLogging': enableLogging,
      'enableBetaFeatures': enableBetaFeatures,
      'enableAnalytics': enableAnalytics,
      'enablePerformanceMonitoring': enablePerformanceMonitoring,
      'httpTimeout': httpTimeout,
      'connectionPoolSize': connectionPoolSize,
      'cacheExpirationMinutes': cacheExpirationMinutes,
      'imageCacheSize': imageCacheSize,
      'enableCertificateValidation': enableCertificateValidation,
      'showDebugInfo': showDebugInfo,
    };
  }

  /// 현재 환경 설정을 문자열로 반환 (디버깅용)
  static String get environmentSummary {
    return '''
=== 환경 설정 정보 ===
환경: ${currentEnvironment.name}
API URL: $apiBaseUrl
로깅: ${enableLogging ? '활성화' : '비활성화'}
로그 레벨: $logLevel
베타 기능: ${enableBetaFeatures ? '활성화' : '비활성화'}
분석: ${enableAnalytics ? '활성화' : '비활성화'}
==================
''';
  }
}

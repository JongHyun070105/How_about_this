// =============================================================================
// 앱 전역 상수 정의
// =============================================================================

import 'package:flutter/material.dart';

/// 앱에서 사용하는 전역 상수들을 정의하는 클래스
class AppConstants {
  AppConstants._(); // 인스턴스 생성 방지

  // =============================================================================
  // 앱 기본 정보
  // =============================================================================

  static const String appName = 'Food Rating App';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // =============================================================================
  // 광고 관련 상수
  // =============================================================================

  /// 테스트용 광고 ID들

  // =============================================================================
  // 네트워크 관련 상수
  // =============================================================================

  /// 허용된 도메인 목록
  static const List<String> allowedDomains = [
    'generativelanguage.googleapis.com', // Gemini API
    'googleads.g.doubleclick.net', // AdMob
    'googlesyndication.com', // AdMob
    'googleadservices.com', // AdMob
  ];

  /// HTTP 요청 타임아웃 (초)
  static const int httpTimeoutSeconds = 30;

  /// 최대 재시도 횟수
  static const int maxRetryAttempts = 3;

  // =============================================================================
  // 파일 및 이미지 관련 상수
  // =============================================================================

  /// 허용된 이미지 파일 확장자
  static const List<String> allowedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  /// 최대 이미지 파일 크기 (10MB)
  static const int maxImageSizeBytes = 10 * 1024 * 1024;

  /// 이미지 압축 품질 (0-100)
  static const int imageCompressionQuality = 80;

  // =============================================================================
  // 입력 데이터 제한
  // =============================================================================

  /// 음식명 최대 길이
  static const int maxFoodNameLength = 20;

  /// 음식명 최소 길이
  static const int minFoodNameLength = 1;

  /// 별점 최솟값
  static const double minRating = 0.0;

  /// 별점 최댓값
  static const double maxRating = 5.0;

  /// 리뷰 텍스트 최대 길이
  static const int maxReviewLength = 1000;

  // =============================================================================
  // UI 관련 상수
  // =============================================================================

  /// 기본 패딩
  static const double defaultPadding = 16.0;

  /// 기본 마진
  static const double defaultMargin = 8.0;

  /// 기본 보더 반지름
  static const double defaultBorderRadius = 8.0;

  /// 애니메이션 지속 시간 (밀리초)
  static const int defaultAnimationDurationMs = 300;

  // =============================================================================
  // 캐시 관련 상수
  // =============================================================================

  /// 이미지 캐시 최대 크기 (MB)
  static const int maxImageCacheSizeMB = 100;

  /// 데이터 캐시 만료 시간 (분)
  static const int dataCacheExpirationMinutes = 30;

  // =============================================================================
  // 정규 표현식 패턴
  // =============================================================================

  /// 유효한 음식명 패턴
  static const String validFoodNamePattern = r'^[가-힣a-zA-Z0-9\s\-_()]+$';

  /// API 키 숨기기 패턴
  static const String apiKeyHiddenPattern = r'API.*key.*[A-Za-z0-9]{20,}';

  /// 토큰 숨기기 패턴
  static const String tokenHiddenPattern = r'token.*[A-Za-z0-9]{20,}';

  /// 경로 숨기기 패턴
  static const String pathHiddenPattern = r'path.*\/.*\/';

  // =============================================================================
  // 에러 메시지
  // =============================================================================

  static const String errorApiKeyNotFound = 'API 키가 설정되지 않았습니다.';
  static const String errorInvalidImageFile = '유효하지 않은 이미지 파일입니다.';
  static const String errorImageTooLarge = '이미지 파일이 너무 큽니다.';
  static const String errorInvalidFoodName = '유효하지 않은 음식명입니다.';
  static const String errorInvalidRating = '별점은 0-5 사이의 값이어야 합니다.';
  static const String errorNetworkConnection = '네트워크 연결을 확인해주세요.';

  // =============================================================================
  // 성공 메시지
  // =============================================================================

  static const String successImageUploaded = '이미지가 성공적으로 업로드되었습니다.';
  static const String successRatingSaved = '평점이 저장되었습니다.';
  static const String successDataSynced = '데이터가 동기화되었습니다.';

  // =============================================================================
  // 음식 및 추천 관련 상수
  // =============================================================================
  static const Color defaultFoodColor = Color(0xFFFFE0B2); // orange.shade100
  static const String defaultFoodImage = 'assets/images/default_food.svg';
  static const String defaultFoodName = '음식을 선택해주세요';
  static const int recentFoodsLimit = 3;
}

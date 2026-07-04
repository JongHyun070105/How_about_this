import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/logger_service.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  FirebaseRemoteConfig? _customRemoteConfig;
  FirebaseRemoteConfig get _remoteConfig =>
      _customRemoteConfig ?? FirebaseRemoteConfig.instance;

  @visibleForTesting
  set mockRemoteConfig(FirebaseRemoteConfig config) =>
      _customRemoteConfig = config;

  // Key Constants
  static const String keyReviewCooldownDays = 'review_cooldown_days';
  static const String keyMaxDailyAiReviews = 'max_daily_ai_reviews';
  static const String keyMaxDailyRecommendations = 'max_daily_recommendations';
  static const String keyReviewTargetRecommendationCount =
      'review_target_recommendation_count';
  static const String keyReviewTargetGenerationCount =
      'review_target_generation_count';

  Future<void> initialize() async {
    try {
      // 1. 기본값(Defaults) 설정
      await _remoteConfig.setDefaults(const {
        keyReviewCooldownDays: 14,
        keyMaxDailyAiReviews: 5,
        keyMaxDailyRecommendations: 40,
        keyReviewTargetRecommendationCount: 10,
        keyReviewTargetGenerationCount: 3,
      });

      // 2. 개발 모드에서는 더 짧은 주기로 패치하도록 설정
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 5)
              : const Duration(hours: 12),
        ),
      );

      // 3. 서버 설정값을 패치 및 활성화
      await _remoteConfig.fetchAndActivate();

      LoggerService.i(
        'RemoteConfigService: Initialized correctly. values: '
        'cooldown: $reviewCooldownDays, reviews: $maxDailyAiReviews, recs: $maxDailyRecommendations, '
        'targetRec: $reviewTargetRecommendationCount, targetGen: $reviewTargetGenerationCount',
      );
    } catch (e, stack) {
      LoggerService.e('RemoteConfigService: Failed to initialize.', e, stack);
    }
  }

  int get reviewCooldownDays => _remoteConfig.getInt(keyReviewCooldownDays);
  int get maxDailyAiReviews => _remoteConfig.getInt(keyMaxDailyAiReviews);
  int get maxDailyRecommendations =>
      _remoteConfig.getInt(keyMaxDailyRecommendations);
  int get reviewTargetRecommendationCount =>
      _remoteConfig.getInt(keyReviewTargetRecommendationCount);
  int get reviewTargetGenerationCount =>
      _remoteConfig.getInt(keyReviewTargetGenerationCount);
}

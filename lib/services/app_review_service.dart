import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:review_ai/core/utils/logger_service.dart';
import 'package:review_ai/services/remote_config_service.dart';

/// 앱 리뷰 유도를 관리하는 서비스 클래스
class AppReviewService {
  final RemoteConfigService _remoteConfigService;
  final InAppReview _inAppReview;

  AppReviewService(this._remoteConfigService, {InAppReview? inAppReview})
    : _inAppReview = inAppReview ?? InAppReview.instance;

  // SharedPreferences Keys
  static const String _keyRecommendationCount = 'review_recommendation_count';
  static const String _keyReviewGenerationCount = 'review_generation_count';
  static const String _keyLastPromptTimestamp = 'review_last_prompt_timestamp';

  // SharedPreferences 캐시
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 추천(Today Recommendation) 발생 시 카운트 증가 및 조건 충족 시 리뷰 요청
  Future<void> onRecommendationReceived() {
    return _handleEvent(
      countKey: _keyRecommendationCount,
      targetCount: _remoteConfigService.reviewTargetRecommendationCount,
      reason: 'Target Recommendation Reached',
    );
  }

  /// AI 리뷰 생성 완료 시 카운트 증가 및 조건 충족 시 리뷰 요청
  Future<void> onReviewGenerated() {
    return _handleEvent(
      countKey: _keyReviewGenerationCount,
      targetCount: _remoteConfigService.reviewTargetGenerationCount,
      reason: 'Target Review Generation Reached',
    );
  }

  Future<void> _handleEvent({
    required String countKey,
    required int targetCount,
    required String reason,
  }) async {
    try {
      final prefs = await _getPrefs();
      int currentCount = prefs.getInt(countKey) ?? 0;
      currentCount++;
      await prefs.setInt(countKey, currentCount);

      LoggerService.i('AppReviewService: $countKey count = $currentCount');

      if (currentCount >= targetCount) {
        await prefs.setInt(countKey, 0);
        await _requestReviewIfNeeded(reason: '$reason ($currentCount)');
      }
    } catch (e, stack) {
      LoggerService.e('AppReviewService: Error tracking $countKey', e, stack);
    }
  }

  /// 리뷰 작성을 요청하기 위한 내부 로직 (쿨다운 체크 적용)
  Future<void> _requestReviewIfNeeded({required String reason}) async {
    try {
      final prefs = await _getPrefs();
      final lastPromptMillis = prefs.getInt(_keyLastPromptTimestamp) ?? 0;
      final lastPromptDate = DateTime.fromMillisecondsSinceEpoch(
        lastPromptMillis,
      );
      final currentDate = DateTime.now();

      final difference = currentDate.difference(lastPromptDate).inDays;
      final coolDownDays = _remoteConfigService.reviewCooldownDays;

      if (difference >= coolDownDays || lastPromptMillis == 0) {
        if (await _inAppReview.isAvailable()) {
          LoggerService.i(
            'AppReviewService: Requesting In-App Review. Reason: $reason',
          );
          await _inAppReview.requestReview();
          await prefs.setInt(
            _keyLastPromptTimestamp,
            currentDate.millisecondsSinceEpoch,
          );
        } else {
          LoggerService.w(
            'AppReviewService: In-App Review is not available on this device/platform.',
          );
        }
      } else {
        LoggerService.i(
          'AppReviewService: Review request skipped. Cool down active ($difference / $coolDownDays days).',
        );
      }
    } catch (e, stack) {
      LoggerService.e('AppReviewService: Error requesting review', e, stack);
    }
  }

  /// 강제로 리뷰 팝업을 띄우는 함수 (디버깅/테스트 전용)
  Future<void> forceRequestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        LoggerService.i('AppReviewService: Force requesting In-App Review');
        await _inAppReview.requestReview();
      } else {
        LoggerService.w(
          'AppReviewService: In-App Review is not available forcefully.',
        );
      }
    } catch (e, stack) {
      LoggerService.e(
        'AppReviewService: Error during force review request',
        e,
        stack,
      );
    }
  }
}

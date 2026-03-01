import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:review_ai/core/utils/logger_service.dart';

/// 앱 리뷰 유도를 관리하는 서비스 클래스
class AppReviewService {
  static final AppReviewService _instance = AppReviewService._internal();

  factory AppReviewService() => _instance;

  AppReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  // SharedPreferences Keys
  static const String _keyRecommendationCount = 'review_recommendation_count';
  static const String _keyReviewGenerationCount = 'review_generation_count';
  static const String _keyLastPromptTimestamp = 'review_last_prompt_timestamp';

  // 팝업 표시 조건 (기획에 맞게 조절 가능)
  static const int _targetRecommendationCount = 10;
  static const int _targetReviewGenerationCount = 3;
  static const int _coolDownDays = 14;

  /// 추천(Today Recommendation) 발생 시 카운트 증가 및 조건 충족 시 리뷰 요청
  Future<void> onRecommendationReceived() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int currentCount = prefs.getInt(_keyRecommendationCount) ?? 0;
      currentCount++;
      await prefs.setInt(_keyRecommendationCount, currentCount);

      LoggerService.i('AppReviewService: Recommendation count = $currentCount');

      if (currentCount >= _targetRecommendationCount) {
        // 이미 표시 조건에 만족했으므로 카운트를 초기화하고 리뷰를 띄움
        await prefs.setInt(_keyRecommendationCount, 0);
        await _requestReviewIfNeeded(
          reason: 'Target Recommendation Reached ($currentCount)',
        );
      }
    } catch (e) {
      LoggerService.e(
        'AppReviewService: Error tracking recommendation count',
        e,
      );
    }
  }

  /// AI 리뷰 생성 완료 시 카운트 증가 및 조건 충족 시 리뷰 요청
  Future<void> onReviewGenerated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int currentCount = prefs.getInt(_keyReviewGenerationCount) ?? 0;
      currentCount++;
      await prefs.setInt(_keyReviewGenerationCount, currentCount);

      LoggerService.i(
        'AppReviewService: Review generation count = $currentCount',
      );

      if (currentCount >= _targetReviewGenerationCount) {
        // 이미 표시 조건에 만족했으므로 카운트를 초기화하고 리뷰를 띄움
        await prefs.setInt(_keyReviewGenerationCount, 0);
        await _requestReviewIfNeeded(
          reason: 'Target Review Generation Reached ($currentCount)',
        );
      }
    } catch (e) {
      LoggerService.e(
        'AppReviewService: Error tracking review generation count',
        e,
      );
    }
  }

  /// 리뷰 작성을 요청하기 위한 내부 로직 (쿨다운 체크 적용)
  Future<void> _requestReviewIfNeeded({required String reason}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPromptMillis = prefs.getInt(_keyLastPromptTimestamp) ?? 0;
      final lastPromptDate = DateTime.fromMillisecondsSinceEpoch(
        lastPromptMillis,
      );
      final currentDate = DateTime.now();

      final difference = currentDate.difference(lastPromptDate).inDays;

      if (difference >= _coolDownDays || lastPromptMillis == 0) {
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
          'AppReviewService: Review request skipped. Cool down active ($difference / $_coolDownDays days).',
        );
      }
    } catch (e) {
      LoggerService.e('AppReviewService: Error requesting review', e);
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
    } catch (e) {
      LoggerService.e('AppReviewService: Error during force review request', e);
    }
  }
}

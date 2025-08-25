import 'package:shared_preferences/shared_preferences.dart';

class UsageTrackingService {
  static const String _lastResetDateKey = 'last_reset_date';
  static const String _reviewCountKey = 'review_count';
  static const String _recommendationCountKey =
      'recommendation_count'; // 추천 횟수용 키
  static const String _totalRecommendationCountKey =
      'total_recommendation_count';
  static const int _maxReviewsPerDay = 5;
  static const int _maxRecommendationsPerDay = 20; // 일일 추천 제한
  static const int _maxTotalRecommendationsPerDay = 20;

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  /// 사용량 카운터를 초기화합니다 (자정 기준).
  Future<void> _resetCountsIfNewDay() async {
    final prefs = await _getPrefs();
    final lastResetDateStr = prefs.getString(_lastResetDateKey);
    final now = DateTime.now();

    if (lastResetDateStr != null) {
      final lastResetDate = DateTime.parse(lastResetDateStr);
      if (lastResetDate.year == now.year &&
          lastResetDate.month == now.month &&
          lastResetDate.day == now.day) {
        // 같은 날이면 초기화하지 않음
        return;
      }
    }

    // 새 날이거나 첫 실행이면 모든 카운트 초기화
    await prefs.setInt(_reviewCountKey, 0);
    await prefs.setInt(_recommendationCountKey, 0); // 추천 횟수 초기화
    await prefs.setInt(_totalRecommendationCountKey, 0);
    await prefs.setString(
      _lastResetDateKey,
      now.toIso8601String().substring(0, 10),
    ); // 날짜만 저장
  }

  /// 리뷰 생성 횟수를 증가시키고 제한을 확인합니다.
  Future<bool> incrementReviewCount() async {
    await _resetCountsIfNewDay();
    final prefs = await _getPrefs();
    int currentCount = prefs.getInt(_reviewCountKey) ?? 0;

    if (currentCount < _maxReviewsPerDay) {
      await prefs.setInt(_reviewCountKey, currentCount + 1);
      return true;
    }
    return false;
  }

  /// 추천 횟수를 증가시킵니다 (today_recommendation_screen.dart에서 사용).
  Future<void> incrementRecommendationCount() async {
    await _resetCountsIfNewDay();
    final prefs = await _getPrefs();
    int currentCount = prefs.getInt(_recommendationCountKey) ?? 0;
    await prefs.setInt(_recommendationCountKey, currentCount + 1);
  }

  /// 총 추천 사용 횟수를 증가시키고 제한을 확인합니다.
  Future<bool> incrementTotalRecommendationCount() async {
    await _resetCountsIfNewDay();
    final prefs = await _getPrefs();
    int currentCount = prefs.getInt(_totalRecommendationCountKey) ?? 0;

    if (currentCount < _maxTotalRecommendationsPerDay) {
      await prefs.setInt(_totalRecommendationCountKey, currentCount + 1);
      return true;
    }
    return false;
  }

  /// 현재 리뷰 생성 횟수를 가져옵니다.
  Future<int> getReviewCount() async {
    await _resetCountsIfNewDay();
    final prefs = await _getPrefs();
    return prefs.getInt(_reviewCountKey) ?? 0;
  }

  /// 현재 추천 횟수를 가져옵니다.
  Future<int> getRecommendationCount() async {
    await _resetCountsIfNewDay();
    final prefs = await _getPrefs();
    return prefs.getInt(_recommendationCountKey) ?? 0;
  }

  /// 총 추천 사용 횟수를 가져옵니다.
  Future<int> getTotalRecommendationCount() async {
    await _resetCountsIfNewDay();
    final prefs = await _getPrefs();
    return prefs.getInt(_totalRecommendationCountKey) ?? 0;
  }

  /// 일일 추천 제한에 도달했는지 확인합니다 (today_recommendation_screen.dart에서 사용).
  Future<bool> hasReachedDailyLimit() async {
    await _resetCountsIfNewDay();
    final currentCount = await getRecommendationCount();
    return currentCount >= _maxRecommendationsPerDay;
  }

  /// 남은 추천 사용 가능 횟수를 반환합니다.
  Future<int> getRemainingRecommendationCount() async {
    await _resetCountsIfNewDay();
    final used = await getRecommendationCount();
    return (_maxRecommendationsPerDay - used).clamp(
      0,
      _maxRecommendationsPerDay,
    );
  }

  /// 남은 총 추천 사용 가능 횟수를 반환합니다.
  Future<int> getRemainingTotalRecommendationCount() async {
    await _resetCountsIfNewDay();
    final used = await getTotalRecommendationCount();
    return (_maxTotalRecommendationsPerDay - used).clamp(
      0,
      _maxTotalRecommendationsPerDay,
    );
  }

  /// 남은 리뷰 생성 가능 횟수를 반환합니다.
  Future<int> getRemainingReviewCount() async {
    await _resetCountsIfNewDay();
    final used = await getReviewCount();
    return (_maxReviewsPerDay - used).clamp(0, _maxReviewsPerDay);
  }

  /// 리뷰 생성 제한에 도달했는지 확인합니다.
  Future<bool> hasReachedReviewLimit() async {
    await _resetCountsIfNewDay();
    return await getReviewCount() >= _maxReviewsPerDay;
  }

  /// 총 추천 사용 제한에 도달했는지 확인합니다.
  Future<bool> hasReachedTotalRecommendationLimit() async {
    await _resetCountsIfNewDay();
    return await getTotalRecommendationCount() >=
        _maxTotalRecommendationsPerDay;
  }

  /// 모든 사용량 카운트를 강제로 초기화합니다 (테스트 또는 디버그용).
  Future<void> forceResetAllCounts() async {
    final prefs = await _getPrefs();
    await prefs.remove(_lastResetDateKey);
    await prefs.remove(_reviewCountKey);
    await prefs.remove(_recommendationCountKey);
    await prefs.remove(_totalRecommendationCountKey);
  }
}

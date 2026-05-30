import 'package:review_ai/services/persistent_storage_service.dart';
import 'package:review_ai/services/server_time_service.dart';
import 'package:review_ai/services/remote_config_service.dart';
import 'package:review_ai/core/utils/logger_service.dart';

class UsageTrackingService {
  final RemoteConfigService _remoteConfigService;
  final PersistentStorageService _storageService = PersistentStorageService();

  UsageTrackingService(this._remoteConfigService);
  static const String _usageDataFile = 'usage_data.json';

  static const String _lastResetDateKey = 'last_reset_date';
  static const String _reviewCountKey = 'review_count';
  static const String _totalRecommendationCountKey =
      'total_recommendation_count';
  static const String _lastAccessTimestampKey = 'last_access_timestamp';

  /// 세션 내 날짜 체크 캐싱 (동일 날짜 내에서 반복 서버 시간 조회를 방지)
  String? _lastCheckedDate;

  int get _maxReviewsPerDay => _remoteConfigService.maxDailyAiReviews;
  int get _maxTotalRecommendationsPerDay =>
      _remoteConfigService.maxDailyRecommendations;

  /// 사용량 카운터를 초기화합니다 (서버 시간 기준).
  Future<void> _resetCountsIfNewDay() async {
    try {
      // 서버 시간 가져오기
      final serverDate = await ServerTimeService.getCurrentDate();
      final serverDateStr = serverDate.toIso8601String().substring(0, 10);
      final serverTimestamp = serverDate.millisecondsSinceEpoch;

      // 세션 캐시로 동일 날짜 내 중복 서버 시간 조회 방지
      if (_lastCheckedDate == serverDateStr) {
        return;
      }

      final lastAccessTimestamp = await _storageService.getValue<int>(
        _usageDataFile,
        _lastAccessTimestampKey,
      );

      if (lastAccessTimestamp != null &&
          serverTimestamp < lastAccessTimestamp) {
        final diff = lastAccessTimestamp - serverTimestamp;
        LoggerService.d(
          'Time manipulation detected! Last access was ${diff}ms in the future',
        );
      }

      final lastResetDateStr = await _storageService.getValue<String>(
        _usageDataFile,
        _lastResetDateKey,
      );

      if (lastResetDateStr != null && lastResetDateStr == serverDateStr) {
        // 같은 날이면 초기화하지 않음, 캐시 업데이트 후 리턴
        _lastCheckedDate = serverDateStr;
        await _storageService.setValue(
          _usageDataFile,
          _lastAccessTimestampKey,
          serverTimestamp,
        );
        return;
      }

      // 새 날이거나 첫 실행이면 모든 카운트 초기화
      await _storageService.setValue(_usageDataFile, _reviewCountKey, 0);
      await _storageService.setValue(
        _usageDataFile,
        _totalRecommendationCountKey,
        0,
      );
      await _storageService.setValue(
        _usageDataFile,
        _lastResetDateKey,
        serverDateStr,
      );
      await _storageService.setValue(
        _usageDataFile,
        _lastAccessTimestampKey,
        serverTimestamp,
      );

      _lastCheckedDate = serverDateStr;

      LoggerService.d(
        'Usage counts reset for new day: ${serverDate.toIso8601String()}',
      );
    } catch (e) {
      LoggerService.e('Error in _resetCountsIfNewDay: $e');
      // 에러 발생 시 로컬 시간 사용 (폴백)
      final now = DateTime.now();
      final nowDateStr = now.toIso8601String().substring(0, 10);

      final lastResetDateStr = await _storageService.getValue<String>(
        _usageDataFile,
        _lastResetDateKey,
      );

      if (lastResetDateStr != null && lastResetDateStr == nowDateStr) {
        _lastCheckedDate = nowDateStr;
        return;
      }

      await _storageService.setValue(_usageDataFile, _reviewCountKey, 0);
      await _storageService.setValue(
        _usageDataFile,
        _totalRecommendationCountKey,
        0,
      );
      await _storageService.setValue(
        _usageDataFile,
        _lastResetDateKey,
        nowDateStr,
      );
      _lastCheckedDate = nowDateStr;
    }
  }

  /// 리뷰 생성 횟수를 증가시키고 제한을 확인합니다.
  Future<bool> incrementReviewCount() async {
    await _resetCountsIfNewDay();
    final int currentCount =
        await _storageService.getValue<int>(_usageDataFile, _reviewCountKey) ??
        0;

    if (currentCount < _maxReviewsPerDay) {
      await _storageService.setValue(
        _usageDataFile,
        _reviewCountKey,
        currentCount + 1,
      );
      return true;
    }
    return false;
  }

  /// 총 추천 사용 횟수를 증가시키고 제한을 확인합니다.
  Future<bool> incrementTotalRecommendationCount() async {
    await _resetCountsIfNewDay();
    final int currentCount =
        await _storageService.getValue<int>(
          _usageDataFile,
          _totalRecommendationCountKey,
        ) ??
        0;

    if (currentCount < _maxTotalRecommendationsPerDay) {
      await _storageService.setValue(
        _usageDataFile,
        _totalRecommendationCountKey,
        currentCount + 1,
      );
      return true;
    }
    return false;
  }

  /// 현재 리뷰 생성 횟수를 가져옵니다.
  Future<int> getReviewCount() async {
    await _resetCountsIfNewDay();
    return await _storageService.getValue<int>(
          _usageDataFile,
          _reviewCountKey,
        ) ??
        0;
  }

  /// 총 추천 사용 횟수를 가져옵니다.
  Future<int> getTotalRecommendationCount() async {
    await _resetCountsIfNewDay();
    return await _storageService.getValue<int>(
          _usageDataFile,
          _totalRecommendationCountKey,
        ) ??
        0;
  }

  /// 남은 추천 사용 가능 횟수를 반환합니다.
  Future<int> getRemainingRecommendationCount() async {
    final used = await getTotalRecommendationCount();
    return (_maxTotalRecommendationsPerDay - used).clamp(
      0,
      _maxTotalRecommendationsPerDay,
    );
  }

  /// 남은 총 추천 사용 가능 횟수를 반환합니다.
  /// [getRemainingRecommendationCount]와 동일한 기능입니다.
  Future<int> getRemainingTotalRecommendationCount() async {
    return getRemainingRecommendationCount();
  }

  /// 남은 리뷰 생성 가능 횟수를 반환합니다.
  Future<int> getRemainingReviewCount() async {
    final used = await getReviewCount();
    return (_maxReviewsPerDay - used).clamp(0, _maxReviewsPerDay);
  }

  /// 리뷰 생성 제한에 도달했는지 확인합니다.
  Future<bool> hasReachedReviewLimit() async {
    return await getReviewCount() >= _maxReviewsPerDay;
  }

  /// 총 추천 사용 제한에 도달했는지 확인합니다.
  Future<bool> hasReachedTotalRecommendationLimit() async {
    return await getTotalRecommendationCount() >=
        _maxTotalRecommendationsPerDay;
  }

  /// 모든 사용량 카운트를 강제로 초기화합니다 (테스트 또는 디버그용).
  Future<void> forceResetAllCounts() async {
    _lastCheckedDate = null;
    await _storageService.clearFile(_usageDataFile);
  }
}

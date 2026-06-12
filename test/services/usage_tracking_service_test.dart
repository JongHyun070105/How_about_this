import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:review_ai/services/usage_tracking_service.dart';
import 'package:review_ai/services/persistent_storage_service.dart';
import 'package:review_ai/services/remote_config_service.dart';

class MockPersistentStorageService extends PersistentStorageService {
  int getCallCount = 0;
  int setCallCount = 0;
  final Map<String, dynamic> store = {};

  @override
  Future<T?> getValue<T>(String fileName, String key) async {
    getCallCount++;
    return store['$fileName:$key'] as T?;
  }

  @override
  Future<void> setValue<T>(String fileName, String key, T value) async {
    setCallCount++;
    store['$fileName:$key'] = value;
  }
}

class MockRemoteConfigService extends Mock implements RemoteConfigService {
  @override
  int get maxDailyAiReviews => 10;

  @override
  int get maxDailyRecommendations => 20;
}

void main() {
  late MockPersistentStorageService mockStorage;
  late MockRemoteConfigService mockConfig;
  late UsageTrackingService trackingService;

  setUp(() {
    mockStorage = MockPersistentStorageService();
    mockConfig = MockRemoteConfigService();
    trackingService = UsageTrackingService(
      mockConfig,
      storageService: mockStorage,
    );
  });

  group('UsageTrackingService 캐싱 및 기능 검증', () {
    test('최초 사용량 조회 시 디스크 I/O가 발생하고 이후 캐시를 사용한다', () async {
      mockStorage.store['usage_data.json:review_count'] = 3;
      mockStorage.store['usage_data.json:total_recommendation_count'] = 5;
      mockStorage.store['usage_data.json:last_reset_date'] = '2026-06-12';

      final reviewCount1 = await trackingService.getReviewCount();
      expect(reviewCount1, 3);
      expect(mockStorage.getCallCount, greaterThan(0));

      final initialGetCalls = mockStorage.getCallCount;

      final reviewCount2 = await trackingService.getReviewCount();
      expect(reviewCount2, 3);
      expect(mockStorage.getCallCount, initialGetCalls); // 추가 getCall 없음
    });

    test('카운트 증가 시 캐시가 즉시 반영되며 추가적인 읽기 I/O는 0회다', () async {
      mockStorage.store['usage_data.json:review_count'] = 2;
      mockStorage.store['usage_data.json:total_recommendation_count'] = 1;
      mockStorage.store['usage_data.json:last_reset_date'] = '2026-06-12';

      await trackingService.getReviewCount();
      mockStorage.getCallCount = 0;
      mockStorage.setCallCount = 0;

      final success = await trackingService.incrementReviewCount();
      expect(success, isTrue);
      expect(mockStorage.setCallCount, 1); // 쓰기 1회
      expect(mockStorage.getCallCount, 0); // 읽기 0회 (캐시 이용)

      final count = await trackingService.getReviewCount();
      expect(count, 3);
      expect(mockStorage.getCallCount, 0); // 읽기 여전히 0회
    });

    test('새로운 날짜가 도래하면 일일 카운터가 초기화된다', () async {
      mockStorage.store['usage_data.json:review_count'] = 5;
      mockStorage.store['usage_data.json:total_recommendation_count'] = 10;
      mockStorage.store['usage_data.json:last_reset_date'] = '2026-06-11';

      final count = await trackingService.getReviewCount();
      expect(count, 0); // 날짜 바뀜에 따라 0으로 초기화

      final recCount = await trackingService.getTotalRecommendationCount();
      expect(recCount, 0); // 추천 수 역시 0으로 초기화
    });
  });
}

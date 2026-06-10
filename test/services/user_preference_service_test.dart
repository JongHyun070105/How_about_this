import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/services/user_preference_service.dart';
import 'package:review_ai/services/persistent_storage_service.dart';

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

void main() {
  late MockPersistentStorageService mockStorage;

  setUp(() {
    mockStorage = MockPersistentStorageService();
    UserPreferenceService.setStorageServiceForTesting(mockStorage);
    UserPreferenceService.clearCache();
  });

  group('UserPreferenceService 캐싱 및 기능 검증', () {
    test('음식 선택 기록 최초 조회 시 디스크 I/O가 1회 발생한다', () async {
      mockStorage.store['user_preferences.json:food_selection_history'] = [
        {
          'foodName': '치킨',
          'category': '한식',
          'selectedAt': DateTime.now().toIso8601String(),
          'liked': true,
        },
      ];

      final history1 = await UserPreferenceService.getFoodSelectionHistory();
      expect(history1.length, 1);
      expect(history1[0].foodName, '치킨');
      expect(mockStorage.getCallCount, 1);

      // 두 번째 호출 시 메모리 캐시를 사용하여 getCallCount가 여전히 1이어야 함
      final history2 = await UserPreferenceService.getFoodSelectionHistory();
      expect(history2.length, 1);
      expect(mockStorage.getCallCount, 1); // 추가 호출 없음
    });

    test('음식 기록 저장 시 캐시가 즉시 업데이트되며 쓰기 I/O가 발생한다', () async {
      await UserPreferenceService.recordFoodSelection(
        foodName: '피자',
        category: '양식',
        liked: true,
      );

      // 쓰기 I/O 발생 검증
      expect(mockStorage.setCallCount, greaterThan(0));

      // 디스크 호출 횟수를 초기화하고 다시 읽어올 때 캐시를 타서 getCallCount가 0이어야 함
      mockStorage.getCallCount = 0;
      final history = await UserPreferenceService.getFoodSelectionHistory();
      expect(history.length, 1);
      expect(history[0].foodName, '피자');
      expect(mockStorage.getCallCount, 0); // 디스크 안 거침
    });

    test('싫어하는 음식 캐시 동작 검증', () async {
      mockStorage.store['user_preferences.json:disliked_foods'] = ['가지', '오이'];

      final disliked1 = await UserPreferenceService.getDislikedFoods();
      expect(disliked1, contains('가지'));
      expect(mockStorage.getCallCount, 1);

      // 캐싱되어 getCallCount 증가하지 않음
      final disliked2 = await UserPreferenceService.getDislikedFoods();
      expect(disliked2, contains('오이'));
      expect(mockStorage.getCallCount, 1);
    });
  });
}

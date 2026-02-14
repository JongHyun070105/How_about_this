import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/services/food_insight_service.dart';
import 'package:review_ai/services/ai_food_insight_service.dart';
import 'package:review_ai/providers/review_provider.dart';

/// 테스트용 ReviewHistoryEntry 생성 헬퍼
ReviewHistoryEntry _createEntry({
  String foodName = '김치찌개',
  String category = '한식',
  DateTime? createdAt,
}) {
  return ReviewHistoryEntry(
    foodName: foodName,
    category: category,
    tasteRating: 4.0,
    deliveryRating: 4.0,
    portionRating: 3.5,
    priceRating: 3.0,
    reviewStyle: '일반',
    generatedReviews: ['좋은 리뷰'],
    createdAt: createdAt,
  );
}

void main() {
  group('AiInsightResult', () {
    test('AI 인사이트 결과 생성', () {
      final result = AiInsightResult(message: 'AI가 생성한 인사이트', isAi: true);

      expect(result.message, 'AI가 생성한 인사이트');
      expect(result.isAi, true);
    });

    test('로컬 폴백 결과 생성', () {
      final result = AiInsightResult(message: '로컬 메시지', isAi: false);

      expect(result.message, '로컬 메시지');
      expect(result.isAi, false);
    });
  });

  group('AiFoodInsightService - 폴백 로직', () {
    test('빈 히스토리일 때 로컬 폴백 반환', () async {
      final service = AiFoodInsightService();
      final result = await service.getInsight([]);

      expect(result.isAi, false);
      expect(result.message, isNotEmpty);
      expect(result.message, FoodInsightService.generateInsightMessage([]));
    });

    test('네트워크 실패 시 로컬 폴백 반환', () async {
      final service = AiFoodInsightService();

      final history = <ReviewHistoryEntry>[
        _createEntry(foodName: '김치찌개', category: '한식'),
        _createEntry(
          foodName: '비빔밥',
          category: '한식',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      final result = await service.getInsight(history);

      // 인증 실패 → 로컬 폴백
      expect(result.isAi, false);
      expect(result.message, isNotEmpty);
    });
  });

  group('FoodInsightService와 연동', () {
    test('로컬 인사이트 메시지가 유효한 문자열', () {
      final history = <ReviewHistoryEntry>[
        _createEntry(foodName: '짜장면', category: '중식'),
      ];

      final message = FoodInsightService.generateInsightMessage(history);
      expect(message, isNotEmpty);
      expect(message, isA<String>());
    });

    test('빈 히스토리 인사이트 메시지', () {
      final message = FoodInsightService.generateInsightMessage([]);
      expect(message, contains('첫 리뷰'));
    });
  });
}

// ignore_for_file: avoid_print, unused_local_variable
import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';
import 'package:review_ai/services/food_stats_service.dart';

void main() {
  group('FoodStatsService 성능 벤치마크 테스트', () {
    test('기존 다중 루프 순회 방식 vs 최적화 단일 패스 및 캐싱 방식 속도 비교', () {
      // 1. 테스트용 대용량 Mock 데이터 준비 (200개 리뷰 히스토리 생성)
      final List<ReviewHistoryEntry> mockHistory = [];
      final List<String> categories = [
        '한식',
        '중식',
        '일식',
        '양식',
        '아시안',
        '디저트',
        '패스트푸드',
        '기타',
      ];
      final List<String> foods = [
        '김치찌개',
        '짜장면',
        '초밥',
        '파스타',
        '쌀국수',
        '와플',
        '햄버거',
        '치킨',
      ];

      final now = DateTime.now();
      for (int i = 0; i < 200; i++) {
        final categoryIndex = i % categories.length;
        final foodIndex = i % foods.length;
        mockHistory.add(
          ReviewHistoryEntry(
            foodName: foods[foodIndex],
            restaurantName: '테스트 식당 $i',
            category: categories[categoryIndex],
            deliveryRating: (i % 5) + 1.0,
            tasteRating: ((i + 1) % 5) + 1.0,
            portionRating: ((i + 2) % 5) + 1.0,
            priceRating: ((i + 3) % 5) + 1.0,
            reviewStyle: '간결하게',
            generatedReviews: ['맛있어요 $i'],
            createdAt: now.subtract(
              Duration(hours: i * 2),
            ), // 7일 전후 데이터가 혼재하도록 설정
          ),
        );
      }

      const int iterations = 300; // 반복 연산 횟수

      // 2. [기존 방식 시뮬레이션] 각 지표별 개별 순회 루프 + InsightMessage 내 다중 재순회
      final stopwatchNoOptimization = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        // 기존 generateSummary 및 generateInsightMessage가 동작하던 패턴 그대로 실행
        final totalReviews = mockHistory.length;
        final categoryFrequency = FoodStatsService.getCategoryFrequency(
          mockHistory,
        );
        final topFoods = FoodStatsService.getTopFoods(mockHistory, limit: 3);
        final weeklyEntries = FoodStatsService.getRecentEntries(
          mockHistory,
          days: 7,
        );
        final averageRatings = FoodStatsService.getAverageRatings(mockHistory);
        final streak = FoodStatsService.getRecentStreak(mockHistory);

        // generateInsightMessage 내부에서 발생했던 다중 개별 재호출 시뮬레이션
        final msgStreak = FoodStatsService.getRecentStreak(mockHistory);
        final msgTopFoods = FoodStatsService.getTopFoods(mockHistory, limit: 1);
        final msgWeeklyEntries = FoodStatsService.getRecentEntries(
          mockHistory,
          days: 7,
        );
        final msgWeeklyCategories = FoodStatsService.getCategoryFrequency(
          msgWeeklyEntries,
        );
        final msgRatings = FoodStatsService.getAverageRatings(mockHistory);

        // 시뮬레이션 변수 검증 (dead code elimination 방지용)
        expect(totalReviews, equals(200));
        expect(categoryFrequency, isNotEmpty);
        expect(topFoods.length, lessThanOrEqualTo(3));
        expect(weeklyEntries, isNotNull);
        expect(averageRatings, isNotEmpty);
        expect(msgWeeklyCategories, isNotNull);
      }
      stopwatchNoOptimization.stop();
      final int timeNoOptimization =
          stopwatchNoOptimization.elapsedMilliseconds;

      // 3. [최적화 방식] 단일 패스 순회 및 통계 전달 캐싱 방식
      final stopwatchWithOptimization = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        final summary = FoodStatsService.generateSummary(mockHistory);

        // 변수 검증
        expect(summary['totalReviews'], equals(200));
        expect(summary['categoryFrequency'], isNotEmpty);
        expect(summary['topFoods'].length, lessThanOrEqualTo(3));
        expect(summary['averageRatings'], isNotEmpty);
      }
      stopwatchWithOptimization.stop();
      final int timeWithOptimization =
          stopwatchWithOptimization.elapsedMilliseconds;

      print('----------------------------------------');
      print('리뷰 히스토리 개수: ${mockHistory.length} 개');
      print('테스트 반복 횟수: $iterations 회');
      print('기존 다중 루프 방식 소요시간: $timeNoOptimization ms');
      print('최적화 단일 패스 방식 소요시간: $timeWithOptimization ms');
      print(
        '성능 개선율: ${((timeNoOptimization - timeWithOptimization) / timeNoOptimization * 100).toStringAsFixed(2)}%',
      );
      print('----------------------------------------');

      // 최적화 방식이 기존 방식보다 성능이 더 좋아야 함
      expect(timeWithOptimization, lessThan(timeNoOptimization));
    });
    group('유효성 테스트', () {
      test('최적화된 generateSummary의 결과 무결성 검증', () {
        final List<ReviewHistoryEntry> history = [
          ReviewHistoryEntry(
            foodName: '김치찌개',
            category: '한식',
            deliveryRating: 5.0,
            tasteRating: 5.0,
            portionRating: 4.0,
            priceRating: 4.0,
            reviewStyle: '간결하게',
            generatedReviews: ['맛있어요'],
            createdAt: DateTime.now(),
          ),
          ReviewHistoryEntry(
            foodName: '초밥',
            category: '일식',
            deliveryRating: 4.0,
            tasteRating: 4.0,
            portionRating: 5.0,
            priceRating: 3.0,
            reviewStyle: '간결하게',
            generatedReviews: ['괜찮아요'],
            createdAt: DateTime.now().subtract(
              const Duration(days: 10),
            ), // 7일 이전 데이터
          ),
        ];

        final summary = FoodStatsService.generateSummary(history);

        expect(summary['totalReviews'], equals(2));
        expect(summary['weeklyCount'], equals(1)); // 7일 이내 데이터는 1개
        expect(summary['favoriteCategory'], equals('한식'));
        expect(summary['averageRatings']['taste'], equals(4.5)); // (5+4)/2
        expect(summary['averageRatings']['delivery'], equals(4.5));
        expect(summary['averageRatings']['portion'], equals(4.5));
        expect(summary['averageRatings']['price'], equals(3.5)); // (4+3)/2
      });
    });
  });
}

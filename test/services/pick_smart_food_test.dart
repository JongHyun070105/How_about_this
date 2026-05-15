import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/data/models/food_recommendation.dart';
import 'package:review_ai/services/recommendation_service.dart';
import 'package:review_ai/services/user_preference_service.dart';
import 'package:review_ai/services/weather_service.dart';

void main() {
  group('RecommendationService.pickSmartFood', () {
    final sampleFoods = [
      const FoodRecommendation(name: '김치찌개', imageUrl: ''),
      const FoodRecommendation(name: '된장찌개', imageUrl: ''),
      const FoodRecommendation(name: '비빔밥', imageUrl: ''),
      const FoodRecommendation(name: '냉면', imageUrl: ''),
      const FoodRecommendation(name: '삼겹살', imageUrl: ''),
    ];

    final defaultPreferences = UserPreferenceAnalysis(
      preferredCategories: [],
      preferredFoods: [],
      dislikedFoods: [],
      categoryScores: {},
    );

    test('빈 리스트는 예외를 던진다', () {
      expect(
        () => RecommendationService.pickSmartFood([], [], defaultPreferences),
        throwsException,
      );
    });

    test('추천 결과가 food와 reason을 포함한다', () {
      final result = RecommendationService.pickSmartFood(
        sampleFoods,
        [],
        defaultPreferences,
      );

      expect(result.food, isNotNull);
      expect(result.reason, isNotEmpty);
      expect(sampleFoods.contains(result.food), isTrue);
    });

    test('최근 먹은 음식은 가능하면 제외한다', () {
      // 4개를 최근 먹은 것으로 표시하면, 남은 1개가 선택되어야 함
      final recentFoods = ['김치찌개', '된장찌개', '비빔밥', '냉면'];

      final result = RecommendationService.pickSmartFood(
        sampleFoods,
        recentFoods,
        defaultPreferences,
      );

      expect(result.food.name, '삼겹살');
    });

    test('싫어하는 음식은 가능하면 제외한다', () {
      final prefsWithDislikes = UserPreferenceAnalysis(
        preferredCategories: [],
        preferredFoods: [],
        dislikedFoods: ['김치찌개', '된장찌개', '비빔밥', '냉면'],
        categoryScores: {},
      );

      final result = RecommendationService.pickSmartFood(
        sampleFoods,
        [],
        prefsWithDislikes,
      );

      expect(result.food.name, '삼겹살');
    });

    test('모든 음식이 필터링되면 전체 목록에서 선택한다', () {
      final prefsWithAllDisliked = UserPreferenceAnalysis(
        preferredCategories: [],
        preferredFoods: [],
        dislikedFoods: ['김치찌개', '된장찌개', '비빔밥', '냉면', '삼겹살'],
        categoryScores: {},
      );

      final result = RecommendationService.pickSmartFood(sampleFoods, [
        '김치찌개',
        '된장찌개',
        '비빔밥',
        '냉면',
        '삼겹살',
      ], prefsWithAllDisliked);

      expect(sampleFoods.contains(result.food), isTrue);
    });

    test('선호 음식에 대한 추천 사유를 반환한다', () {
      final prefsWithFavorites = UserPreferenceAnalysis(
        preferredCategories: [],
        preferredFoods: ['삼겹살'],
        dislikedFoods: ['김치찌개', '된장찌개', '비빔밥', '냉면'],
        categoryScores: {},
      );

      final result = RecommendationService.pickSmartFood(
        sampleFoods,
        [],
        prefsWithFavorites,
      );

      // 삼겹살만 남거나, 선호도 가중치로 높은 확률로 선택
      if (result.food.name == '삼겹살') {
        expect(result.reason, contains('좋아하시는'));
      }
    });

    test('비 오는 날 국물 음식에 가중치가 적용된다', () {
      final soupFoods = [
        const FoodRecommendation(name: '김치찌개', imageUrl: ''),
        const FoodRecommendation(name: '냉면', imageUrl: ''),
      ];

      // 여러 번 실행해서 찌개가 더 자주 선택되는지 확인
      int soupCount = 0;
      const trials = 100;

      for (int i = 0; i < trials; i++) {
        final result = RecommendationService.pickSmartFood(
          soupFoods,
          [],
          defaultPreferences,
          weather: WeatherCondition.rain,
        );
        if (result.food.name == '김치찌개') soupCount++;
      }

      // 비 오는 날 찌개 가중치(2.0)가 적용되므로, 찌개 선택 비율이 50% 이상이어야 함
      expect(soupCount, greaterThan(trials * 0.5));
    });

    test('날씨 기반 추천 사유를 반환한다', () {
      final rainFoods = [const FoodRecommendation(name: '파전', imageUrl: '')];

      final result = RecommendationService.pickSmartFood(
        rainFoods,
        [],
        defaultPreferences,
        weather: WeatherCondition.rain,
      );

      expect(result.reason, contains('비'));
    });
  });
}

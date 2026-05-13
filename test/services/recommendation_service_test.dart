import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/data/models/food_recommendation.dart';
import 'package:review_ai/services/recommendation_service.dart';
import 'package:review_ai/services/user_preference_service.dart';

void main() {
  test(
    'pickSmartFood excludes recent and disliked foods deterministically',
    () {
      final foods = [
        const FoodRecommendation(name: '김치찌개'),
        const FoodRecommendation(name: '초밥'),
        const FoodRecommendation(name: '라멘'),
      ];

      final analysis = UserPreferenceAnalysis(
        preferredFoods: const ['라멘'],
        dislikedFoods: const ['김치찌개'],
        preferredCategories: const [],
        categoryScores: const {},
      );

      final result = RecommendationService.pickSmartFood(foods, [
        '초밥',
        '김치찌개',
        '초밥',
      ], analysis);

      expect(result.food.name, '라멘');
      expect(result.reason, isNotEmpty);
    },
  );
}

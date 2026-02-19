import '../entities/food_recommendation.dart';

abstract class RecommendationRepository {
  Future<List<FoodRecommendation>> getRecommendations({
    required String category,
    required List<String> recentFoods,
  });
}

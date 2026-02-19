import '../entities/food_recommendation.dart';
import '../repositories/recommendation_repository.dart';

class GetRecommendationsUseCase {
  final RecommendationRepository repository;

  GetRecommendationsUseCase(this.repository);

  Future<List<FoodRecommendation>> call({
    required String category,
    required List<String> recentFoods,
  }) {
    return repository.getRecommendations(
      category: category,
      recentFoods: recentFoods,
    );
  }
}

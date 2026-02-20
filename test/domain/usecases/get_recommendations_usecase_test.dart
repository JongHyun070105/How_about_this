import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:review_ai/domain/entities/food_recommendation.dart';
import 'package:review_ai/domain/repositories/recommendation_repository.dart';
import 'package:review_ai/domain/usecases/get_recommendations_usecase.dart';

@GenerateNiceMocks([MockSpec<RecommendationRepository>()])
import 'get_recommendations_usecase_test.mocks.dart';

void main() {
  late GetRecommendationsUseCase useCase;
  late MockRecommendationRepository mockRepository;

  setUp(() {
    mockRepository = MockRecommendationRepository();
    useCase = GetRecommendationsUseCase(mockRepository);
  });

  test('GetRecommendationsUseCase should call repository', () async {
    const category = '한식';
    final recentFoods = ['비빔밥'];
    final recommendations = [
      const FoodRecommendation(name: '김치찌개', imageUrl: 'url1'),
    ];

    when(
      mockRepository.getRecommendations(
        category: category,
        recentFoods: recentFoods,
      ),
    ).thenAnswer((_) async => recommendations);

    final result = await useCase(category: category, recentFoods: recentFoods);

    expect(result, recommendations);
    verify(
      mockRepository.getRecommendations(
        category: category,
        recentFoods: recentFoods,
      ),
    ).called(1);
  });
}

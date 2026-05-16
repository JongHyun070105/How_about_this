import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:review_ai/domain/repositories/review_repository.dart';
import 'package:review_ai/domain/usecases/generate_review_usecase.dart';

import 'generate_review_usecase_test.mocks.dart';

@GenerateMocks([ReviewRepository])
void main() {
  late GenerateReviewUseCase usecase;
  late MockReviewRepository mockRepository;

  setUp(() {
    mockRepository = MockReviewRepository();
    usecase = GenerateReviewUseCase(mockRepository);
  });

  const tFoodName = 'pizza';
  const tDeliveryRating = 4.5;
  const tTasteRating = 5.0;
  const tPortionRating = 4.0;
  const tPriceRating = 3.5;
  const tReviewStyle = '재미있게';
  final tFoodImage = File('test.jpg');
  final tGeneratedReviews = ['review 1', 'review 2', 'review 3'];

  test('should format request and forward to repository', () async {
    // arrange
    when(
      mockRepository.generateReviews(
        foodName: anyNamed('foodName'),
        deliveryRating: anyNamed('deliveryRating'),
        tasteRating: anyNamed('tasteRating'),
        portionRating: anyNamed('portionRating'),
        priceRating: anyNamed('priceRating'),
        reviewStyle: anyNamed('reviewStyle'),
        foodImage: anyNamed('foodImage'),
      ),
    ).thenAnswer((_) async => tGeneratedReviews);

    // act
    final result = await usecase(
      foodName: tFoodName,
      deliveryRating: tDeliveryRating,
      tasteRating: tTasteRating,
      portionRating: tPortionRating,
      priceRating: tPriceRating,
      reviewStyle: tReviewStyle,
      foodImage: tFoodImage,
    );

    // assert
    expect(result, tGeneratedReviews);
    verify(
      mockRepository.generateReviews(
        foodName: tFoodName,
        deliveryRating: tDeliveryRating,
        tasteRating: tTasteRating,
        portionRating: tPortionRating,
        priceRating: tPriceRating,
        reviewStyle: tReviewStyle,
        foodImage: tFoodImage,
      ),
    );
    verifyNoMoreInteractions(mockRepository);
  });
}

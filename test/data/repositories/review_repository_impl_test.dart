import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:review_ai/data/datasources/gemini_remote_data_source.dart';
import 'package:review_ai/data/repositories/review_repository_impl.dart';

import 'review_repository_impl_test.mocks.dart';

@GenerateMocks([GeminiRemoteDataSource])
void main() {
  late ReviewRepositoryImpl repository;
  late MockGeminiRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockGeminiRemoteDataSource();
    repository = ReviewRepositoryImpl(mockRemoteDataSource);
  });

  group('generateReviews', () {
    final tFoodName = 'pizza';
    final tDeliveryRating = 4.5;
    final tTasteRating = 5.0;
    final tPortionRating = 4.0;
    final tPriceRating = 3.5;
    final tReviewStyle = '재미있게';
    final tFoodImage = File('test.jpg');
    final tGeneratedReviews = ['review 1', 'review 2', 'review 3'];

    test(
      'should return list of strings when remote data source is successful',
      () async {
        // arrange
        when(
          mockRemoteDataSource.generateReviews(
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
        final result = await repository.generateReviews(
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
          mockRemoteDataSource.generateReviews(
            foodName: tFoodName,
            deliveryRating: tDeliveryRating,
            tasteRating: tTasteRating,
            portionRating: tPortionRating,
            priceRating: tPriceRating,
            reviewStyle: tReviewStyle,
            foodImage: tFoodImage,
          ),
        );
        verifyNoMoreInteractions(mockRemoteDataSource);
      },
    );
  });

  group('validateImage', () {
    final tFile = File('test.jpg');

    test('should return true when remote data source returns true', () async {
      // arrange
      when(
        mockRemoteDataSource.validateImage(any),
      ).thenAnswer((_) async => true);

      // act
      final result = await repository.validateImage(tFile);

      // assert
      expect(result, true);
      verify(mockRemoteDataSource.validateImage(tFile));
      verifyNoMoreInteractions(mockRemoteDataSource);
    });

    test('should return false when remote data source returns false', () async {
      // arrange
      when(
        mockRemoteDataSource.validateImage(any),
      ).thenAnswer((_) async => false);

      // act
      final result = await repository.validateImage(tFile);

      // assert
      expect(result, false);
      verify(mockRemoteDataSource.validateImage(tFile));
      verifyNoMoreInteractions(mockRemoteDataSource);
    });
  });
}

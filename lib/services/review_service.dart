import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/main.dart';
import 'package:review_ai/providers/review_provider.dart';
import 'package:review_ai/services/gemini_service.dart';

// Provider for the new ReviewService
final reviewServiceProvider = Provider((ref) => ReviewService(ref));

class ReviewService {
  final Ref _ref;

  ReviewService(this._ref);

  /// Generates reviews by calling the Gemini service with the current state from providers.
  Future<List<String>> generateReviewsFromState() async {
    final geminiService = _ref.read(geminiServiceProvider);
    final reviewState = _ref.read(reviewProvider);

    final reviews = await geminiService.generateReviews(
      foodName: reviewState.foodName,
      deliveryRating: reviewState.deliveryRating,
      tasteRating: reviewState.tasteRating,
      portionRating: reviewState.portionRating,
      priceRating: reviewState.priceRating,
      reviewStyle: reviewState.selectedReviewStyle,
      foodImage: reviewState.image,
    );

    return reviews;
  }

  /// Handles post-generation tasks like incrementing usage counts.
  Future<void> handleSuccessfulGeneration() async {
    final usageTrackingService = _ref.read(usageTrackingServiceProvider);
    await usageTrackingService.incrementReviewCount();
  }
}

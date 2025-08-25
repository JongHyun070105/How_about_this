import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/main.dart';
import 'package:review_ai/providers/review_provider.dart';

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

    // Get the current review state
    final reviewState = _ref.read(reviewProvider);

    // Create a ReviewHistoryEntry
    final newEntry = ReviewHistoryEntry(
      foodName: reviewState.foodName,
      restaurantName: reviewState.restaurantName,
      imagePath: reviewState.image?.path,
      deliveryRating: reviewState.deliveryRating,
      tasteRating: reviewState.tasteRating,
      portionRating: reviewState.portionRating,
      priceRating: reviewState.priceRating,
      reviewStyle: reviewState.selectedReviewStyle,
      emphasis: reviewState.emphasis,
      category: reviewState.category,
      generatedReviews: reviewState.generatedReviews,
    );

    // Add to history
    await _ref.read(reviewHistoryProvider.notifier).addReview(newEntry);

    // Reset the review state after successful generation and saving
    _ref.read(reviewProvider.notifier).reset();
  }
}
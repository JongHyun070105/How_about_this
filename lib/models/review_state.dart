import 'dart:io';

class ReviewState {
  final File? image;
  final String foodName;
  final String restaurantName;
  final String emphasis;
  final double deliveryRating;
  final double tasteRating;
  final double portionRating;
  final double priceRating;
  final String selectedReviewStyle;
  final bool isLoading;
  final List<String> generatedReviews;

  ReviewState({
    this.image,
    this.foodName = '',
    this.restaurantName = '',
    this.emphasis = '',
    this.deliveryRating = 0.0,
    this.tasteRating = 0.0,
    this.portionRating = 0.0,
    this.priceRating = 0.0,
    this.selectedReviewStyle = '재미있게',
    this.isLoading = false,
    this.generatedReviews = const [],
  });

  ReviewState copyWith({
    File? image,
    String? foodName,
    String? restaurantName,
    String? emphasis,
    double? deliveryRating,
    double? tasteRating,
    double? portionRating,
    double? priceRating,
    String? selectedReviewStyle,
    bool? isLoading,
    List<String>? generatedReviews,
  }) {
    return ReviewState(
      image: image ?? this.image,
      foodName: foodName ?? this.foodName,
      restaurantName: restaurantName ?? this.restaurantName,
      emphasis: emphasis ?? this.emphasis,
      deliveryRating: deliveryRating ?? this.deliveryRating,
      tasteRating: tasteRating ?? this.tasteRating,
      portionRating: portionRating ?? this.portionRating,
      priceRating: priceRating ?? this.priceRating,
      selectedReviewStyle: selectedReviewStyle ?? this.selectedReviewStyle,
      isLoading: isLoading ?? this.isLoading,
      generatedReviews: generatedReviews ?? this.generatedReviews,
    );
  }
}

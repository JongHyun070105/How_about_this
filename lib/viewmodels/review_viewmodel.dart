import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/main.dart';
import 'package:review_ai/models/food_recommendation.dart';
import 'package:review_ai/providers/review_provider.dart';
import 'package:review_ai/services/ad_service.dart';
import 'package:review_ai/services/review_service.dart';
import 'package:review_ai/widgets/common/app_dialogs.dart';
import 'package:review_ai/widgets/dialogs/review_dialogs.dart';

class ReviewViewModel extends StateNotifier<bool> {
  final Ref _ref;

  ReviewViewModel(this._ref) : super(false);

  Future<void> generateReviews(BuildContext context) async {
    if (state) return;
    state = true;

    if (!_validateInputs(context)) {
      state = false;
      return;
    }

    final usageTrackingService = _ref.read(usageTrackingServiceProvider);
    if (await usageTrackingService.hasReachedReviewLimit()) {
      showAppDialog(context, title: '알림', message: '리뷰 생성은 하루 5회까지만 가능합니다.');
      state = false;
      return;
    }

    _ref.read(reviewProvider.notifier).setLoading(true);

    try {
      final imageFile = _ref.read(reviewProvider).image;
      if (imageFile != null) {
        // await _ref.read(geminiServiceProvider).validateImage(imageFile);
      }

      await _handleAdFlow(context);
    } catch (e) {
      _handleGenerationError(context, e);
    } finally {
      if (context.mounted) {
        _ref.read(reviewProvider.notifier).setLoading(false);
      }
      state = false;
    }
  }

  Future<void> _handleAdFlow(BuildContext context) async {
    final adService = _ref.read(adServiceProvider.notifier);

    _ref.read(reviewProvider.notifier).setLoading(false);

    final adShown = await adService.showAdWithRetry(
      onUserEarnedReward: () => _actualGenerateReviews(context),
      onAdFailedToLoad: (message) {
        if (context.mounted) {
          showAppDialog(context, title: '알림', message: message);
        }
      },
    );

    if (!adShown) {
      showAppDialog(context, title: '알림', message: '광고 로드에 실패하여 리뷰를 생성합니다.');
      await _actualGenerateReviews(context);
    }
  }

  Future<void> _actualGenerateReviews(BuildContext context) async {
    _ref.read(reviewProvider.notifier).setLoading(true);
    try {
      final reviewService = _ref.read(reviewServiceProvider);
      final reviews = await reviewService.generateReviewsFromState();

      _ref.read(reviewProvider.notifier).setGeneratedReviews(reviews);

      if (_isSuccessfulGeneration(reviews)) {
        await reviewService.handleSuccessfulGeneration();
        // Navigation should be handled in the UI
      } else {
        showAppDialog(context, title: '알림', message: '리뷰 생성에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      _handleGenerationError(context, e);
    } finally {
      if (context.mounted) {
        _ref.read(reviewProvider.notifier).setLoading(false);
      }
    }
  }

  bool _validateInputs(BuildContext context) {
    final reviewState = _ref.read(reviewProvider);

    if (reviewState.foodName.isEmpty ||
        reviewState.deliveryRating == 0 ||
        reviewState.tasteRating == 0 ||
        reviewState.portionRating == 0 ||
        reviewState.priceRating == 0) {
      showValidationDialog(context, MediaQuery.of(context).size);
      return false;
    }
    return true;
  }

  bool _isSuccessfulGeneration(List<String> reviews) {
    return reviews.isNotEmpty && !reviews.first.contains('오류');
  }

  void _handleGenerationError(BuildContext context, dynamic error) {
    final errorString = error.toString();
    final errorMessage = _getErrorMessage(errorString);

    if (errorString.contains('부적절한 이미지') ||
        errorString.contains('이미지가 음식 리뷰에 적합하지 않습니다')) {
      showImageErrorDialog(
        context,
        errorMessage,
        MediaQuery.of(context).size,
      );
    } else {
      showAppDialog(context, title: '오류', message: errorMessage);
    }
  }

  String _getErrorMessage(String errorString) {
    if (errorString.contains('부적절한 이미지')) {
      return '업로드하신 이미지가 음식 사진이 아닙니다. 음식 사진을 업로드해주세요.';
    } else if (errorString.contains('이미지가 음식 리뷰에 적합하지 않습니다')) {
      return '음식을 명확히 식별할 수 있는 사진을 업로드해주세요.';
    } else {
      return '오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
  }
}

final reviewViewModelProvider = StateNotifierProvider<ReviewViewModel, bool>((ref) {
  return ReviewViewModel(ref);
});
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/main.dart';
import 'package:review_ai/models/food_category.dart';
import 'package:review_ai/models/food_recommendation.dart';
import 'package:review_ai/providers/food_providers.dart';
import 'package:review_ai/services/recommendation_service.dart';
import 'package:review_ai/widgets/common/app_dialogs.dart';

class TodayRecommendationViewModel extends StateNotifier<bool> {
  final Ref _ref;

  TodayRecommendationViewModel(this._ref) : super(false);

  Future<void> handleCategoryTap(
    BuildContext context,
    FoodCategory category,
    Function(
      BuildContext, {
      required String category,
      required List<FoodRecommendation> foods,
      required Color color,
    }) showDialogFn,
  ) async {
    if (state) return;

    state = true;

    try {
      final usageTrackingService = _ref.read(usageTrackingServiceProvider);
      if (await usageTrackingService.hasReachedTotalRecommendationLimit()) {
        if (context.mounted) {
          _showErrorDialog(context, '음식 추천은 하루 20회까지만 이용 가능합니다.');
        }
        return;
      }

      _updateSelectedCategory(category);
      final foods = await _getFoodRecommendations(category);

      if (foods.isNotEmpty) {
        await _incrementUsageCount();
        if (context.mounted) {
          showDialogFn(
            context,
            category: category.name,
            foods: foods,
            color: category.color,
          );
        }
      } else {
        if (context.mounted) {
          _showErrorDialog(context, '추천을 불러오지 못했습니다.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, '오류가 발생했습니다: $e');
      }
    } finally {
      state = false;
    }
  }

  void _updateSelectedCategory(FoodCategory category) {
    _ref.read(selectedCategoryProvider.notifier).state = category.name;
    _ref.read(selectedFoodProvider.notifier).state = null;
  }

  Future<List<FoodRecommendation>> _getFoodRecommendations(
    FoodCategory category,
  ) async {
    return await RecommendationService.getFoodRecommendations(
      category: category.name,
    );
  }

  Future<void> _incrementUsageCount() async {
    final usageTrackingService = _ref.read(usageTrackingServiceProvider);
    await usageTrackingService.incrementTotalRecommendationCount();
  }

  void _showErrorDialog(BuildContext context, String message) {
    showAppDialog(context, title: '알림', message: message);
  }
}

final todayRecommendationViewModelProvider =
    StateNotifierProvider<TodayRecommendationViewModel, bool>((ref) {
  return TodayRecommendationViewModel(ref);
});
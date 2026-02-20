import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/presentation/providers/app_providers.dart';
import 'package:review_ai/core/exceptions.dart';
import 'package:review_ai/data/models/food_category.dart';
import 'package:review_ai/data/models/food_recommendation.dart';
import 'package:review_ai/presentation/providers/food_providers.dart';
import 'package:review_ai/presentation/widgets/common/app_dialogs.dart';
import 'package:review_ai/services/user_preference_service.dart';
import 'package:review_ai/presentation/providers/dependency_injection.dart';
import 'package:review_ai/core/utils/logger_service.dart';

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
    })
    showDialogFn,
  ) async {
    if (state) return;

    state = true;

    try {
      final usageTrackingService = _ref.read(usageTrackingServiceProvider);
      if (await usageTrackingService.hasReachedTotalRecommendationLimit()) {
        if (context.mounted) {
          _showInfoDialog(context, '음식 추천은 하루 40회까지만 이용 가능합니다.');
        }
        return;
      }

      _updateSelectedCategory(category);
      final foods = await _getFoodRecommendations(category);

      if (foods.isNotEmpty) {
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
          _showInfoDialog(context, '추천을 불러오지 못했습니다.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _handleError(context, e);
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
    // 최근 7일간 먹은 음식 가져오기 (히스토리에서 필터링)
    final history = await UserPreferenceService.getFoodSelectionHistory();
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentFoods = history
        .where((s) => s.selectedAt.isAfter(sevenDaysAgo))
        .map((s) => s.foodName)
        .toList();

    // UseCase 활용 (캐싱은 Repository 구현체 내부에서 담당)
    final getRecommendationsUseCase = _ref.read(
      getRecommendationsUseCaseProvider,
    );
    final domainFoods = await getRecommendationsUseCase(
      category: category.name,
      recentFoods: recentFoods,
    );

    // Entity를 Presentation용 Model로 변환
    return domainFoods
        .map((f) => FoodRecommendation(name: f.name, imageUrl: f.imageUrl))
        .toList();
  }

  void _showInfoDialog(BuildContext context, String message) {
    showAppDialog(context, title: '알림', message: message);
  }

  void _handleError(BuildContext context, dynamic error) {
    if (!context.mounted) return;

    final errorString = error.toString().toLowerCase();
    LoggerService.e("음식 추천 오류 발생", error);

    String userMessage;
    if (error is NetworkException ||
        errorString.contains('socketexception') ||
        errorString.contains('timeoutexception') ||
        errorString.contains('handshakeexception')) {
      userMessage = '네트워크 연결이 불안정합니다. 인터넷 상태를 확인 후 다시 시도해주세요.';
    } else {
      userMessage = '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }

    showAppDialog(context, title: '오류', message: userMessage, isError: true);
  }
}

final todayRecommendationViewModelProvider =
    StateNotifierProvider<TodayRecommendationViewModel, bool>((ref) {
      return TodayRecommendationViewModel(ref);
    });

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/utils/responsive.dart';
import 'package:review_ai/utils/network_utils.dart';
import 'package:review_ai/data/models/food_category.dart';
import 'package:review_ai/data/models/food_recommendation.dart';
import 'package:review_ai/presentation/providers/app_providers.dart';
import 'package:review_ai/presentation/providers/food_providers.dart';
import 'package:review_ai/presentation/viewmodels/today_recommendation_viewmodel.dart';
import 'package:review_ai/presentation/widgets/category_card.dart';
import 'package:review_ai/presentation/widgets/common/app_dialogs.dart';
import 'package:review_ai/presentation/widgets/common/skeleton_loader.dart';
import 'package:review_ai/services/weather_service.dart';
import 'package:review_ai/presentation/widgets/common/banner_ad_widget.dart';
import 'package:review_ai/config/security_config.dart';

/// 오늘의 추천 화면 - Body (카테고리 그리드 + 배너 광고)
class TodayRecommendationBody extends ConsumerWidget {
  final String weatherMessage;
  final WeatherCondition? currentWeather;
  final void Function(
    BuildContext context, {
    required String category,
    required List<FoodRecommendation> foods,
    required Color color,
  })
  onShowRecommendationDialog;
  final void Function() onStartLoadingRotation;
  final void Function() onStopLoadingRotation;

  const TodayRecommendationBody({
    super.key,
    required this.weatherMessage,
    required this.currentWeather,
    required this.onShowRecommendationDialog,
    required this.onStartLoadingRotation,
    required this.onStopLoadingRotation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = Responsive(context);
    final foodCategories = ref.watch(foodCategoriesProvider);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: responsive.verticalSpacing()),
                  _buildHeader(context, responsive, textTheme),
                  SizedBox(height: responsive.verticalSpacing()),
                  _buildCategoryGrid(context, ref, responsive, foodCategories),
                ],
              ),
            ),
          ),
        ),
        SafeArea(top: false, child: BannerAdWidget(adUnitId: SecurityConfig.bannerAdUnitId)),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Responsive responsive,
    TextTheme textTheme,
  ) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(
        vertical: responsive.verticalSpacing() * 0.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (weatherMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                weatherMessage,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SCDream',
                ),
              ),
            ),
          Semantics(
            header: true,
            child: Text(
              '카테고리를 선택해주세요',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: responsive.titleFontSize(),
                fontFamily: 'SCDream',
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    WidgetRef ref,
    Responsive responsive,
    List<FoodCategory> foodCategories,
  ) {
    if (foodCategories.isEmpty) {
      return Expanded(
        child: SkeletonGrid(
          itemCount: 6,
          crossAxisCount: responsive.crossAxisCount(),
          childAspectRatio: responsive.childAspectRatio(),
          padding: EdgeInsets.only(
            top: responsive.verticalSpacing(),
            bottom: responsive.verticalSpacing(),
          ),
        ),
      );
    }

    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.only(
          top: responsive.verticalSpacing(),
          bottom: responsive.verticalSpacing(),
        ),
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: responsive.crossAxisCount(),
          crossAxisSpacing: responsive.horizontalPadding() * 0.5,
          mainAxisSpacing: responsive.verticalSpacing(),
          childAspectRatio: responsive.childAspectRatio(),
        ),
        itemCount: foodCategories.length,
        itemBuilder: (context, index) =>
            _buildCategoryItem(context, ref, foodCategories[index], index),
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    WidgetRef ref,
    FoodCategory category,
    int index,
  ) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      child: CategoryCard(
        category: category,
        onTap: () => _handleCategoryTap(context, ref, category),
      ),
    );
  }

  Future<void> _handleCategoryTap(
    BuildContext context,
    WidgetRef ref,
    FoodCategory category,
  ) async {
    final isLoading = ref.read(todayRecommendationViewModelProvider);
    if (isLoading) return;

    final connected = await NetworkUtils.checkInternetConnectivity();
    if (!connected) {
      if (context.mounted) {
        showAppDialog(
          context,
          title: '네트워크 오류',
          message: '인터넷 연결을 확인해주세요.',
          isError: true,
        );
      }
      return;
    }

    final usageTrackingService = ref.read(usageTrackingServiceProvider);
    final hasReachedLimit = await usageTrackingService
        .hasReachedTotalRecommendationLimit();

    if (hasReachedLimit && context.mounted) {
      showAppDialog(
        context,
        title: '일일 추천 한도 초과',
        message: '오늘의 음식 추천 한도에 도달했습니다. 내일 다시 이용해주세요!',
      );
      return;
    }

    await usageTrackingService.incrementTotalRecommendationCount();

    if (context.mounted) {
      onStartLoadingRotation();
      ref
          .read(todayRecommendationViewModelProvider.notifier)
          .handleCategoryTap(context, category, onShowRecommendationDialog)
          .whenComplete(onStopLoadingRotation);
    }
  }

  // _buildBottomBannerAd is replaced by BannerAdWidget
}

import 'package:reviewai_flutter/config/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reviewai_flutter/providers/food_providers.dart';
import 'package:reviewai_flutter/screens/review_screen.dart';
import 'package:reviewai_flutter/services/user_preference_service.dart';
import 'package:reviewai_flutter/services/recommendation_service.dart';
import 'package:reviewai_flutter/widgets/category_card.dart';
import 'package:reviewai_flutter/widgets/dialogs/food_recommendation_dialog.dart';
import 'package:reviewai_flutter/widgets/dialogs/user_stats_dialog.dart';

// 로딩 상태를 관리하는 Provider
final isCategoryLoadingProvider = StateProvider<bool>((ref) => false);

class TodayRecommendationScreen extends ConsumerStatefulWidget {
  const TodayRecommendationScreen({super.key});

  @override
  ConsumerState<TodayRecommendationScreen> createState() =>
      _TodayRecommendationScreenState();
}

class _TodayRecommendationScreenState
    extends ConsumerState<TodayRecommendationScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final foodCategories = ref.watch(foodCategoriesProvider);
    final isCategoryLoading = ref.watch(isCategoryLoadingProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textTheme = Theme.of(context).textTheme;

    Future<FoodRecommendation> pickSmartFood(
      List<FoodRecommendation> foods,
      List<String> recentFoods,
    ) async {
      final preferences = await UserPreferenceService.analyzeUserPreferences();
      return RecommendationService.pickSmartFood(
        foods,
        recentFoods,
        preferences,
      );
    }

    void showRecommendationDialog(
      BuildContext context, {
      required String category,
      required List<FoodRecommendation> foods,
      required Color color,
    }) {
      final recentFoods = <String>[];

      void openDialog() async {
        final recommended = await pickSmartFood(foods, recentFoods);
        ref.read(selectedFoodProvider.notifier).state = recommended;

        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (_) => SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: ModalRoute.of(context)!.animation!,
                    curve: Curves.easeOutBack,
                  ),
                ),
            child: FoodRecommendationDialog(
              category: category,
              recommended: recommended,
              foods: foods,
              color: color,
            ),
          ),
        ).then((result) {
          if (!context.mounted) return;
          if (result == true) {
            openDialog(); // Re-call openDialog if "싫어요" was pressed
          }
        });
      }

      openDialog();
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            titleSpacing: screenWidth * 0.06,
            centerTitle: false,
            title: Text(
              '오늘 뭐 먹지?',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.05,
                fontFamily: 'Do Hyeon',
              ),
            ),
            actions: [
              // 통계 보기 버튼 추가
              IconButton(
                icon: Icon(Icons.analytics, size: screenWidth * 0.06),
                onPressed: () => _showUserStatsDialog(context),
                tooltip: '내 식습관 통계',
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              IconButton(
                icon: Icon(Icons.rate_review, size: screenWidth * 0.06),
                onPressed: () =>
                    _navigateToReviewScreen(context, _createDefaultFood()),
                tooltip: '리뷰 작성',
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: screenHeight * 0.02),
                Text(
                  '카테고리를 선택해주세요',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Do Hyeon',
                    fontSize: screenWidth * 0.05,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),

                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: screenWidth * 0.04,
                      mainAxisSpacing: screenHeight * 0.02,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: foodCategories.length,
                    itemBuilder: (context, index) {
                      final category = foodCategories[index];
                      return CategoryCard(
                        category: category,
                        onTap: () => _handleCategoryTap(
                          context,
                          ref,
                          category,
                          showRecommendationDialog,
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
        if (isCategoryLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  FoodRecommendation _createDefaultFood() {
    return FoodRecommendation(
      name: AppConstants.defaultFoodName,
      imageUrl: AppConstants.defaultFoodImage,
    );
  }

  void _navigateToReviewScreen(BuildContext context, FoodRecommendation food) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReviewScreen(food: food),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _handleCategoryTap(
    BuildContext context,
    WidgetRef ref,
    FoodCategory category,
    Function(
      BuildContext, {
      required String category,
      required List<FoodRecommendation> foods,
      required Color color,
    })
    showDialogFn,
  ) async {
    if (ref.read(isCategoryLoadingProvider)) return;

    ref.read(isCategoryLoadingProvider.notifier).state = true;
    try {
      ref.read(selectedCategoryProvider.notifier).state = category.name;
      ref.read(selectedFoodProvider.notifier).state = null;

      final foods = await ref.read(
        recommendationProvider(category.name).future,
      );

      if (foods.isNotEmpty) {
        if (!context.mounted) return;
        showDialogFn(
          context,
          category: category.name,
          foods: foods,
          color: category.color,
        );
      } else {
        if (!context.mounted) return;
      _showErrorSnackBar(context, '추천을 불러오지 못했습니다.');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, '오류가 발생했습니다: $e');
    } finally {
      ref.read(isCategoryLoadingProvider.notifier).state = false;
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 사용자 통계 다이얼로그 (PageView로 리팩토링)
  void _showUserStatsDialog(BuildContext context) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    try {
      final stats = await RecommendationService.getUserStats();
      

      // Get the food categories from provider to get category colors
      final foodCategories = ref.read(foodCategoriesProvider);
      // Map category name to color
      final Map<String, Color> categoryColorMap = {
        for (final cat in foodCategories) cat.name: cat.color,
      };

      // Convert stats['categoryStats'] (Map<String, int>) to List<Map<String, dynamic>>
      List<Map<String, dynamic>> categoryList = [];
      int totalSelections = stats['totalSelections'] ?? 0;
      if (stats['categoryStats'] != null &&
          stats['categoryStats'] is Map<String, dynamic>) {
        final Map<String, dynamic> catStats = Map<String, dynamic>.from(
          stats['categoryStats'],
        );
        // Filter out "상관없음", include all with count > 0
        final filteredCats = catStats.entries
            .where((e) => e.key != '상관없음' && (e.value ?? 0) > 0)
            .toList();
        int denominator = totalSelections > 0
            ? totalSelections
            : filteredCats.fold<int>(
                0,
                (sum, e) => sum + ((e.value ?? 0) as num).toInt(),
              );
        categoryList = filteredCats.map<Map<String, dynamic>>((e) {
          int count = (e.value ?? 0) as int;
          double percent = denominator > 0 ? (count / denominator * 100) : 0.0;
          return {'name': e.key, 'count': count, 'percent': percent};
        }).toList();
      }

      // Calculate total count of top 5 foods
      final List<dynamic> topFoodsList = (stats['topFoods'] as List)
          .take(5)
          .toList();
      int totalTop5Count = 0;
      for (final food in topFoodsList) {
        if (food['count'] != null) {
          totalTop5Count += (food['count'] as num).toInt();
        }
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          PageController pageController = PageController();
          return AnimatedStatsDialog(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            stats: stats,
            topFoodsList: topFoodsList,
            totalTop5Count: totalTop5Count,
            categoryList: categoryList,
            categoryColorMap: categoryColorMap,
            pageController: pageController,
            buildStatItem: _buildStatItem,
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, '통계를 불러오는데 실패했습니다.');
    }
  }

  // 통계 아이템 빌더 헬퍼 메서드
  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'Do Hyeon'),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Do Hyeon',
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}



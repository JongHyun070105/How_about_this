import 'package:eat_this_app/config/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eat_this_app/providers/food_providers.dart';
import 'package:eat_this_app/screens/review_screen.dart';
import 'package:eat_this_app/services/user_preference_service.dart';
import 'package:eat_this_app/services/recommendation_service.dart';
import 'package:eat_this_app/widgets/category_card.dart';
import 'package:eat_this_app/widgets/dialogs/food_recommendation_dialog.dart';
import 'package:eat_this_app/widgets/dialogs/user_stats_dialog.dart';

// Loading state provider
final isCategoryLoadingProvider = StateProvider<bool>((ref) => false);

class TodayRecommendationScreen extends ConsumerStatefulWidget {
  const TodayRecommendationScreen({super.key});

  @override
  ConsumerState<TodayRecommendationScreen> createState() =>
      _TodayRecommendationScreenState();
}

class _TodayRecommendationScreenState
    extends ConsumerState<TodayRecommendationScreen> {
  // Responsive variables
  late double screenWidth;
  late double screenHeight;
  late bool isTablet;
  late bool isSmallScreen;
  late double appBarFontSize;
  late double titleFontSize;
  late double horizontalPadding;
  late double verticalSpacing;
  late double iconSize;
  late int crossAxisCount;
  late double childAspectRatio;

  void _calculateResponsiveSizes() {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    isTablet = screenWidth >= 768;
    isSmallScreen = screenWidth < 600;

    // Dynamic font sizes
    appBarFontSize = (screenWidth * (isTablet ? 0.032 : 0.05)).clamp(
      16.0,
      28.0,
    );
    titleFontSize = (screenWidth * (isTablet ? 0.032 : 0.05)).clamp(16.0, 26.0);

    // Dynamic spacing and padding
    horizontalPadding = (screenWidth * (isTablet ? 0.08 : 0.06)).clamp(
      20.0,
      60.0,
    );
    verticalSpacing = (screenHeight * (isTablet ? 0.025 : 0.02)).clamp(
      12.0,
      24.0,
    );

    // Icon size
    iconSize = (screenWidth * (isTablet ? 0.045 : 0.06)).clamp(20.0, 36.0);

    // Grid layout
    if (isTablet) {
      crossAxisCount = screenWidth > 1024
          ? 4
          : 3; // 4 columns for very large tablets
      childAspectRatio = 0.95;
    } else if (isSmallScreen) {
      crossAxisCount = 2;
      childAspectRatio = 0.88;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 0.92;
    }
  }

  @override
  Widget build(BuildContext context) {
    _calculateResponsiveSizes();
    final foodCategories = ref.watch(foodCategoriesProvider);
    final isCategoryLoading = ref.watch(isCategoryLoadingProvider);
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(textTheme),
          body: _buildBody(foodCategories, textTheme),
        ),
        if (isCategoryLoading) _buildLoadingOverlay(),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(TextTheme textTheme) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: horizontalPadding,
      centerTitle: false,
      title: Container(
        alignment: Alignment.centerLeft,
        child: Text(
          '오늘 뭐 먹지?',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: appBarFontSize,
            fontFamily: 'Do Hyeon',
            color: Colors.grey[800],
          ),
        ),
      ),
      actions: [
        // Statistics button with enhanced design
        Container(
          margin: EdgeInsets.only(right: (screenWidth * 0.02).clamp(8.0, 16.0)),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all((screenWidth * 0.02).clamp(6.0, 10.0)),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isTablet ? 12.0 : 10.0),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
              child: Icon(
                Icons.analytics,
                size: iconSize * 0.9,
                color: Colors.blue.shade600,
              ),
            ),
            onPressed: () => _showUserStatsDialog(context),
            tooltip: '내 식습관 통계',
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ),

        // Review button with enhanced design
        Container(
          margin: EdgeInsets.only(right: horizontalPadding * 0.7),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all((screenWidth * 0.02).clamp(6.0, 10.0)),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isTablet ? 12.0 : 10.0),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
              child: Icon(
                Icons.rate_review,
                size: iconSize * 0.9,
                color: Colors.green.shade600,
              ),
            ),
            onPressed: () =>
                _navigateToReviewScreen(context, _createDefaultFood()),
            tooltip: '리뷰 작성',
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(List<FoodCategory> foodCategories, TextTheme textTheme) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: verticalSpacing),

            // Title section with enhanced styling
            Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(vertical: verticalSpacing * 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '카테고리를 선택해주세요',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Do Hyeon',
                      fontSize: titleFontSize,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: verticalSpacing * 0.3),
                  Container(
                    height: 3.0,
                    width: (screenWidth * 0.20).clamp(60.0, 100.0), // Increased underline width
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: verticalSpacing),

            // Enhanced grid view with responsive design
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isTablet ? 20.0 : 16.0),
                ),
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(vertical: verticalSpacing),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: (screenWidth * (isTablet ? 0.03 : 0.04))
                        .clamp(12.0, 24.0),
                    mainAxisSpacing: (screenHeight * (isTablet ? 0.02 : 0.02))
                        .clamp(12.0, 20.0),
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: foodCategories.length,
                  itemBuilder: (context, index) {
                    final category = foodCategories[index];
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      curve: Curves.easeOutBack,
                      child: CategoryCard(
                        category: category,
                        onTap: () => _handleCategoryTap(
                          context,
                          ref,
                          category,
                          _showRecommendationDialog,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            SizedBox(height: verticalSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black38,
        child: Center(
          child: Container(
            padding: EdgeInsets.all((screenWidth * 0.08).clamp(24.0, 48.0)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isTablet ? 20.0 : 16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: isTablet ? 20.0 : 15.0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CircularProgressIndicator( // Removed
                //   strokeWidth: isTablet ? 4.0 : 3.0,
                //   color: Theme.of(context).primaryColor,
                // ),
                // SizedBox(height: verticalSpacing), // Removed
                Text(
                  '추천을 불러오는 중...',
                  style: TextStyle(
                    fontFamily: 'Do Hyeon',
                    fontSize: (screenWidth * (isTablet ? 0.025 : 0.035)).clamp(
                      12.0,
                      18.0,
                    ),
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<FoodRecommendation> _pickSmartFood(
    List<FoodRecommendation> foods,
    List<String> recentFoods,
  ) async {
    final preferences = await UserPreferenceService.analyzeUserPreferences();
    return RecommendationService.pickSmartFood(foods, recentFoods, preferences);
  }

  void _showRecommendationDialog(
    BuildContext context, {
    required String category,
    required List<FoodRecommendation> foods,
    required Color color,
  }) {
    final recentFoods = <String>[];

    void openDialog() async {
      final recommended = await _pickSmartFood(foods, recentFoods);
      ref.read(selectedFoodProvider.notifier).state = recommended;

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
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
          openDialog(); // Re-call if "싫어요" was pressed
        }
      });
    }

    openDialog();
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
        transitionDuration: Duration(milliseconds: isTablet ? 500 : 400),
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
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: iconSize * 0.8,
            ),
            SizedBox(width: (screenWidth * 0.03).clamp(8.0, 12.0)),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'Do Hyeon',
                  fontSize: (screenWidth * (isTablet ? 0.025 : 0.035)).clamp(
                    12.0,
                    18.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 12.0 : 8.0),
        ),
        margin: EdgeInsets.all(horizontalPadding),
      ),
    );
  }

  void _showUserStatsDialog(BuildContext context) async {
    try {
      final stats = await RecommendationService.getUserStats();
      final foodCategories = ref.read(foodCategoriesProvider);

      // Map category name to color
      final Map<String, Color> categoryColorMap = {
        for (final cat in foodCategories) cat.name: cat.color,
      };

      // Process category stats
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
          // 반응형 계산을 dialog builder 내부로 이동
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;

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

  // Statistics item builder helper method
  Widget _buildStatItem(String label, String value) {
    return Padding( // Changed Container to Padding for simpler styling
      padding: EdgeInsets.symmetric(
        vertical: (screenHeight * 0.008).clamp(4.0, 8.0),
        horizontal: (screenWidth * 0.02).clamp(8.0, 16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: (screenWidth * (isTablet ? 0.025 : 0.035)).clamp(
                  12.0,
                  18.0,
                ),
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          SizedBox(width: (screenWidth * 0.04).clamp(12.0, 20.0)),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: (screenWidth * (isTablet ? 0.028 : 0.038)).clamp(
                  14.0,
                  20.0,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
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

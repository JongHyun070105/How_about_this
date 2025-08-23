import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:review_ai/config/app_constants.dart';
import 'package:review_ai/main.dart';
import 'package:review_ai/models/food_category.dart';
import 'package:review_ai/models/food_recommendation.dart';
import 'package:review_ai/providers/food_providers.dart';
import 'package:review_ai/screens/review_screen.dart';
import 'package:review_ai/services/recommendation_service.dart';
import 'package:review_ai/services/user_preference_service.dart';
import 'package:review_ai/utils/responsive.dart';
import 'package:review_ai/viewmodels/today_recommendation_viewmodel.dart';
import 'package:review_ai/widgets/category_card.dart';
import 'package:review_ai/widgets/dialogs/food_recommendation_dialog.dart';
import 'package:review_ai/widgets/dialogs/user_stats_dialog.dart';
import 'package:review_ai/widgets/dialogs/review_prompt_dialog.dart';
import 'package:flutter/foundation.dart';

class TodayRecommendationScreen extends ConsumerStatefulWidget {
  const TodayRecommendationScreen({super.key});

  @override
  ConsumerState<TodayRecommendationScreen> createState() =>
      _TodayRecommendationScreenState();
}

class _TodayRecommendationScreenState
    extends ConsumerState<TodayRecommendationScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    final adUnitId = _getAdUnitId();
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.fullBanner,
      listener: _createBannerAdListener(),
    )..load();
  }

  String _getAdUnitId() {
    return defaultTargetPlatform == TargetPlatform.android
        ? "ca-app-pub-3940256099942544/6300978111"
        : "ca-app-pub-3940256099942544/2934735716";
  }

  BannerAdListener _createBannerAdListener() {
    return BannerAdListener(
      onAdLoaded: (ad) {
        setState(() {
          _bannerAd = ad as BannerAd;
          _isBannerAdLoaded = true;
        });
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('BannerAd failed to load: $error');
        ad.dispose();
        setState(() {
          _isBannerAdLoaded = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final foodCategories = ref.watch(foodCategoriesProvider);
    final isCategoryLoading = ref.watch(todayRecommendationViewModelProvider);
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context, responsive, textTheme),
          body: _buildBody(context, responsive, foodCategories, textTheme),
        ),
        if (isCategoryLoading) _buildLoadingOverlay(context, responsive),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, Responsive responsive, TextTheme textTheme) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: responsive.horizontalPadding(),
      centerTitle: false,
      title: _buildAppBarTitle(responsive, textTheme),
      actions: _buildAppBarActions(context, responsive),
    );
  }

  Widget _buildAppBarTitle(Responsive responsive, TextTheme textTheme) {
    return Container(
      alignment: Alignment.centerLeft,
      child: Text('오늘 뭐 먹지?',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: responsive.appBarFontSize(),
            fontFamily: 'Do Hyeon',
            color: Colors.grey[800],
          )),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, Responsive responsive) {
    return [_buildStatsIconButton(context, responsive), _buildReviewIconButton(context, responsive)];
  }

  Widget _buildStatsIconButton(BuildContext context, Responsive responsive) {
    return IconButton(
      icon: Icon(
        Icons.analytics,
        size: responsive.iconSize(),
        color: Colors.black,
      ),
      onPressed: () =>
          showDialog(context: context, builder: (_) => const UserStatsDialog()),
      tooltip: '내 식습관 통계',
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }

  Widget _buildReviewIconButton(BuildContext context, Responsive responsive) {
    return IconButton(
      icon: Icon(
        Icons.rate_review,
        size: responsive.iconSize(),
        color: Colors.black,
      ),
      onPressed: () => _navigateToReviewScreen(context, _createDefaultFood()),
      tooltip: '리뷰 작성',
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }

  Widget _buildBody(BuildContext context, Responsive responsive,
      List<FoodCategory> foodCategories, TextTheme textTheme) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.horizontalPadding(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: responsive.verticalSpacing()),
            _buildBodyHeader(responsive, textTheme),
            SizedBox(height: responsive.verticalSpacing()),
            _buildCategoryGrid(context, responsive, foodCategories),
            SizedBox(height: responsive.verticalSpacing()),
            _buildBottomBannerAd(responsive),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyHeader(Responsive responsive, TextTheme textTheme) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(
        vertical: responsive.verticalSpacing() * 0.5,
      ),
      child: Text('카테고리를 선택해주세요',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Do Hyeon',
            fontSize: responsive.titleFontSize(),
            color: Colors.grey[800],
          )),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, Responsive responsive,
      List<FoodCategory> foodCategories) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            responsive.isTablet ? 20.0 : 16.0,
          ),
        ),
        child: GridView.builder(
          padding: EdgeInsets.symmetric(
            vertical: responsive.verticalSpacing(),
          ),
          physics: const BouncingScrollPhysics(),
          gridDelegate: _createGridDelegate(responsive),
          itemCount: foodCategories.length,
          itemBuilder: (context, index) =>
              _buildCategoryItem(context, foodCategories[index], index),
        ),
      ),
    );
  }

  SliverGridDelegateWithFixedCrossAxisCount _createGridDelegate(
      Responsive responsive) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: responsive.crossAxisCount(),
      crossAxisSpacing: responsive.horizontalPadding() * 0.5,
      mainAxisSpacing: responsive.verticalSpacing(),
      childAspectRatio: responsive.childAspectRatio(),
    );
  }

  Widget _buildCategoryItem(BuildContext context, FoodCategory category, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutBack,
      child: CategoryCard(
        category: category,
        onTap: () => ref
            .read(todayRecommendationViewModelProvider.notifier)
            .handleCategoryTap(context, category, _showRecommendationDialog),
      ),
    );
  }

  Widget _buildBottomBannerAd(Responsive responsive) {
    if (!_isBannerAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: EdgeInsets.only(bottom: responsive.verticalSpacing() * 0.5),
      decoration: _getBannerAdDecoration(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  BoxDecoration _getBannerAdDecoration() {
    return BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(color: Colors.grey[200]!, width: 1.0),
    );
  }

  Widget _buildLoadingOverlay(BuildContext context, Responsive responsive) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(child: _buildLoadingDialog(context, responsive)),
      ),
    );
  }

  Widget _buildLoadingDialog(BuildContext context, Responsive responsive) {
    final padding = responsive.horizontalPadding() * 0.5;
    final progressSize = responsive.iconSize();

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: _getLoadingDialogDecoration(responsive),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: progressSize,
            height: progressSize,
            child: _buildProgressIndicator(responsive),
          ),
          SizedBox(height: responsive.verticalSpacing()),
          _buildLoadingText(responsive),
        ],
      ),
    );
  }

  BoxDecoration _getLoadingDialogDecoration(Responsive responsive) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        responsive.isTablet ? 20.0 : 16.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: responsive.isTablet ? 20.0 : 15.0,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(Responsive responsive) {
    return CircularProgressIndicator(
      strokeWidth: responsive.isTablet ? 3.0 : 2.5,
      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
    );
  }

  Widget _buildLoadingText(Responsive responsive) {
    return Text('추천을 불러오는 중...', style: _getLoadingTextStyle(responsive));
  }

  TextStyle _getLoadingTextStyle(Responsive responsive) {
    final fontSize = responsive.inputFontSize() * 0.8;

    return TextStyle(
      fontFamily: 'Do Hyeon',
      fontSize: fontSize,
      color: Colors.grey[700],
      decoration: TextDecoration.none,
    );
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

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (_) =>
            _buildAnimatedDialog(context, category, recommended, foods, color),
      );

      await _handleDialogResult(context, result, openDialog);
    }

    openDialog();
  }

  Widget _buildAnimatedDialog(
    BuildContext context,
    String category,
    FoodRecommendation recommended,
    List<FoodRecommendation> foods,
    Color color,
  ) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
          .animate(
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
    );
  }

  Future<void> _handleDialogResult(
    BuildContext context,
    bool? result,
    VoidCallback openDialog,
  ) async {
    if (!context.mounted) return;

    await _showReviewPromptIfNeeded(context);

    if (result == true) {
      openDialog();
    }
  }

  Future<void> _showReviewPromptIfNeeded(BuildContext context) async {
    final usageTrackingService = ref.read(usageTrackingServiceProvider);
    final currentCount = await usageTrackingService
        .getTotalRecommendationCount();

    if (_shouldShowReviewPrompt(currentCount) && context.mounted) {
      final responsive = Responsive(context);
      await showDialog(
        context: context,
        builder: (_) => ReviewPromptDialog(
          screenWidth: responsive.screenWidth,
          screenHeight: responsive.screenHeight,
        ),
      );
    }
  }

  bool _shouldShowReviewPrompt(int count) {
    return count == 1 || count == 10 || count == 20;
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
      MaterialPageRoute(builder: (_) => ReviewScreen(food: food)),
    );
  }

  Future<FoodRecommendation> _pickSmartFood(
    List<FoodRecommendation> foods,
    List<String> recentFoods,
  ) async {
    final analysis = await UserPreferenceService.analyzeUserPreferences();
    return RecommendationService.pickSmartFood(foods, recentFoods, analysis);
  }
}

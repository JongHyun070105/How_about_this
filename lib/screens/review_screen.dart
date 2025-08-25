import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/config/app_constants.dart';
import 'package:review_ai/models/food_recommendation.dart';
import 'package:review_ai/providers/review_provider.dart';
import 'package:review_ai/screens/history_screen.dart';
import 'package:review_ai/screens/review_selection_screen.dart';
import 'package:review_ai/utils/responsive.dart';
import 'package:review_ai/viewmodels/review_viewmodel.dart';
import 'package:review_ai/widgets/review/image_upload_section.dart';
import 'package:review_ai/widgets/review/rating_row.dart';
import 'package:review_ai/widgets/common/primary_action_button.dart';
import 'package:review_ai/widgets/review/review_style_section.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final FoodRecommendation food;
  final String category;

  const ReviewScreen({super.key, required this.food, required this.category});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final TextEditingController _foodNameController = TextEditingController();
  bool _hasNavigatedToSelection = false; // 중복 네비게이션 방지 플래그

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedFood = widget.food;
      final isDefaultFood = selectedFood.name == AppConstants.defaultFoodName;
      final foodNameToSet = isDefaultFood ? '' : selectedFood.name;

      _foodNameController.text = foodNameToSet;
      ref.read(reviewProvider.notifier).setFoodName(foodNameToSet);

      // 화면 진입 시 플래그 초기화
      _hasNavigatedToSelection = false;
    });
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final textTheme = Theme.of(context).textTheme;
    final reviewState = ref.watch(reviewProvider);
    final isLoading = reviewState.isLoading;

    ref.listen(reviewProvider.select((state) => state.foodName), (_, next) {
      if (_foodNameController.text != next) {
        _foodNameController.text = next;
      }
    });

    ref.listen(reviewProvider.select((state) => state.generatedReviews), (
      previous,
      next,
    ) {
      debugPrint('생성된 리뷰 상태 변경: ${previous?.length} -> ${next.length}');

      // 새로운 리뷰가 생성되고 아직 선택 화면으로 이동하지 않은 경우만 네비게이션
      if (previous?.isEmpty == true &&
          next.isNotEmpty &&
          !_hasNavigatedToSelection &&
          context.mounted) {
        debugPrint('새로운 리뷰 생성됨 - 화면 전환 준비');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && !_hasNavigatedToSelection) {
            debugPrint('실제 화면 전환 실행');
            _navigateToReviewSelection();
          }
        });
      }
    });

    return PopScope(
      canPop: !isLoading,
      onPopInvokedWithResult: (didPop, _) {
        // no reset here; reset happens in ReviewSelectionScreen after save
        if (didPop) {
          _hasNavigatedToSelection = false; // 뒤로 가기 시 플래그 리셋
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(context, responsive, textTheme),
            body: _buildBody(context, responsive, textTheme, isLoading),
          ),
          if (isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  void _navigateToRecommendationScreen() {
    _hasNavigatedToSelection = false;
    Navigator.pop(context);
  }

  void _navigateToHistoryScreen() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const HistoryScreen()),
  );

  void _navigateToReviewSelection() {
    if (!_hasNavigatedToSelection && context.mounted) {
      _hasNavigatedToSelection = true; // 여기서 플래그 설정
      debugPrint('ReviewSelectionScreen으로 네비게이션 시작');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReviewSelectionScreen()),
      ).then((_) {
        // 선택 화면에서 돌아왔을 때 플래그 리셋
        debugPrint('ReviewSelectionScreen에서 돌아옴');
        if (mounted) {
          _hasNavigatedToSelection = false;
          // 필요시 상태도 리셋
          ref.read(reviewProvider.notifier).setGeneratedReviews([]);
        }
      });
    } else {
      debugPrint('네비게이션 스킵 - 이미 이동했거나 컨텍스트가 마운트되지 않음');
    }
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    Responsive responsive,
    TextTheme textTheme,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        '리뷰 AI',
        style: textTheme.headlineMedium?.copyWith(
          fontSize: responsive.appBarFontSize(),
          fontWeight: FontWeight.bold,
          fontFamily: 'Do Hyeon',
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, size: responsive.iconSize()),
        onPressed: _navigateToRecommendationScreen,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history, size: responsive.iconSize()),
          onPressed: _navigateToHistoryScreen,
          tooltip: '히스토리',
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    Responsive responsive,
    TextTheme textTheme,
    bool isLoading,
  ) {
    final reviewState = ref.watch(reviewProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.horizontalPadding(),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: responsive.verticalSpacing() * 0.4),
              Container(
                constraints: BoxConstraints(
                  maxHeight:
                      responsive.screenHeight *
                      (responsive.isTablet ? 0.28 : 0.26),
                ),
                child: const ImageUploadSection(),
              ),
              SizedBox(height: responsive.verticalSpacing() * 0.8),
              _buildSectionLabel(responsive, '음식명'),
              SizedBox(height: responsive.verticalSpacing() * 0.3),
              _buildFoodNameInput(responsive),
              SizedBox(height: responsive.verticalSpacing() * 0.6),
              Column(
                children: [
                  RatingRow(
                    label: '배달',
                    rating: reviewState.deliveryRating,
                    onRate: (r) =>
                        ref.read(reviewProvider.notifier).setDeliveryRating(r),
                  ),
                  SizedBox(height: responsive.verticalSpacing() * 0.02),
                  RatingRow(
                    label: '맛',
                    rating: reviewState.tasteRating,
                    onRate: (r) =>
                        ref.read(reviewProvider.notifier).setTasteRating(r),
                  ),
                  SizedBox(height: responsive.verticalSpacing() * 0.02),
                  RatingRow(
                    label: '양',
                    rating: reviewState.portionRating,
                    onRate: (r) =>
                        ref.read(reviewProvider.notifier).setPortionRating(r),
                  ),
                  SizedBox(height: responsive.verticalSpacing() * 0.02),
                  RatingRow(
                    label: '가격',
                    rating: reviewState.priceRating,
                    onRate: (r) =>
                        ref.read(reviewProvider.notifier).setPriceRating(r),
                  ),
                ],
              ),
              SizedBox(height: responsive.verticalSpacing() * 0.8),
              const ReviewStyleSection(),
              SizedBox(height: responsive.verticalSpacing() * 1.5),
              PrimaryActionButton(
                text: '리뷰 생성하기',
                onPressed: () => ref
                    .read(reviewViewModelProvider.notifier)
                    .generateReviews(context),
                isLoading: isLoading,
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(Responsive responsive, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: responsive.inputFontSize() * 1.1,
          fontWeight: FontWeight.bold,
          fontFamily: 'Do Hyeon',
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildFoodNameInput(Responsive responsive) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!, width: 1.0),
      ),
      child: TextField(
        controller: _foodNameController,
        maxLength: AppConstants.maxFoodNameLength,
        onChanged: (text) =>
            ref.read(reviewProvider.notifier).setFoodName(text),
        style: TextStyle(
          fontFamily: 'Do Hyeon',
          fontSize: responsive.inputFontSize(),
          color: Colors.grey[800],
        ),
        decoration: InputDecoration(
          hintText: '음식명을 입력해주세요',
          counterText: "",
          hintStyle: TextStyle(
            fontFamily: 'Do Hyeon',
            fontSize: responsive.inputFontSize() * 0.9,
            color: Colors.grey[400],
          ),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
          filled: false,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withAlpha(128),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
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

  const ReviewScreen({super.key, required this.food});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final TextEditingController _foodNameController = TextEditingController();

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

    ref.listen(reviewViewModelProvider, (previous, next) {
      if (next) {
        // is loading
      } else {
        // is not loading
        final reviews = ref.read(reviewProvider).generatedReviews;
        if (reviews.isNotEmpty) {
          _navigateToReviewSelection();
        }
      }
    });

    return PopScope(
      canPop: !isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(reviewProvider.notifier).reset();
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

  void _navigateToRecommendationScreen() => Navigator.pop(context);

  void _navigateToHistoryScreen() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      );

  void _navigateToReviewSelection() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReviewSelectionScreen()),
      );

  PreferredSizeWidget _buildAppBar(
      BuildContext context, Responsive responsive, TextTheme textTheme) {
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

  Widget _buildBody(BuildContext context, Responsive responsive,
      TextTheme textTheme, bool isLoading) {
    final reviewState = ref.watch(reviewProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding()),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: responsive.verticalSpacing() * 0.4),
              Container(
                constraints: BoxConstraints(
                    maxHeight: responsive.screenHeight *
                        (responsive.isTablet ? 0.28 : 0.26)),
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
                      onRate: (r) => ref
                          .read(reviewProvider.notifier)
                          .setDeliveryRating(r)),
                  SizedBox(height: responsive.verticalSpacing() * 0.02),
                  RatingRow(
                      label: '맛',
                      rating: reviewState.tasteRating,
                      onRate: (r) =>
                          ref.read(reviewProvider.notifier).setTasteRating(r)),
                  SizedBox(height: responsive.verticalSpacing() * 0.02),
                  RatingRow(
                      label: '양',
                      rating: reviewState.portionRating,
                      onRate: (r) => ref
                          .read(reviewProvider.notifier)
                          .setPortionRating(r)),
                  SizedBox(height: responsive.verticalSpacing() * 0.02),
                  RatingRow(
                      label: '가격',
                      rating: reviewState.priceRating,
                      onRate: (r) =>
                          ref.read(reviewProvider.notifier).setPriceRating(r)),
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
              SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 16.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(Responsive responsive, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: TextStyle(
              fontSize: responsive.inputFontSize() * 1.1,
              fontWeight: FontWeight.bold,
              fontFamily: 'Do Hyeon',
              color: Colors.grey[800])),
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
            color: Colors.grey[800]),
        decoration: InputDecoration(
          hintText: '음식명을 입력해주세요',
          counterText: "",
          hintStyle: TextStyle(
              fontFamily: 'Do Hyeon',
              fontSize: responsive.inputFontSize() * 0.9,
              color: Colors.grey[400]),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          filled: false,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

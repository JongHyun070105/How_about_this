import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eat_this_app/providers/review_provider.dart';
import 'package:eat_this_app/providers/food_providers.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:eat_this_app/widgets/review_selection/edit_review_dialog.dart';
import 'package:eat_this_app/widgets/review_selection/review_card.dart';

class ReviewSelectionScreen extends ConsumerStatefulWidget {
  const ReviewSelectionScreen({super.key});

  @override
  ConsumerState<ReviewSelectionScreen> createState() =>
      _ReviewSelectionScreenState();
}

class _ReviewSelectionScreenState extends ConsumerState<ReviewSelectionScreen> {
  final PageController _pageController = PageController();
  int? selectedReviewIndex;

  // Responsive variables
  late double screenWidth;
  late double screenHeight;
  late bool isTablet;
  late bool isSmallScreen;
  late double appBarFontSize;
  late double titleFontSize;
  late double subtitleFontSize;
  late double buttonFontSize;
  late double horizontalPadding;
  late double verticalSpacing;
  late double buttonHeight;

  void _calculateResponsiveSizes() {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    isTablet = screenWidth >= 768;
    isSmallScreen = screenWidth < 600;

    // Dynamic font sizes
    appBarFontSize = (screenWidth * (isTablet ? 0.035 : 0.055)).clamp(
      18.0,
      30.0,
    );
    titleFontSize = (screenWidth * (isTablet ? 0.032 : 0.05)).clamp(16.0, 26.0);
    subtitleFontSize = (screenWidth * (isTablet ? 0.025 : 0.04)).clamp(
      12.0,
      18.0,
    );
    buttonFontSize = (screenWidth * (isTablet ? 0.028 : 0.045)).clamp(
      14.0,
      22.0,
    );

    // Dynamic spacing and padding
    horizontalPadding = (screenWidth * (isTablet ? 0.06 : 0.04)).clamp(
      16.0,
      48.0,
    );
    verticalSpacing = (screenHeight * (isTablet ? 0.025 : 0.02)).clamp(
      12.0,
      24.0,
    );

    // Button height with constraints
    buttonHeight = (screenHeight * (isTablet ? 0.065 : 0.055)).clamp(
      44.0,
      70.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _calculateResponsiveSizes();
    final reviews = ref.watch(generatedReviewsProvider);
    final textTheme = Theme.of(context).textTheme;

    final iconSize = (screenWidth * (isTablet ? 0.04 : 0.06)).clamp(20.0, 32.0);
    final indicatorSize = (screenWidth * (isTablet ? 0.03 : 0.025)).clamp(
      8.0,
      16.0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '리뷰 AI',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: appBarFontSize,
            fontFamily: 'Do Hyeon',
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: iconSize),
          onPressed: () => Navigator.of(context).pop(),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        actions: [
          if (selectedReviewIndex != null)
            Center(
              child: Container(
                margin: EdgeInsets.only(right: horizontalPadding * 0.5),
                padding: EdgeInsets.symmetric(
                  horizontal: (screenWidth * 0.03).clamp(8.0, 16.0),
                  vertical: (screenHeight * 0.008).clamp(4.0, 8.0),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isTablet ? 20.0 : 16.0),
                  border: Border.all(color: Colors.blue, width: 1.0),
                ),
                child: Text(
                  '선택됨',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Do Hyeon',
                    fontSize: subtitleFontSize,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              SizedBox(height: verticalSpacing * 2),

              // Title section with enhanced styling
              Container(
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Text(
                      '마음에 드는 리뷰 하나를 선택하세요',
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Do Hyeon',
                        fontSize: titleFontSize,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: verticalSpacing * 0.5),
                    Text(
                      '리뷰를 탭하여 선택할 수 있습니다',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontFamily: 'Do Hyeon',
                        fontSize: subtitleFontSize,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: verticalSpacing * 2),

              // Review cards with enhanced layout
              Expanded(
                flex: isTablet ? 6 : 5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isTablet ? 16.0 : 12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: isTablet ? 12.0 : 8.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: reviews.length,
                    onPageChanged: (index) {
                      // Auto-deselect when swiping to new page
                      if (selectedReviewIndex != null) {
                        setState(() {
                          selectedReviewIndex = null;
                        });
                      }
                    },
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      final isSelected = selectedReviewIndex == index;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 4.0 : 8.0,
                        ),
                        child: ReviewCard(
                          review: review,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              HapticFeedback.lightImpact();
                              if (isSelected) {
                                selectedReviewIndex = null;
                              } else {
                                selectedReviewIndex = index;
                              }
                            });
                          },
                          onEdit: () {
                            _showEditReviewDialog(context, index, review);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: verticalSpacing),

              // Page indicator with responsive styling
              if (reviews.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(
                    (screenWidth * 0.02).clamp(8.0, 16.0),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(isTablet ? 25.0 : 20.0),
                  ),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: reviews.length,
                    effect: WormEffect(
                      dotColor: Colors.grey.shade400,
                      activeDotColor: Theme.of(context).primaryColor,
                      dotHeight: indicatorSize,
                      dotWidth: indicatorSize,
                      spacing: indicatorSize * 0.8,
                      radius: indicatorSize,
                    ),
                  ),
                ),

              SizedBox(height: verticalSpacing * 2.5),

              // Action button with enhanced styling
              Container(
                width: double.infinity,
                height: buttonHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isTablet ? 12.0 : 8.0),
                  boxShadow: selectedReviewIndex != null
                      ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                            blurRadius: isTablet ? 12.0 : 8.0,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: selectedReviewIndex == null
                      ? null
                      : () => _saveSelectedReview(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedReviewIndex == null
                        ? Colors.grey.shade400
                        : Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isTablet ? 12.0 : 8.0,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: (screenHeight * 0.015).clamp(8.0, 16.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (selectedReviewIndex != null) ...[
                        Icon(Icons.save_alt, size: iconSize * 0.8),
                        SizedBox(width: (screenWidth * 0.02).clamp(4.0, 8.0)),
                      ],
                      Text(
                        selectedReviewIndex == null ? '리뷰를 선택하세요' : '선택한 리뷰 저장',
                        style: TextStyle(
                          fontFamily: 'Do Hyeon',
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: verticalSpacing * 2),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSelectedReview() async {
    if (selectedReviewIndex == null) return;

    try {
      final reviews = ref.read(generatedReviewsProvider);
      final selectedReviewText = reviews[selectedReviewIndex!];

      final imageFile = ref.read(imageProvider);
      final foodName = ref.read(foodNameProvider);
      final delivery = ref.read(deliveryRatingProvider);
      final taste = ref.read(tasteRatingProvider);
      final portion = ref.read(portionRatingProvider);
      final price = ref.read(priceRatingProvider);
      final style = ref.read(selectedReviewStyleProvider);
      final emphasisText = ref.read(emphasisProvider);

      final newEntry = ReviewHistoryEntry(
        foodName: foodName.isEmpty ? '이름 없음' : foodName,
        imagePath: imageFile?.path,
        deliveryRating: delivery,
        tasteRating: taste,
        portionRating: portion,
        priceRating: price,
        reviewStyle: style,
        emphasis: emphasisText.isEmpty ? null : emphasisText,
        generatedReviews: [selectedReviewText],
      );

      await ref.read(reviewHistoryProvider.notifier).addReview(newEntry);
      ref.read(foodHistoryProvider.notifier).addFood(foodName);

      await Clipboard.setData(ClipboardData(text: selectedReviewText));

      // Haptic feedback for successful save
      HapticFeedback.mediumImpact();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: (screenWidth * (isTablet ? 0.035 : 0.05)).clamp(
                  16.0,
                  24.0,
                ),
              ),
              SizedBox(width: (screenWidth * 0.03).clamp(8.0, 12.0)),
              Expanded(
                child: Text(
                  '선택한 리뷰가 저장되고 클립보드에 복사되었습니다.',
                  style: TextStyle(
                    fontFamily: 'Do Hyeon',
                    fontSize: subtitleFontSize,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 12.0 : 8.0),
          ),
          margin: EdgeInsets.all(horizontalPadding),
          duration: const Duration(seconds: 3),
        ),
      );

      resetAllProviders(ref);
      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '저장 중 오류가 발생했습니다. 다시 시도해주세요.',
            style: TextStyle(
              fontFamily: 'Do Hyeon',
              fontSize: subtitleFontSize,
            ),
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
  }

  void _showEditReviewDialog(
    BuildContext context,
    int index,
    String currentReview,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return EditReviewDialog(index: index, currentReview: currentReview);
      },
    );
  }
}

import 'package:review_ai/widgets/common/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/providers/review_provider.dart';
import 'package:review_ai/utils/responsive.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:review_ai/widgets/review_selection/edit_review_dialog.dart';
import 'package:review_ai/widgets/review_selection/review_card.dart';

class ReviewSelectionScreen extends ConsumerStatefulWidget {
  const ReviewSelectionScreen({super.key});

  @override
  ConsumerState<ReviewSelectionScreen> createState() =>
      _ReviewSelectionScreenState();
}

class _ReviewSelectionScreenState extends ConsumerState<ReviewSelectionScreen> {
  final PageController _pageController = PageController();
  int? selectedReviewIndex;
  List<String> _cachedReviews = []; // 리뷰를 캐시하여 상태 변화에 영향받지 않도록 함

  @override
  void initState() {
    super.initState();
    // 화면 초기화 시 리뷰를 캐시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reviewState = ref.read(reviewProvider);
      setState(() {
        _cachedReviews = List<String>.from(reviewState.generatedReviews);
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final textTheme = Theme.of(context).textTheme;

    // 캐시된 리뷰가 비어있다면 provider에서 다시 가져오기
    if (_cachedReviews.isEmpty) {
      final reviewState = ref.watch(reviewProvider);
      _cachedReviews = List<String>.from(reviewState.generatedReviews);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context, responsive, textTheme),
      body: _buildBody(context, responsive, _cachedReviews, textTheme),
    );
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
          fontWeight: FontWeight.bold,
          fontSize: responsive.appBarFontSize(),
          fontFamily: 'Do Hyeon',
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, size: responsive.iconSize()),
        onPressed: () {
          // 뒤로 가기 시 리뷰 상태를 리셋하여 무한 루프 방지
          ref.read(reviewProvider.notifier).setGeneratedReviews([]);
          Navigator.of(context).pop();
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      actions: [
        if (selectedReviewIndex != null)
          Center(
            child: Container(
              margin: EdgeInsets.only(
                right: responsive.horizontalPadding() * 0.5,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding() * 0.2,
                vertical: responsive.verticalSpacing() * 0.2,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 20.0 : 16.0,
                ),
              ),
              child: Text(
                '선택됨',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Do Hyeon',
                  fontSize: responsive.subtitleFontSize(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    Responsive responsive,
    List<String> reviews,
    TextTheme textTheme,
  ) {
    // 리뷰가 없는 경우 처리
    if (reviews.isEmpty) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: responsive.iconSize() * 2,
                color: Colors.grey[400],
              ),
              SizedBox(height: responsive.verticalSpacing()),
              Text(
                '생성된 리뷰가 없습니다.',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontFamily: 'Do Hyeon',
                ),
              ),
              SizedBox(height: responsive.verticalSpacing()),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('뒤로 가기', style: TextStyle(fontFamily: 'Do Hyeon')),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.horizontalPadding() * 0.8,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: responsive.verticalSpacing() * 2),
          child: Column(
            children: [
              SizedBox(height: responsive.verticalSpacing() * 2),

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
                        fontSize: responsive.titleFontSize(),
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: responsive.verticalSpacing() * 0.5),
                    Text(
                      '리뷰를 탭하여 선택할 수 있습니다',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontFamily: 'Do Hyeon',
                        fontSize: responsive.subtitleFontSize(),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: responsive.verticalSpacing() * 2),

              // Review cards with enhanced layout
              Expanded(
                flex: responsive.isTablet ? 6 : 5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      responsive.isTablet ? 16.0 : 12.0,
                    ),
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: reviews.length,
                    onPageChanged: (index) {
                      // Do not auto-deselect when swiping to new page
                    },
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      final isSelected = selectedReviewIndex == index;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.symmetric(
                          horizontal: responsive.isSmallScreen ? 6.0 : 10.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            responsive.isTablet ? 16.0 : 12.0,
                          ),
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

              SizedBox(height: responsive.verticalSpacing()),

              // Page indicator with responsive styling
              if (reviews.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(responsive.horizontalPadding() * 0.2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(
                      responsive.isTablet ? 25.0 : 20.0,
                    ),
                  ),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: reviews.length,
                    effect: WormEffect(
                      dotColor: Colors.grey.shade400,
                      activeDotColor: Theme.of(context).primaryColor,
                      dotHeight: responsive.iconSize() * 0.5,
                      dotWidth: responsive.iconSize() * 0.5,
                      spacing: responsive.iconSize() * 0.4,
                      radius: responsive.iconSize() * 0.5,
                    ),
                  ),
                ),

              SizedBox(height: responsive.verticalSpacing() * 2.5),

              // Action button with enhanced styling and added horizontal padding
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding() * 0.8,
                ),
                child: Container(
                  width: double.infinity,
                  height: responsive.buttonHeight(),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      responsive.isTablet ? 24.0 : 20.0,
                    ),
                    boxShadow: selectedReviewIndex != null
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withAlpha((0.3 * 255).round()),
                              blurRadius: responsive.isTablet ? 12.0 : 8.0,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: selectedReviewIndex == null
                        ? null
                        : () => _saveSelectedReview(context, responsive),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedReviewIndex == null
                          ? Colors.grey.shade400
                          : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          responsive.isTablet ? 24.0 : 20.0,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          selectedReviewIndex == null
                              ? '리뷰를 선택하세요'
                              : '선택한 리뷰 저장',
                          style: TextStyle(
                            fontFamily: 'Do Hyeon',
                            fontSize: responsive.buttonFontSize(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: responsive.verticalSpacing()),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSelectedReview(
    BuildContext context,
    Responsive responsive,
  ) async {
    if (selectedReviewIndex == null) return;

    try {
      final reviewState = ref.read(reviewProvider);
      final selectedReviewText = _cachedReviews[selectedReviewIndex!];

      final newEntry = ReviewHistoryEntry(
        foodName: reviewState.foodName.isEmpty ? '이름 없음' : reviewState.foodName,
        imagePath: reviewState.image?.path,
        deliveryRating: reviewState.deliveryRating,
        tasteRating: reviewState.tasteRating,
        portionRating: reviewState.portionRating,
        priceRating: reviewState.priceRating,
        reviewStyle: reviewState.selectedReviewStyle,
        emphasis: reviewState.emphasis.isEmpty ? null : reviewState.emphasis,
        category: reviewState.category,
        generatedReviews: [selectedReviewText], // Save only the selected review
      );

      await ref.read(reviewHistoryProvider.notifier).addReview(newEntry);

      await Clipboard.setData(ClipboardData(text: selectedReviewText));

      // Haptic feedback for successful save
      HapticFeedback.mediumImpact();

      if (!context.mounted) return;

      showAppDialog(context, title: '성공', message: '리뷰가 저장되고 클립보드에 복사되었습니다.');

      // 리뷰 상태를 완전히 리셋하고 홈 화면으로 돌아가기
      ref.read(reviewProvider.notifier).reset();

      if (!context.mounted) return;
      // 모든 화면을 닫고 처음 화면으로 돌아가기
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!context.mounted) return;
      showAppDialog(
        context,
        title: '오류',
        message: '저장 중 오류가 발생했습니다. 다시 시도해주세요.',
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
    ).then((_) {
      // 다이얼로그가 닫힌 후 provider에서 최신 리뷰를 가져와서 캐시 업데이트
      final reviewState = ref.read(reviewProvider);
      if (reviewState.generatedReviews.isNotEmpty &&
          index < reviewState.generatedReviews.length) {
        setState(() {
          _cachedReviews[index] = reviewState.generatedReviews[index];
        });
      }
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';
import 'package:review_ai/presentation/widgets/common/app_dialogs.dart';
import 'package:review_ai/presentation/widgets/review_selection/edit_review_dialog.dart';
import 'package:review_ai/presentation/widgets/review_selection/review_card_widget.dart';
import 'package:review_ai/presentation/widgets/review_selection/review_selection_widgets.dart';
import 'package:review_ai/services/food_insight_service.dart';
import 'package:review_ai/utils/responsive.dart';

class ReviewSelectionScreen extends ConsumerStatefulWidget {
  const ReviewSelectionScreen({super.key});

  @override
  ConsumerState<ReviewSelectionScreen> createState() =>
      _ReviewSelectionScreenState();
}

class _ReviewSelectionScreenState extends ConsumerState<ReviewSelectionScreen> {
  final PageController _pageController = PageController();
  int? selectedReviewIndex;
  List<String> _cachedReviews = [];

  @override
  void initState() {
    super.initState();
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

    if (_cachedReviews.isEmpty) {
      final reviewState = ref.watch(reviewProvider);
      _cachedReviews = List<String>.from(reviewState.generatedReviews);
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(context, responsive, textTheme),
        body: _cachedReviews.isEmpty
            ? _buildEmptyState(context, responsive, textTheme)
            : _buildContent(context, responsive, textTheme),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    Responsive responsive,
    TextTheme textTheme,
  ) {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Semantics(
        header: true,
        label: '마음에 드는 리뷰 선택하기',
        child: Text(
          '리뷰 AI',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: responsive.appBarFontSize(),
            fontFamily: 'Do Hyeon',
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    Responsive responsive,
    TextTheme textTheme,
  ) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: responsive.iconSize() * 2, color: Colors.grey[400]),
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

  Widget _buildContent(
    BuildContext context,
    Responsive responsive,
    TextTheme textTheme,
  ) {
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
              _buildTitleSection(context, responsive, textTheme),
              SizedBox(height: responsive.verticalSpacing() * 2),
              Expanded(
                flex: responsive.isTablet ? 6 : 5,
                child: _buildPageView(responsive, textTheme),
              ),
              SizedBox(height: responsive.verticalSpacing()),
              ReviewPageIndicator(
                controller: _pageController,
                count: _cachedReviews.length,
                responsive: responsive,
              ),
              SizedBox(height: responsive.verticalSpacing() * 2.5),
              ReviewActionButton(
                isEnabled: selectedReviewIndex != null,
                responsive: responsive,
                onPressed: () => _saveSelectedReview(context, responsive),
              ),
              SizedBox(height: responsive.verticalSpacing()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(
    BuildContext context,
    Responsive responsive,
    TextTheme textTheme,
  ) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        children: [
          Semantics(
            header: true,
            child: Text(
              '마음에 드는 리뷰 하나를 선택하세요',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Do Hyeon',
                fontSize: responsive.titleFontSize(),
                color: Colors.grey[800],
              ),
            ),
          ),
          SizedBox(height: responsive.verticalSpacing() * 0.5),
          Text(
            '리뷰를 탭하여 선택할 수 있습니다',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontFamily: 'Do Hyeon',
              fontSize: responsive.subtitleFontSize(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView(Responsive responsive, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 12.0),
      ),
      child: PageView.builder(
        controller: _pageController,
        itemCount: _cachedReviews.length,
        itemBuilder: (context, index) {
          final isSelected = selectedReviewIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(
              horizontal: responsive.isSmallScreen ? 6.0 : 10.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 12.0),
            ),
            child: ReviewCardWidget(
              review: _cachedReviews[index],
              isSelected: isSelected,
              responsive: responsive,
              textTheme: textTheme,
              onTap: () => setState(() {
                HapticFeedback.lightImpact();
                selectedReviewIndex = isSelected ? null : index;
              }),
              onEdit: () => _showEditReviewDialog(context, index, _cachedReviews[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveSelectedReview(BuildContext context, Responsive responsive) async {
    if (selectedReviewIndex == null) return;
    try {
      final reviewState = ref.read(reviewProvider);
      final selectedReviewText = _cachedReviews[selectedReviewIndex!];
      final foodName = reviewState.foodName.isEmpty ? '이름 없음' : reviewState.foodName;
      String category = reviewState.category;
      if (category.isEmpty || category == '기타') {
        category = await FoodInsightService.inferCategory(foodName);
      }

      final newEntry = ReviewHistoryEntry(
        foodName: foodName,
        imagePath: reviewState.image?.path,
        deliveryRating: reviewState.deliveryRating,
        tasteRating: reviewState.tasteRating,
        portionRating: reviewState.portionRating,
        priceRating: reviewState.priceRating,
        reviewStyle: reviewState.selectedReviewStyle,
        emphasis: reviewState.emphasis.isEmpty ? null : reviewState.emphasis,
        category: category,
        generatedReviews: [selectedReviewText],
      );

      await ref.read(reviewHistoryProvider.notifier).addReview(newEntry);
      await Clipboard.setData(ClipboardData(text: selectedReviewText));
      HapticFeedback.mediumImpact();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('클립보드 복사 및 히스토리에 저장되었습니다.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      ref.read(reviewProvider.notifier).reset();
      if (!context.mounted) return;
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

  void _showEditReviewDialog(BuildContext context, int index, String currentReview) {
    showDialog(
      context: context,
      builder: (dialogContext) => EditReviewDialog(index: index, currentReview: currentReview),
    ).then((_) {
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

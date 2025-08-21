import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reviewai_flutter/providers/review_provider.dart';
import 'package:reviewai_flutter/providers/food_providers.dart'; // Added import
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:reviewai_flutter/widgets/review_selection/edit_review_dialog.dart';
import 'package:reviewai_flutter/widgets/review_selection/review_card.dart';

class ReviewSelectionScreen extends ConsumerStatefulWidget {
  const ReviewSelectionScreen({super.key});

  @override
  ConsumerState<ReviewSelectionScreen> createState() =>
      _ReviewSelectionScreenState();
}

class _ReviewSelectionScreenState extends ConsumerState<ReviewSelectionScreen> {
  final PageController _pageController = PageController();
  int? selectedReviewIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviews = ref.watch(generatedReviewsProvider);
    final textTheme = Theme.of(context).textTheme;

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '리뷰 AI',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.055, // 화면 크기에 비례
            fontFamily: 'Do Hyeon',
          ),
        ),
        elevation: 0,
        actions: [
          if (selectedReviewIndex != null)
            Center(
              child: Padding(
                padding: EdgeInsets.only(right: screenWidth * 0.04),
                child: Text(
                  '선택됨',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Do Hyeon',
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.04),
              Text(
                '마음에 드는 리뷰 하나를 선택하세요',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Do Hyeon',
                  fontSize: screenWidth * 0.05,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                '리뷰를 탭하여 선택할 수 있습니다',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontFamily: 'Do Hyeon',
                  fontSize: screenWidth * 0.04,
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              Expanded(
                flex: 5,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final isSelected = selectedReviewIndex == index;

                    return ReviewCard(
                      review: review,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
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
                    );
                  },
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              if (reviews.isNotEmpty)
                SmoothPageIndicator(
                  controller: _pageController,
                  count: reviews.length,
                  effect: WormEffect(
                    dotColor: Colors.grey.shade300,
                    activeDotColor: Colors.black,
                    dotHeight: screenWidth * 0.025,
                    dotWidth: screenWidth * 0.025,
                  ),
                ),
              SizedBox(height: screenHeight * 0.05),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedReviewIndex == null
                      ? null
                      : () async {
                          final selectedReviewText =
                              reviews[selectedReviewIndex!];

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
                            emphasis: emphasisText.isEmpty
                                ? null
                                : emphasisText,
                            generatedReviews: [selectedReviewText],
                          );

                          await ref
                              .read(reviewHistoryProvider.notifier)
                              .addReview(newEntry);
                          ref.read(foodHistoryProvider.notifier).addFood(foodName); // Add food name to history

                          await Clipboard.setData(
                            ClipboardData(text: selectedReviewText),
                          );

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '선택한 리뷰가 저장되고 클립보드에 복사되었습니다.',
                                style: const TextStyle(fontFamily: 'Do Hyeon'),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );

                          resetAllProviders(ref);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedReviewIndex == null
                        ? Colors.grey
                        : null,
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02,
                    ),
                  ),
                  child: Text(
                    selectedReviewIndex == null ? '리뷰를 선택하세요' : '선택한 리뷰 저장',
                    style: TextStyle(
                      fontFamily: 'Do Hyeon',
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditReviewDialog(BuildContext context, int index, String currentReview) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return EditReviewDialog(index: index, currentReview: currentReview);
      },
    );
  }
}

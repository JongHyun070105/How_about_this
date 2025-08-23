import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/providers/review_provider.dart';

class ReviewStyleSection extends ConsumerWidget {
  const ReviewStyleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;
    final reviewStyles = ref.watch(reviewStylesProvider);
    final selectedStyle = ref.watch(reviewProvider).selectedReviewStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '리뷰 스타일',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Do Hyeon',
            fontSize: screenSize.width * 0.045,
          ),
        ),
        SizedBox(height: screenSize.height * 0.01),
        Wrap(
          spacing: screenSize.width * 0.02,
          runSpacing: screenSize.height * 0.005,
          children: reviewStyles.map((style) {
            return Theme(
              data: Theme.of(
                context,
              ).copyWith(splashFactory: NoSplash.splashFactory),
              child: ChoiceChip(
                label: Text(
                  style,
                  style: TextStyle(
                    fontFamily: 'Do Hyeon',
                    fontSize: screenSize.width * 0.035,
                    color: selectedStyle == style ? Colors.white : Colors.black,
                  ),
                ),
                selected: selectedStyle == style,
                onSelected: (isSelected) {
                  if (isSelected) {
                    ref.read(reviewProvider.notifier).setSelectedReviewStyle(style);
                  }
                },
                selectedColor: Colors.black, // 선택된 상태: 검은색
                backgroundColor: Colors.white, // 기본 상태: 흰색 배경
                side: BorderSide(
                  color: selectedStyle == style
                      ? Colors.black
                      : Colors.grey[400]!,
                  width: 1.0,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
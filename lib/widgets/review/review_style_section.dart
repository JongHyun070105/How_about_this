
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reviewai_flutter/providers/review_provider.dart';

class ReviewStyleSection extends ConsumerWidget {
  const ReviewStyleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;
    final reviewStyles = ref.watch(reviewStylesProvider);
    final selectedStyle = ref.watch(selectedReviewStyleProvider);

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
            return ChoiceChip(
              label: Text(
                style,
                style: TextStyle(
                  fontFamily: 'Do Hyeon',
                  fontSize: screenSize.width * 0.035,
                ),
              ),
              selected: selectedStyle == style,
              onSelected: (isSelected) {
                if (isSelected) {
                  ref.read(selectedReviewStyleProvider.notifier).state = style;
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

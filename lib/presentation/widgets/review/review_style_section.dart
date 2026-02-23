import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';

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
        Semantics(
          header: true,
          child: Text(
            '리뷰 스타일',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Do Hyeon',
              fontSize: screenSize.width * 0.045,
            ),
          ),
        ),
        SizedBox(height: screenSize.height * 0.01),
        Wrap(
          spacing: screenSize.width * 0.02,
          runSpacing: screenSize.height * 0.005,
          children: reviewStyles.map((style) {
            final isSelected = selectedStyle == style;
            return Semantics(
              button: true,
              label: '$style 스타일',
              selected: isSelected,
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(splashFactory: NoSplash.splashFactory),
                child: ChoiceChip(
                  label: Text(
                    style,
                    style: TextStyle(
                      fontFamily: 'Do Hyeon',
                      fontSize: screenSize.width * 0.035,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (isSelected) {
                    if (isSelected) {
                      ref
                          .read(reviewProvider.notifier)
                          .setSelectedReviewStyle(style);
                    }
                  },
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary, // 선택된 상태
                  backgroundColor: Theme.of(
                    context,
                  ).chipTheme.backgroundColor, // 기본 상태
                  side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                    width: 1.0,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

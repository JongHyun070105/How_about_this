import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/config/app_constants.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';
import 'package:review_ai/utils/responsive.dart';
import 'package:review_ai/presentation/widgets/review/rating_row.dart';

/// 음식명 입력 필드 위젯 (AI 자동완성 버튼 포함)
class FoodNameInputField extends ConsumerWidget {
  final TextEditingController controller;
  final bool isGenerating;
  final bool isUpdatingFromProvider;
  final VoidCallback onAiTap;

  const FoodNameInputField({
    super.key,
    required this.controller,
    required this.isGenerating,
    required this.isUpdatingFromProvider,
    required this.onAiTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = Responsive(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).shadowColor.withAlpha((255 * 0.05).round()),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLength: AppConstants.maxFoodNameLength,
        autocorrect: false,
        enableSuggestions: false,
        enableInteractiveSelection: false,
        enabled: !isGenerating,
        onChanged: (text) {
          if (!isUpdatingFromProvider) {
            ref.read(reviewProvider.notifier).setFoodName(text);
          }
        },
        style: TextStyle(
          fontFamily: 'SCDream',
          fontSize: responsive.inputFontSize(),
          color: Theme.of(context).textTheme.bodyMedium?.color,
          decoration: TextDecoration.none,
        ),
        decoration: InputDecoration(
          hintText: isGenerating ? 'AI가 음식명 생성 중...' : '음식명을 입력해주세요',
          counterText: '',
          hintStyle: TextStyle(
            fontFamily: 'SCDream',
            fontSize: responsive.inputFontSize() * 0.9,
            color: isGenerating ? Colors.grey[500] : Colors.grey[400],
          ),
          suffixIcon: isGenerating
              ? null
              : IconButton(
                  onPressed: onAiTap,
                  tooltip: 'AI로 음식명 생성',
                  icon: Semantics(
                    label: '음식 이미지로부터 음식명 자동 추출',
                    button: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[800]!, Colors.black],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI',
                            style: TextStyle(
                              fontFamily: 'SCDream',
                              fontSize: responsive.inputFontSize() * 0.8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          border: const UnderlineInputBorder(borderSide: BorderSide.none),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide.none,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide.none,
          ),
          errorBorder: const UnderlineInputBorder(borderSide: BorderSide.none),
          disabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
          filled: false,
        ),
      ),
    );
  }
}

/// 4개 항목 평점 입력 컨테이너
class RatingSection extends ConsumerWidget {
  const RatingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = Responsive(context);
    final reviewState = ref.watch(reviewProvider);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1.0),
      ),
      child: Column(
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
            onRate: (r) => ref.read(reviewProvider.notifier).setTasteRating(r),
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
            onRate: (r) => ref.read(reviewProvider.notifier).setPriceRating(r),
          ),
        ],
      ),
    );
  }
}

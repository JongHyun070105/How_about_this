import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:review_ai/utils/responsive.dart';

/// 리뷰 페이지 인디케이터 위젯
class ReviewPageIndicator extends StatelessWidget {
  final PageController controller;
  final int count;
  final Responsive responsive;

  const ReviewPageIndicator({
    super.key,
    required this.controller,
    required this.count,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Semantics(
      label:
          '총 $count개의 리뷰 중 현재 ${(controller.hasClients ? controller.page?.round() ?? 0 : 0) + 1}번째 리뷰',
      child: Container(
        padding: EdgeInsets.all(responsive.horizontalPadding() * 0.2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(
            responsive.isTablet ? 25.0 : 20.0,
          ),
        ),
        child: SmoothPageIndicator(
          controller: controller,
          count: count,
          effect: WormEffect(
            dotColor: Theme.of(context).dividerColor,
            activeDotColor: Theme.of(context).primaryColor,
            dotHeight: responsive.iconSize() * 0.5,
            dotWidth: responsive.iconSize() * 0.5,
            spacing: responsive.iconSize() * 0.4,
            radius: responsive.iconSize() * 0.5,
          ),
        ),
      ),
    );
  }
}

/// 리뷰 선택 저장 버튼 위젯
class ReviewActionButton extends StatelessWidget {
  final bool isEnabled;
  final Responsive responsive;
  final VoidCallback onPressed;

  const ReviewActionButton({
    super.key,
    required this.isEnabled,
    required this.responsive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          boxShadow: isEnabled
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
        child: Semantics(
          label: isEnabled
              ? '선택한 리뷰를 클립보드에 복사하고 히스토리에 저장하기'
              : '리뷰를 먼저 선택해야 저장할 수 있습니다',
          button: true,
          enabled: isEnabled,
          child: ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 24.0 : 20.0,
                ),
              ),
              padding: EdgeInsets.symmetric(
                vertical: responsive.verticalSpacing() * 0.8,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    isEnabled ? '선택한 리뷰 저장' : '리뷰를 선택하세요',
                    style: TextStyle(
                      fontFamily: 'Do Hyeon',
                      fontSize: responsive.buttonFontSize(),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

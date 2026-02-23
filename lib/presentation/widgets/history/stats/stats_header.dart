import 'package:flutter/material.dart';
import 'package:review_ai/utils/responsive_helper.dart';

/// 통계 다이얼로그 헤더 위젯
class StatsHeader extends StatelessWidget {
  final int currentPage;
  final int maxPages;
  final VoidCallback onClose;

  const StatsHeader({
    super.key,
    required this.currentPage,
    required this.maxPages,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final headerFontSize = responsive.fontSize(
      mobileRatio: 0.045,
      tabletRatio: 0.028,
      min: 14.0,
      max: 24.0,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.widthRatio(0.04),
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color:
            Theme.of(context).dialogTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha((255 * 0.1).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            currentPage == 0 ? '📊 사용 통계' : '📈 카테고리별 분석',
            style: TextStyle(
              fontFamily: 'Do Hyeon',
              fontSize: headerFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              ...List.generate(
                maxPages,
                (index) => _PageIndicatorDot(isActive: currentPage == index),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 페이지 인디케이터 점
class _PageIndicatorDot extends StatelessWidget {
  final bool isActive;

  const _PageIndicatorDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? Theme.of(context).primaryColor
            : Theme.of(context).disabledColor,
      ),
    );
  }
}

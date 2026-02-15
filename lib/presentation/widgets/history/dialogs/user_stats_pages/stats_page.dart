import 'package:flutter/material.dart';
import 'package:review_ai/presentation/widgets/history/food_insight_card.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';

/// 사용자 통계 페이지 위젯
///
/// 인사이트 카드 + 사용량 현황을 표시합니다.
class StatsPageWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  final int remainingRecommendations;
  final int remainingReviews;
  final int maxRecommendations;
  final int maxReviews;
  final List<ReviewHistoryEntry> history;

  const StatsPageWidget({
    super.key,
    required this.stats,
    required this.remainingRecommendations,
    required this.remainingReviews,
    required this.maxRecommendations,
    required this.maxReviews,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final usedRecommendations = (maxRecommendations - remainingRecommendations)
        .clamp(0, maxRecommendations);
    final usedReviews = (maxReviews - remainingReviews).clamp(0, maxReviews);

    final usageTextStyle = TextStyle(
      fontFamily: 'Do Hyeon',
      fontSize: (screenSize.width * 0.037).clamp(13.0, 18.0),
      color: Colors.grey[700],
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 식습관 인사이트 카드
            FoodInsightCard(history: history),
            const SizedBox(height: 12),
            // 사용량 현황
            _buildUsageSection(
              screenSize,
              usageTextStyle,
              usedRecommendations,
              usedReviews,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageSection(
    Size screenSize,
    TextStyle usageTextStyle,
    int usedRecommendations,
    int usedReviews,
  ) {
    return Column(
      children: [
        _buildUsageIndicator(
          screenSize,
          label: "음식 추천 사용량",
          used: usedRecommendations,
          max: maxRecommendations,
          color: Colors.grey[700]!,
          style: usageTextStyle,
        ),
        const SizedBox(height: 12),
        _buildUsageIndicator(
          screenSize,
          label: "리뷰 사용량",
          used: usedReviews,
          max: maxReviews,
          color: Colors.grey[500]!,
          style: usageTextStyle,
        ),
        const SizedBox(height: 12),
        _buildTimeInfo(screenSize),
      ],
    );
  }

  Widget _buildTimeInfo(Size screenSize) {
    final now = DateTime.now();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: (screenSize.width * 0.02).clamp(8.0, 16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "매일 00:00시에 초기화",
            style: TextStyle(
              fontFamily: 'Do Hyeon',
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          Text(
            "현재 시간: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
            style: TextStyle(
              fontFamily: 'Do Hyeon',
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageIndicator(
    Size screenSize, {
    required String label,
    required int used,
    required int max,
    required Color color,
    required TextStyle style,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: (screenSize.width * 0.02).clamp(8.0, 16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: $used / $max", style: style),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: max > 0 ? used / max : 0,
            minHeight: 10,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:review_ai/presentation/widgets/history/food_insight_card.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';
import 'package:review_ai/services/food_insight_service.dart';

/// 사용자 통계 페이지 위젯
///
/// 인사이트 카드 + 단골 메뉴 하이라이트 + 사용량 현황을 표시합니다.
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
      fontSize: (screenSize.width * 0.035).clamp(12.0, 16.0),
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
            const SizedBox(height: 16),

            // 단골 메뉴 하이라이트
            if (history.isNotEmpty) _buildFavoriteMenuHighlight(history),
            const SizedBox(height: 24),

            // 사용량 현황 (컴팩트하게 개선)
            _buildUsageSection(
              screenSize,
              usageTextStyle,
              usedRecommendations,
              usedReviews,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 단골 메뉴 하이라이트 위젯
  Widget _buildFavoriteMenuHighlight(List<ReviewHistoryEntry> history) {
    final topFoods = FoodInsightService.getTopFoods(history);
    if (topFoods.isEmpty) return const SizedBox.shrink();

    final favorite = topFoods.first;
    final foodName = favorite['foodName'] as String;
    final count = favorite['count'] as int;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: const Color(0x05000000), // black.withOpacity(0.02)
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '나의 최애 메뉴',
                  style: TextStyle(
                    fontFamily: 'Do Hyeon',
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  foodName,
                  style: const TextStyle(
                    fontFamily: 'Do Hyeon',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '현재까지 총 $count회 방문하셨어요!',
                  style: TextStyle(
                    fontFamily: 'Do Hyeon',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.star, color: Colors.amber, size: 24),
        ],
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
          color: Colors.black87,
          style: usageTextStyle,
        ),
        const SizedBox(height: 8),
        _buildUsageIndicator(
          screenSize,
          label: "리뷰 작성 사용량",
          used: usedReviews,
          max: maxReviews,
          color: Colors.grey[600]!,
          style: usageTextStyle,
        ),
        const SizedBox(height: 8),
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
            "매일 00:00시에 초기화됩니다",
            style: TextStyle(
              fontFamily: 'Do Hyeon',
              fontSize: 10,
              color: Colors.grey[400],
            ),
          ),
          Text(
            "현재 시간: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
            style: TextStyle(
              fontFamily: 'Do Hyeon',
              fontSize: 10,
              color: Colors.grey[400],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: style),
              Text(
                "$used / $max",
                style: style.copyWith(color: Colors.grey[400], fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: max > 0 ? used / max : 0,
              minHeight: 6,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

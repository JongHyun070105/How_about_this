import 'package:flutter/material.dart';

/// 사용자 통계 페이지 위젯
///
/// 총 선택 횟수, 최근 활동, 선호 음식 TOP 5, 사용량 현황을 표시합니다.
class StatsPageWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  final int remainingRecommendations;
  final int remainingReviews;
  final int maxRecommendations;
  final int maxReviews;

  const StatsPageWidget({
    super.key,
    required this.stats,
    required this.remainingRecommendations,
    required this.remainingReviews,
    required this.maxRecommendations,
    required this.maxReviews,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final topFoodsList = (stats['topFoods'] as List).take(5).toList();
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
            _buildStatItem(
              screenSize,
              isTablet,
              "총 선택 횟수",
              "${stats['totalSelections']}회",
            ),
            _buildStatItem(
              screenSize,
              isTablet,
              "최근 30일 선택",
              "${stats['recentSelections']}회",
            ),
            const SizedBox(height: 10),
            _buildTopFoodsSection(screenSize, isTablet, topFoodsList),
            const SizedBox(height: 16),
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

  Widget _buildTopFoodsSection(
    Size screenSize,
    bool isTablet,
    List topFoodsList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: (screenSize.width * 0.02).clamp(8.0, 16.0),
          ),
          child: const Text(
            "❤️ 선호하는 음식 TOP 5",
            style: TextStyle(
              fontFamily: 'Do Hyeon',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            if (index < topFoodsList.length) {
              final food = topFoodsList[index];
              return _buildStatItem(
                screenSize,
                false,
                food['name'],
                "${food['count']}회",
              );
            } else {
              return _buildStatItem(screenSize, false, "-", "-");
            }
          },
        ),
      ],
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
          color: Colors.blue.shade400,
          style: usageTextStyle,
        ),
        const SizedBox(height: 12),
        _buildUsageIndicator(
          screenSize,
          label: "리뷰 사용량",
          used: usedReviews,
          max: maxReviews,
          color: Colors.green.shade400,
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

  Widget _buildStatItem(
    Size screenSize,
    bool isTablet,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: (screenSize.height * 0.008).clamp(4.0, 8.0),
        horizontal: (screenSize.width * 0.02).clamp(8.0, 16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: (screenSize.width * (isTablet ? 0.025 : 0.035)).clamp(
                  12.0,
                  18.0,
                ),
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          SizedBox(width: (screenSize.width * 0.04).clamp(12.0, 20.0)),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: (screenSize.width * (isTablet ? 0.028 : 0.038)).clamp(
                  14.0,
                  20.0,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              textAlign: TextAlign.right,
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

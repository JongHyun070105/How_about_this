import 'package:flutter/material.dart';
import 'package:review_ai/services/ai_food_insight_service.dart';
import 'package:review_ai/services/food_insight_service.dart';
import 'package:review_ai/providers/review_provider.dart';

/// 식습관 인사이트 카드 위젯
///
/// 히스토리 화면 상단에 표시되어, 사용자의 식습관 요약 정보를 보여줍니다.
/// AI 인사이트를 비동기로 불러와 자연스러운 메시지를 표시합니다.
class FoodInsightCard extends StatefulWidget {
  final List<ReviewHistoryEntry> history;

  const FoodInsightCard({super.key, required this.history});

  @override
  State<FoodInsightCard> createState() => _FoodInsightCardState();
}

class _FoodInsightCardState extends State<FoodInsightCard> {
  AiInsightResult? _aiInsight;
  bool _isLoadingAi = true;

  @override
  void initState() {
    super.initState();
    _loadAiInsight();
  }

  @override
  void didUpdateWidget(covariant FoodInsightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.history.length != oldWidget.history.length) {
      _loadAiInsight();
    }
  }

  Future<void> _loadAiInsight() async {
    if (widget.history.isEmpty) return;

    setState(() => _isLoadingAi = true);

    try {
      final result = await AiFoodInsightService().getInsight(widget.history);
      if (mounted) {
        setState(() {
          _aiInsight = result;
          _isLoadingAi = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiInsight = AiInsightResult(
            message: FoodInsightService.generateInsightMessage(widget.history),
            isAi: false,
          );
          _isLoadingAi = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) return const SizedBox.shrink();

    final summary = FoodInsightService.generateSummary(widget.history);
    final categoryFrequency = summary['categoryFrequency'] as Map<String, int>;
    final topFoods = summary['topFoods'] as List<Map<String, dynamic>>;
    final totalReviews = summary['totalReviews'] as int;
    final weeklyCount = summary['weeklyCount'] as int;

    // 로컬 폴백 메시지 (AI 로딩 전에 표시)
    final insightMessage =
        _aiInsight?.message ?? summary['insightMessage'] as String;
    final isAi = _aiInsight?.isAi ?? false;

    final screenWidth = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.deepOrange.shade200),
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Icon(
                  Icons.insights_rounded,
                  color: Colors.deepOrange.shade400,
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  '나의 식습관 인사이트',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Do Hyeon',
                    fontSize: screenWidth * 0.042,
                    color: Colors.deepOrange.shade700,
                  ),
                ),
                const Spacer(),
                // AI 배지
                if (isAi && !_isLoadingAi)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenWidth * 0.008,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.deepOrange.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: screenWidth * 0.03,
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          'AI',
                          style: TextStyle(
                            fontFamily: 'Do Hyeon',
                            fontSize: screenWidth * 0.025,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: screenWidth * 0.03),

            // 인사이트 메시지
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: isAi
                    ? Colors.deepPurple.shade50
                    : Colors.deepOrange.shade50,
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
              child: Row(
                children: [
                  if (_isLoadingAi)
                    SizedBox(
                      width: screenWidth * 0.04,
                      height: screenWidth * 0.04,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.deepOrange.shade300,
                      ),
                    )
                  else
                    Text(
                      isAi ? '✨' : '💡',
                      style: TextStyle(fontSize: screenWidth * 0.05),
                    ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: _isLoadingAi
                        ? Text(
                            insightMessage,
                            style: textTheme.bodyMedium?.copyWith(
                              fontFamily: 'Do Hyeon',
                              fontSize: screenWidth * 0.033,
                              height: 1.4,
                              color: Colors.grey.shade500,
                            ),
                          )
                        : Text(
                            insightMessage,
                            style: textTheme.bodyMedium?.copyWith(
                              fontFamily: 'Do Hyeon',
                              fontSize: screenWidth * 0.033,
                              height: 1.4,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.03),

            // 통계 요약 행
            Row(
              children: [
                _buildStatBadge(
                  context,
                  '📝',
                  '총 리뷰',
                  '$totalReviews개',
                  screenWidth,
                ),
                SizedBox(width: screenWidth * 0.02),
                _buildStatBadge(
                  context,
                  '📅',
                  '이번 주',
                  '$weeklyCount개',
                  screenWidth,
                ),
                SizedBox(width: screenWidth * 0.02),
                if (categoryFrequency.isNotEmpty)
                  _buildStatBadge(
                    context,
                    FoodInsightService.categoryEmojis[categoryFrequency
                            .keys
                            .first] ??
                        '🍽️',
                    '선호',
                    categoryFrequency.keys.first,
                    screenWidth,
                  ),
              ],
            ),

            // 카테고리 분포 바
            if (categoryFrequency.isNotEmpty) ...[
              SizedBox(height: screenWidth * 0.03),
              Text(
                '카테고리 분포',
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: 'Do Hyeon',
                  fontSize: screenWidth * 0.03,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: screenWidth * 0.015),
              _buildCategoryBar(categoryFrequency, totalReviews, screenWidth),
              SizedBox(height: screenWidth * 0.01),
              // 범례
              Wrap(
                spacing: screenWidth * 0.03,
                runSpacing: screenWidth * 0.01,
                children: categoryFrequency.entries
                    .take(4)
                    .map(
                      (e) => _buildLegendItem(
                        e.key,
                        e.value,
                        totalReviews,
                        screenWidth,
                      ),
                    )
                    .toList(),
              ),
            ],

            // Top 음식
            if (topFoods.isNotEmpty && topFoods.first['count'] as int >= 2) ...[
              SizedBox(height: screenWidth * 0.03),
              Text(
                '자주 드시는 메뉴',
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: 'Do Hyeon',
                  fontSize: screenWidth * 0.03,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: screenWidth * 0.01),
              Wrap(
                spacing: screenWidth * 0.015,
                runSpacing: screenWidth * 0.008,
                children: topFoods
                    .where((f) => (f['count'] as int) >= 2)
                    .take(5)
                    .map(
                      (f) => Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          '${f['foodName']} ×${f['count']}',
                          style: TextStyle(
                            fontFamily: 'Do Hyeon',
                            fontSize: screenWidth * 0.028,
                            color: Colors.deepOrange.shade700,
                          ),
                        ),
                        backgroundColor: Colors.deepOrange.shade50,
                        side: BorderSide.none,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.015,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(
    BuildContext context,
    String emoji,
    String label,
    String value,
    double screenWidth,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.02,
          horizontal: screenWidth * 0.02,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: screenWidth * 0.04)),
            SizedBox(height: screenWidth * 0.005),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: screenWidth * 0.025,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(
    Map<String, int> frequency,
    int total,
    double screenWidth,
  ) {
    final colors = [
      Colors.deepOrange.shade300,
      Colors.amber.shade300,
      Colors.teal.shade300,
      Colors.indigo.shade300,
      Colors.pink.shade300,
      Colors.cyan.shade300,
      Colors.lime.shade300,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(screenWidth * 0.01),
      child: SizedBox(
        height: screenWidth * 0.02,
        child: Row(
          children: frequency.entries.toList().asMap().entries.map((entry) {
            final colorIndex = entry.key % colors.length;
            final flex = entry.value.value;
            return Expanded(
              flex: flex,
              child: Container(color: colors[colorIndex]),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    String category,
    int count,
    int total,
    double screenWidth,
  ) {
    final colors = [
      Colors.deepOrange.shade300,
      Colors.amber.shade300,
      Colors.teal.shade300,
      Colors.indigo.shade300,
      Colors.pink.shade300,
    ];

    // 카테고리 색상 index 계산 (순서 기반)
    final categories = FoodInsightService.categoryEmojis.keys.toList();
    final index = categories.indexOf(category) % colors.length;

    final percentage = (count / total * 100).round();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: screenWidth * 0.025,
          height: screenWidth * 0.025,
          decoration: BoxDecoration(
            color: colors[index.clamp(0, colors.length - 1)],
            borderRadius: BorderRadius.circular(screenWidth * 0.005),
          ),
        ),
        SizedBox(width: screenWidth * 0.01),
        Text(
          '$category $percentage%',
          style: TextStyle(
            fontFamily: 'Do Hyeon',
            fontSize: screenWidth * 0.025,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

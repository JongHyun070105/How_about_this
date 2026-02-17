import 'package:flutter/material.dart';
import 'package:review_ai/services/ai_food_insight_service.dart';
import 'package:review_ai/services/food_insight_service.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';

/// 식습관 인사이트 카드 위젯
///
/// 사용자의 식습관 요약 정보를 모노톤 UI로 표시합니다.
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
    if (widget.history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: Colors.grey[800], size: 18),
                const SizedBox(width: 6),
                Text(
                  '나의 식습관 인사이트',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Do Hyeon',
                    fontSize: 15,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(
                    '아직 리뷰 기록이 없어요',
                    style: TextStyle(
                      fontFamily: 'Do Hyeon',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '음식을 선택하고 리뷰를 남기면\nAI가 식습관을 분석해드려요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Do Hyeon',
                      fontSize: 12,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final summary = FoodInsightService.generateSummary(widget.history);
    final categoryFrequency = summary['categoryFrequency'] as Map<String, int>;
    final topFoods = summary['topFoods'] as List<Map<String, dynamic>>;
    final totalReviews = summary['totalReviews'] as int;
    final weeklyCount = summary['weeklyCount'] as int;

    // 로컬 폴백 메시지 (AI 로딩 전 또는 실패 시 사용)
    final String insightMessage = _isLoadingAi
        ? '식습관을 분석하고 있어요...'
        : (_aiInsight?.message ??
              (summary['insightMessage'] as String?) ??
              '식기록을 분석 중입니다.');
    final bool isAi = _aiInsight?.isAi ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(Icons.insights_rounded, color: Colors.grey[800], size: 18),
              const SizedBox(width: 6),
              Text(
                '나의 식습관 인사이트',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Do Hyeon',
                  fontSize: 15,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              // AI 배지
              if (isAi && !_isLoadingAi)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 10),
                      SizedBox(width: 3),
                      Text(
                        'AI',
                        style: TextStyle(
                          fontFamily: 'Do Hyeon',
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 인사이트 메시지
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoadingAi) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    insightMessage,
                    style: TextStyle(
                      fontFamily: 'Do Hyeon',
                      fontSize: 13,
                      height: 1.4,
                      color: _isLoadingAi ? Colors.grey[400] : Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 통계 요약 행
          Row(
            children: [
              _buildStatBadge('📝', '총 리뷰', '$totalReviews개'),
              const SizedBox(width: 6),
              _buildStatBadge('📅', '이번 주', '$weeklyCount개'),
              const SizedBox(width: 6),
              if (categoryFrequency.isNotEmpty)
                _buildStatBadge(
                  FoodInsightService.categoryEmojis[categoryFrequency
                          .keys
                          .first] ??
                      '🍽️',
                  '선호',
                  categoryFrequency.keys.first,
                ),
            ],
          ),

          // Top 음식
          if (topFoods.isNotEmpty && topFoods.first['count'] as int >= 2) ...[
            const SizedBox(height: 10),
            Text(
              '자주 드시는 메뉴',
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 3,
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
                          fontSize: 11,
                          color: Colors.grey[800],
                        ),
                      ),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge(String emoji, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

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
      return const _EmptyInsightCard();
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
          _InsightHeader(isAi: isAi && !_isLoadingAi),
          const SizedBox(height: 10),
          _InsightMessage(message: insightMessage, isLoading: _isLoadingAi),
          const SizedBox(height: 10),
          _StatBadgeRow(
            totalReviews: totalReviews,
            weeklyCount: weeklyCount,
            categoryFrequency: categoryFrequency,
          ),
          if (topFoods.isNotEmpty && topFoods.first['count'] as int >= 2) ...[
            const SizedBox(height: 10),
            _FrequentFoodChips(topFoods: topFoods),
          ],
        ],
      ),
    );
  }
}

class _InsightHeader extends StatelessWidget {
  final bool isAi;
  const _InsightHeader({required this.isAi});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.insights_rounded,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          '나의 식습관 인사이트',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Do Hyeon',
            fontSize: 15,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const Spacer(),
        if (isAi)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 10,
                ),
                const SizedBox(width: 3),
                Text(
                  'AI',
                  style: TextStyle(
                    fontFamily: 'Do Hyeon',
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InsightMessage extends StatelessWidget {
  final String message;
  final bool isLoading;

  const _InsightMessage({required this.message, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).chipTheme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: 13,
                height: 1.4,
                color: isLoading
                    ? Theme.of(context).disabledColor
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadgeRow extends StatelessWidget {
  final int totalReviews;
  final int weeklyCount;
  final Map<String, int> categoryFrequency;

  const _StatBadgeRow({
    required this.totalReviews,
    required this.weeklyCount,
    required this.categoryFrequency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBadge(emoji: '📝', label: '총 리뷰', value: '$totalReviews개'),
        const SizedBox(width: 6),
        _StatBadge(emoji: '📅', label: '이번 주', value: '$weeklyCount개'),
        const SizedBox(width: 6),
        if (categoryFrequency.isNotEmpty)
          _StatBadge(
            emoji:
                FoodInsightService.categoryEmojis[categoryFrequency
                    .keys
                    .first] ??
                '🍽️',
            label: '선호',
            value: categoryFrequency.keys.first,
          ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _StatBadge({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
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
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequentFoodChips extends StatelessWidget {
  final List<Map<String, dynamic>> topFoods;
  const _FrequentFoodChips({required this.topFoods});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '자주 드시는 메뉴',
          style: TextStyle(
            fontFamily: 'Do Hyeon',
            fontSize: 11,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
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
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  backgroundColor: Theme.of(context).chipTheme.backgroundColor,
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _EmptyInsightCard extends StatelessWidget {
  const _EmptyInsightCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '나의 식습관 인사이트',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Do Hyeon',
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).chipTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).dividerColor),
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
                    color: Theme.of(
                      context,
                    ).textTheme.titleSmall?.color?.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '음식을 선택하고 리뷰를 남기면\nAI가 식습관을 분석해드려요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Do Hyeon',
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
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
}

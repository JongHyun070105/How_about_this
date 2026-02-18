import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 카테고리 선호도 페이지 위젯
///
/// 카테고리별 선호도를 파이 차트와 범례로 표시합니다.
class CategoryPageWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  final Map<String, Color> categoryColorMap;

  const CategoryPageWidget({
    super.key,
    required this.stats,
    required this.categoryColorMap,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final categoryList = _buildCategoryList();

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16.0,
        left: 16.0,
        right: 16.0,
        top: 8.0,
      ),
      child: categoryList.isEmpty
          ? _buildEmptyCategoryState(context)
          : _buildCategoryChart(context, screenSize, categoryList),
    );
  }

  List<Map<String, dynamic>> _buildCategoryList() {
    final totalSelections = stats['totalSelections'] ?? 0;
    if (stats['categoryStats'] == null ||
        stats['categoryStats'] is! Map<String, dynamic>) {
      return [];
    }

    final catStats = Map<String, dynamic>.from(stats['categoryStats']);
    final filteredCats = catStats.entries
        .where((e) => e.key != '상관없음' && (e.value ?? 0) > 0)
        .toList();

    final denominator = totalSelections > 0
        ? totalSelections
        : filteredCats.fold<int>(
            0,
            (sum, e) => sum + ((e.value ?? 0) as num).toInt(),
          );

    return filteredCats.map<Map<String, dynamic>>((e) {
      final count = (e.value ?? 0) as int;
      final percent = denominator > 0 ? (count / denominator * 100) : 0.0;
      return {'name': e.key, 'count': count, 'percent': percent};
    }).toList();
  }

  Widget _buildEmptyCategoryState(BuildContext context) {
    return Center(
      child: Text(
        "추천 메뉴에 '좋아요'를 눌러보세요.\n취향을 분석하여 선호도를 알려드릴게요!",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Do Hyeon',
          fontSize: 16,
          color: Theme.of(context).disabledColor,
        ),
      ),
    );
  }

  Widget _buildCategoryChart(
    BuildContext context,
    Size screenSize,
    List<Map<String, dynamic>> categoryList,
  ) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: _buildAnimatedPieChart(context, screenSize, categoryList),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 2,
          child: _buildCategoryLegend(context, screenSize, categoryList),
        ),
      ],
    );
  }

  Widget _buildAnimatedPieChart(
    BuildContext context,
    Size screenSize,
    List<Map<String, dynamic>> categoryList,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, child) {
        return PieChart(
          PieChartData(
            sections: categoryList.map((cat) {
              final percent = cat['percent'] ?? 0.0;
              final color =
                  categoryColorMap[cat['name']] ?? Colors.grey.shade400;
              final shouldShowTitle = percent >= 8.0 && animationValue > 0.8;

              return PieChartSectionData(
                color: color,
                value: percent * animationValue,
                title: shouldShowTitle ? '${percent.toStringAsFixed(0)}%' : '',
                radius: screenSize.width * 0.22,
                titleStyle: TextStyle(
                  fontSize: shouldShowTitle ? (percent >= 15 ? 16 : 14) : 0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onTertiary,
                  fontFamily: 'Do Hyeon',
                ),
                titlePositionPercentageOffset: percent >= 15
                    ? 0.6
                    : (percent >= 8 ? 0.7 : 0.8),
              );
            }).toList(),
            pieTouchData: PieTouchData(enabled: true),
            borderData: FlBorderData(show: false),
            sectionsSpace: 3,
            centerSpaceRadius: screenSize.width * 0.12,
            startDegreeOffset: 270,
          ),
        );
      },
    );
  }

  Widget _buildCategoryLegend(
    BuildContext context,
    Size screenSize,
    List<Map<String, dynamic>> categoryList,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, animationValue, child) {
        return Opacity(
          opacity: animationValue.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.7 + (animationValue.clamp(0.0, 1.0) * 0.3),
            child: _buildLegendContent(context, screenSize, categoryList),
          ),
        );
      },
    );
  }

  Widget _buildLegendContent(
    BuildContext context,
    Size screenSize,
    List<Map<String, dynamic>> categoryList,
  ) {
    return Center(
      child: Column(
        children: [
          Wrap(
            spacing: 12.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: categoryList
                .take(4)
                .map((cat) => _buildLegendItem(context, screenSize, cat))
                .toList(),
          ),
          if (categoryList.length > 4)
            Wrap(
              spacing: 12.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: categoryList
                  .skip(4)
                  .take(3)
                  .map((cat) => _buildLegendItem(context, screenSize, cat))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    Size screenSize,
    Map<String, dynamic> cat,
  ) {
    final color = categoryColorMap[cat['name']] ?? Colors.grey.shade400;
    final percent = cat['percent'] ?? 0.0;

    return Container(
      constraints: BoxConstraints(maxWidth: screenSize.width * 0.25),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cat['name'],
                  style: TextStyle(
                    fontFamily: 'Do Hyeon',
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: 'Do Hyeon',
                    fontSize: 10,
                    color: Theme.of(context).disabledColor,
                    fontWeight: FontWeight.bold,
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

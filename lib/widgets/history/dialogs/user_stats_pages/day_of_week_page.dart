import 'package:flutter/material.dart';

/// 요일별 선호도 페이지 위젯
///
/// 각 요일에 가장 많이 선택한 카테고리와 횟수를 표시합니다.
class DayOfWeekPageWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  final Map<String, Color> categoryColorMap;

  const DayOfWeekPageWidget({
    super.key,
    required this.stats,
    required this.categoryColorMap,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dayOfWeekPrefs = (stats['dayOfWeekPreferences'] as Map?) ?? {};

    if (dayOfWeekPrefs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "아직 요일별 데이터가 없습니다.\n음식을 추천받고 '좋아요'를 눌러보세요!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Do Hyeon',
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    final weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final weekday = index + 1;
          final categoryData = (dayOfWeekPrefs[weekday] as Map?) ?? {};

          if (categoryData.isEmpty) {
            return _buildDayCard(
              screenSize,
              weekdayNames[index],
              '-',
              Colors.grey.shade300,
              0,
            );
          }

          final sortedCategories = categoryData.entries.toList()
            ..sort((a, b) => (b.value as int).compareTo(a.value as int));

          final topCategory = sortedCategories.first.key as String;
          final count = sortedCategories.first.value as int;
          final color = categoryColorMap[topCategory] ?? Colors.grey.shade400;

          return _buildDayCard(
            screenSize,
            weekdayNames[index],
            topCategory,
            color,
            count,
          );
        },
      ),
    );
  }

  Widget _buildDayCard(
    Size screenSize,
    String day,
    String category,
    Color color,
    int count,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.04,
        vertical: screenSize.height * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: screenSize.width * 0.12,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontFamily: 'Do Hyeon',
                  fontSize: screenSize.width * 0.035,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          SizedBox(width: screenSize.width * 0.04),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category == '-' ? '데이터 없음' : category,
                    style: TextStyle(
                      fontFamily: 'Do Hyeon',
                      fontSize: screenSize.width * 0.04,
                      color: category == '-'
                          ? Colors.grey
                          : Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count회',
                      style: TextStyle(
                        fontFamily: 'Do Hyeon',
                        fontSize: screenSize.width * 0.032,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
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

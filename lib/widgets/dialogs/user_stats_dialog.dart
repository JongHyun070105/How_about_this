import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// CustomPainter for leader lines in the pie chart
class LeaderLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  LeaderLinePainter({
    required this.start,
    required this.end,
    required this.color,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// PieChart animation dialog widget for user stats
class AnimatedStatsDialog extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  final Map<String, dynamic> stats;
  final List<dynamic> topFoodsList;
  final int totalTop5Count;
  final List<Map<String, dynamic>> categoryList;
  final Map<String, Color> categoryColorMap;
  final PageController pageController;
  final Widget Function(String, String) buildStatItem;

  const AnimatedStatsDialog({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.stats,
    required this.topFoodsList,
    required this.totalTop5Count,
    required this.categoryList,
    required this.categoryColorMap,
    required this.pageController,
    required this.buildStatItem,
  });

  @override
  State<AnimatedStatsDialog> createState() => _AnimatedStatsDialogState();
}

class _AnimatedStatsDialogState extends State<AnimatedStatsDialog> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = widget.screenWidth;
    final screenHeight = widget.screenHeight;
    final stats = widget.stats;
    final topFoodsList = widget.topFoodsList;
    final totalTop5Count = widget.totalTop5Count;
    final categoryList = widget.categoryList;
    final categoryColorMap = widget.categoryColorMap;
    final buildStatItem = widget.buildStatItem;
    final pageController = widget.pageController;

    return AlertDialog(
      titlePadding: EdgeInsets.only(
        left: screenWidth * 0.05,
        right: screenWidth * 0.02,
        top: screenHeight * 0.025,
        bottom: 0,
      ),
      contentPadding: EdgeInsets.only(
        left: screenWidth * 0.03,
        right: screenWidth * 0.03,
        top: screenHeight * 0.01,
        bottom: screenHeight * 0.01,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '📊 내 식습관 통계',
              style: const TextStyle(fontFamily: 'Do Hyeon'),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: Colors.grey,
              size: screenWidth * 0.05,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ],
      ),
      content: SingleChildScrollView(
        // Added SingleChildScrollView here
        child: SizedBox(
          width: screenWidth * 0.85,
          height: screenHeight * 0.45,
          child: Stack(
            children: [
              PageView(
                controller: pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (int idx) {
                  setState(() {
                    _currentPage = idx;
                  });
                },
                children: [
                  // Page 1: 자주 먹는 음식 TOP 5
                  Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.07),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildStatItem(
                                '총 선택 횟수',
                                '${stats['totalSelections']}회',
                              ),
                              buildStatItem(
                                '최근 30일 선택',
                                '${stats['recentSelections']}회',
                              ),
                              buildStatItem(
                                '만족도',
                                '${stats['likedPercentage'].toStringAsFixed(1)}%',
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                '🏆 자주 먹는 음식 TOP 5',
                                style: TextStyle(
                                  fontFamily: 'Do Hyeon',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 19,
                                ),
                              ),
                              const SizedBox(height: 7),
                              ...topFoodsList.map((food) {
                                int count = (food['count'] as num).toInt();
                                int percent = (totalTop5Count > 0)
                                    ? ((count / totalTop5Count) * 100).round()
                                    : 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '• ${food['name']} ($count회)  $percent%',
                                          style: const TextStyle(
                                            fontFamily: 'Do Hyeon',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      // Arrow indicator at the right, vertically centered to page content
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 2,
                        child:
                            _currentPage <
                                1 // Only show if not on the last page
                            ? IconButton(
                                icon: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: screenWidth * 0.045,
                                  color: Colors.grey.shade400,
                                ),
                                onPressed: () {
                                  pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                },
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                              )
                            : const SizedBox.shrink(), // Hide if on the last page
                      ),
                    ],
                  ),
                  // Page 2: PieChart + Legend (with animation)
                  Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: SingleChildScrollView(
                          // Removed physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 2),
                              const Text(
                                '카테고리별 선호도',
                                style: TextStyle(
                                  fontFamily: 'Do Hyeon',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 148,
                                child:
                                    (_currentPage == 1 &&
                                        categoryList.isNotEmpty)
                                    ? AnimatedPieChart(
                                        categoryList: categoryList,
                                        categoryColorMap: categoryColorMap,
                                      )
                                    : const SizedBox(),
                              ),
                              const SizedBox(height: 22),
                              if (categoryList.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 14,
                                    runSpacing: 6,
                                    children: List.generate(
                                      categoryList.length,
                                      (int i) {
                                        final cat = categoryList[i];
                                        final Color legendColor =
                                            categoryColorMap[cat['name']] ??
                                            Colors.grey.shade400;
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 13,
                                              height: 13,
                                              decoration: BoxDecoration(
                                                color: legendColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            SizedBox(
                                              width: 70,
                                              child: Text(
                                                cat['name'],
                                                style: const TextStyle(
                                                  fontFamily: 'Do Hyeon',
                                                  fontSize: 13,
                                                  color: Colors.black,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: false,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      // Arrow indicator at the LEFT, vertically centered to page content (swipe back)
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 2,
                        child:
                            _currentPage >
                                0 // Only show if not on the first page
                            ? IconButton(
                                icon: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: screenWidth * 0.045,
                                  color: Colors.grey.shade400,
                                ),
                                onPressed: () {
                                  pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                },
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                              )
                            : const SizedBox.shrink(), // Hide if on the first page
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// PieChart animation widget for user stats page
class AnimatedPieChart extends StatefulWidget {
  final List<Map<String, dynamic>> categoryList;
  final Map<String, Color> categoryColorMap;
  const AnimatedPieChart({
    super.key,
    required this.categoryList,
    required this.categoryColorMap,
  });

  @override
  State<AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<AnimatedPieChart>
    with TickerProviderStateMixin {
  late AnimationController _pieController;
  late AnimationController _percentTextController;
  late Animation<double> _pieAnimation;
  late Animation<double> _percentTextAnimation;

  @override
  void initState() {
    super.initState();
    _pieController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _pieAnimation = CurvedAnimation(
      parent: _pieController,
      curve: Curves.easeOutCubic,
    );
    _percentTextController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _percentTextAnimation = CurvedAnimation(
      parent: _percentTextController,
      curve: Curves.easeOutCubic,
    );
    _pieAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _percentTextController.forward();
      }
    });
    // Start the pie animation on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pieController.forward();
    });
  }

  @override
  void dispose() {
    _pieController.dispose();
    _percentTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryList = widget.categoryList;
    final categoryColorMap = widget.categoryColorMap;
    return AnimatedBuilder(
      animation: Listenable.merge([_pieAnimation, _percentTextAnimation]),
      builder: (context, child) {
        double animationValue = _pieAnimation.value;
        double percentTextValue = _percentTextAnimation.value;
        List<PieChartSectionData> sections = [];
        for (int i = 0; i < categoryList.length; i++) {
          final cat = categoryList[i];
          final percent = cat['percent'] as double;
          final percentValue = percent > 0 ? percent : 0.01;
          final double animatedValue = percentValue * animationValue;
          final int animatedPercent = (animationValue < 1.0)
              ? 0
              : (percentTextValue * percent).round();
          String percentStr = '$animatedPercent%';
          final Color sectionColor =
              categoryColorMap[cat['name']] ?? Colors.grey.shade400;
          sections.add(
            PieChartSectionData(
              value: animatedValue,
              color: sectionColor,
              showTitle: true,
              title: percentStr,
              titleStyle: const TextStyle(
                fontFamily: 'Do Hyeon',
                color: Color(0xFF000000),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              titlePositionPercentageOffset: 0.65,
              radius: 52,
            ),
          );
        }
        return PieChart(
          PieChartData(
            sections: sections,
            sectionsSpace: 3,
            centerSpaceRadius: 32,
            startDegreeOffset: 180,
          ),
        );
      },
    );
  }
}

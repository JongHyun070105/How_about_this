import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:review_ai/main.dart';
import 'package:review_ai/providers/food_providers.dart';
import 'package:review_ai/services/recommendation_service.dart';

class UserStatsDialog extends ConsumerStatefulWidget {
  const UserStatsDialog({super.key});

  @override
  ConsumerState<UserStatsDialog> createState() => _UserStatsDialogState();
}

class _UserStatsDialogState extends ConsumerState<UserStatsDialog> {
  PageController pageController = PageController();
  int currentPage = 0;
  Map<String, dynamic>? stats;
  int _remainingRecommendations = 0;
  int _remainingReviews = 0;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      final loadedStats = await RecommendationService.getUserStats();
      final usageTrackingService = ref.read(usageTrackingServiceProvider);
      final remainingRecs = await usageTrackingService
          .getRemainingRecommendationCount();
      final remainingRev = await usageTrackingService.getRemainingReviewCount();

      setState(() {
        stats = loadedStats;
        _remainingRecommendations = remainingRecs;
        _remainingReviews = remainingRev;
        isLoading = false;
      });
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e) {
      setState(() {
        errorMessage = '통계를 불러오는데 실패했습니다: $e';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 768;

    if (isLoading) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.3,
            minWidth: screenWidth * 0.6,
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (errorMessage != null) {
      return AlertDialog(
        title: const Text('오류'),
        content: Text(errorMessage!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      );
    }

    if (stats == null) {
      return AlertDialog(
        title: const Text('데이터 없음'),
        content: const Text('통계 데이터를 불러올 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      );
    }

    final foodCategories = ref.watch(foodCategoriesProvider);
    final Map<String, Color> categoryColorMap = {
      for (final cat in foodCategories) cat.name: cat.color,
    };

    List<Map<String, dynamic>> categoryList = [];
    int totalSelections = stats!['totalSelections'] ?? 0;
    if (stats!['categoryStats'] != null &&
        stats!['categoryStats'] is Map<String, dynamic>) {
      final Map<String, dynamic> catStats = Map<String, dynamic>.from(
        stats!['categoryStats'],
      );
      final filteredCats = catStats.entries
          .where((e) => e.key != '상관없음' && (e.value ?? 0) > 0)
          .toList();
      int denominator = totalSelections > 0
          ? totalSelections
          : filteredCats.fold<int>(
              0,
              (sum, e) => sum + ((e.value ?? 0) as num).toInt(),
            );
      categoryList = filteredCats.map<Map<String, dynamic>>((e) {
        int count = (e.value ?? 0) as int;
        double percent = denominator > 0 ? (count / denominator * 100) : 0.0;
        return {'name': e.key, 'count': count, 'percent': percent};
      }).toList();
    }

    final List<dynamic> topFoodsList = (stats!['topFoods'] as List)
        .take(5)
        .toList();

    final int maxRecommendations = 20;
    final int maxReviews = 5;
    int usedRecommendations = (maxRecommendations - _remainingRecommendations)
        .clamp(0, maxRecommendations);
    int usedReviews = (maxReviews - _remainingReviews).clamp(0, maxReviews);

    final usageTextStyle = TextStyle(
      fontFamily: 'Do Hyeon',
      fontSize: (screenWidth * 0.037).clamp(13.0, 18.0),
      color: Colors.grey[700],
      fontWeight: FontWeight.w500,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.62,
          minWidth: screenWidth * 0.8,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 8.0,
                    top: 8.0,
                    bottom: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        width: 48, // Balance for close button
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_left, size: 24),
                              onPressed: () {
                                if (pageController.hasClients &&
                                    currentPage > 0) {
                                  pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.ease,
                                  );
                                  setState(() {
                                    currentPage = currentPage - 1;
                                  });
                                }
                              },
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),
                            Text(
                              currentPage == 0 ? "통계" : "카테고리별 선호도",
                              style: TextStyle(
                                fontFamily: 'Do Hyeon',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_right, size: 24),
                              onPressed: () {
                                if (pageController.hasClients &&
                                    currentPage < 1) {
                                  pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.ease,
                                  );
                                  setState(() {
                                    currentPage = currentPage + 1;
                                  });
                                }
                              },
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: pageController,
                    onPageChanged: (idx) {
                      setState(() {
                        currentPage = idx;
                      });
                    },
                    children: [
                      // Page 0: Statistics
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildStatItem(
                              screenWidth,
                              isTablet,
                              "총 선택 횟수",
                              "${stats!['totalSelections']}회",
                            ),
                            _buildStatItem(
                              screenWidth,
                              isTablet,
                              "최근 30일 선택",
                              "${stats!['recentSelections']}회",
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: (screenWidth * 0.02).clamp(
                                  8.0,
                                  16.0,
                                ),
                              ),
                              child: const Text(
                                "🏆 자주 먹는 음식 TOP 5",
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
                              itemCount: topFoodsList.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final food = topFoodsList[index];
                                return _buildStatItem(
                                  screenWidth,
                                  isTablet,
                                  food['name'],
                                  "${food['count']}회",
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildUsageIndicator(
                              screenWidth,
                              label: "음식 추천 사용량",
                              used: usedRecommendations,
                              max: maxRecommendations,
                              color: Colors.blue.shade400,
                              style: usageTextStyle,
                            ),
                            const SizedBox(height: 12),
                            _buildUsageIndicator(
                              screenWidth,
                              label: "리뷰 사용량",
                              used: usedReviews,
                              max: maxReviews,
                              color: Colors.green.shade400,
                              style: usageTextStyle,
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: (screenWidth * 0.02).clamp(
                                  8.0,
                                  16.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    "현재 시간: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(
                                      fontFamily: 'Do Hyeon',
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Page 1: Category Preference Chart
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: 16.0,
                          left: 16.0,
                          right: 16.0,
                          top: 8.0,
                        ),
                        child: Column(
                          children: [
                            if (categoryList.isEmpty)
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    "아직 데이터가 없어요.\n리뷰를 작성해서 통계를 확인해보세요!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Do Hyeon',
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              Expanded(
                                flex: 5,
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 2000),
                                  tween: Tween<double>(begin: 0, end: 1),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, animationValue, child) {
                                    return PieChart(
                                      PieChartData(
                                        sections: categoryList.asMap().entries.map((
                                          entry,
                                        ) {
                                          final cat = entry.value;
                                          final double percent =
                                              cat['percent'] ?? 0.0;
                                          final color =
                                              categoryColorMap[cat['name']] ??
                                              Colors.grey.shade400;

                                          double adjustedProgress =
                                              animationValue;

                                          bool shouldShowTitle =
                                              percent >= 8.0 &&
                                              animationValue > 0.8;

                                          return PieChartSectionData(
                                            color: color,
                                            value: percent * adjustedProgress,
                                            title: shouldShowTitle
                                                ? '${percent.toStringAsFixed(0)}%'
                                                : '',
                                            radius: screenWidth * 0.22,
                                            titleStyle: TextStyle(
                                              fontSize: shouldShowTitle
                                                  ? (percent >= 15 ? 16 : 14)
                                                  : 0,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontFamily: 'Do Hyeon',
                                            ),
                                            titlePositionPercentageOffset:
                                                percent >= 15
                                                ? 0.6
                                                : (percent >= 8 ? 0.7 : 0.8),
                                          );
                                        }).toList(),
                                        pieTouchData: PieTouchData(
                                          enabled: true,
                                          touchCallback:
                                              (
                                                FlTouchEvent event,
                                                pieTouchResponse,
                                              ) {
                                                // 터치 시 추가 정보 표시 가능
                                              },
                                        ),
                                        borderData: FlBorderData(show: false),
                                        sectionsSpace: 3,
                                        centerSpaceRadius: screenWidth * 0.12,
                                        startDegreeOffset: 270,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                flex: 2,
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 1500),
                                  tween: Tween<double>(begin: 0, end: 1),
                                  curve: Curves.easeOutBack,
                                  builder: (context, animationValue, child) {
                                    double clampedValue = animationValue.clamp(
                                      0.0,
                                      1.0,
                                    );
                                    return Opacity(
                                      opacity: clampedValue,
                                      child: Transform.scale(
                                        scale: 0.7 + (clampedValue * 0.3),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Wrap(
                                                spacing: 12.0,
                                                runSpacing: 8.0,
                                                alignment: WrapAlignment.center,
                                                children: categoryList.take(4).map((
                                                  cat,
                                                ) {
                                                  final color =
                                                      categoryColorMap[cat['name']] ??
                                                      Colors.grey.shade400;
                                                  final percent =
                                                      cat['percent'] ?? 0.0;
                                                  return Container(
                                                    constraints: BoxConstraints(
                                                      maxWidth:
                                                          screenWidth * 0.25,
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 12,
                                                          height: 12,
                                                          decoration: BoxDecoration(
                                                            color: color,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  2,
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Flexible(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                cat['name'],
                                                                style: const TextStyle(
                                                                  fontFamily:
                                                                      'Do Hyeon',
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .black87,
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              Text(
                                                                '${percent.toStringAsFixed(0)}%',
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Do Hyeon',
                                                                  fontSize: 10,
                                                                  color: Colors
                                                                      .grey[600],
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                              if (categoryList.length > 4)
                                                Wrap(
                                                  spacing: 12.0,
                                                  runSpacing: 8.0,
                                                  alignment:
                                                      WrapAlignment.center,
                                                  children: categoryList.skip(4).take(3).map((
                                                    cat,
                                                  ) {
                                                    final color =
                                                        categoryColorMap[cat['name']] ??
                                                        Colors.grey.shade400;
                                                    final percent =
                                                        cat['percent'] ?? 0.0;
                                                    return Container(
                                                      constraints:
                                                          BoxConstraints(
                                                            maxWidth:
                                                                screenWidth *
                                                                0.25,
                                                          ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 12,
                                                            height: 12,
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: color,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        2,
                                                                      ),
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Flexible(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Text(
                                                                  cat['name'],
                                                                  style: const TextStyle(
                                                                    fontFamily:
                                                                        'Do Hyeon',
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                                Text(
                                                                  '${percent.toStringAsFixed(0)}%',
                                                                  style: TextStyle(
                                                                    fontFamily:
                                                                        'Do Hyeon',
                                                                    fontSize:
                                                                        10,
                                                                    color: Colors
                                                                        .grey[600],
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(
    double screenWidth,
    bool isTablet,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: (MediaQuery.of(context).size.height * 0.008).clamp(4.0, 8.0),
        horizontal: (screenWidth * 0.02).clamp(8.0, 16.0),
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
                fontSize: (screenWidth * (isTablet ? 0.025 : 0.035)).clamp(
                  12.0,
                  18.0,
                ),
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          SizedBox(width: (screenWidth * 0.04).clamp(12.0, 20.0)),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: (screenWidth * (isTablet ? 0.028 : 0.038)).clamp(
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
    double screenWidth, {
    required String label,
    required int used,
    required int max,
    required Color color,
    required TextStyle style,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: (screenWidth * 0.02).clamp(8.0, 16.0),
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

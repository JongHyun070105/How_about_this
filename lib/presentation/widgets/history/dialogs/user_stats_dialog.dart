import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/presentation/providers/app_providers.dart';
import 'package:review_ai/presentation/providers/food_providers.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';

import 'package:review_ai/services/recommendation_service.dart';
import 'package:review_ai/presentation/widgets/history/dialogs/user_stats_pages/stats_page.dart';
import 'package:review_ai/presentation/widgets/history/dialogs/user_stats_pages/category_page.dart';

/// 사용자 통계 다이얼로그
///
/// 3개의 페이지로 구성:
/// - 통계 페이지 (선택 횟수, TOP 5, 사용량)
/// - 카테고리별 선호도 페이지 (파이 차트)
class UserStatsDialog extends ConsumerStatefulWidget {
  const UserStatsDialog({super.key});

  @override
  ConsumerState<UserStatsDialog> createState() => _UserStatsDialogState();
}

class _UserStatsDialogState extends ConsumerState<UserStatsDialog> {
  late final PageController _pageController;
  int _currentPage = 0;
  Map<String, dynamic>? _stats;
  int _remainingRecommendations = 0;
  int _remainingReviews = 0;
  bool _isLoading = true;
  String? _errorMessage;

  static const int maxRecommendations = 40;
  static const int maxReviews = 5;
  static const int maxPages = 2;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      final loadedStats = await RecommendationService.getUserStats();
      final usageTrackingService = ref.read(usageTrackingServiceProvider);
      final remainingRecs = await usageTrackingService
          .getRemainingRecommendationCount();
      final remainingRev = await usageTrackingService.getRemainingReviewCount();

      if (mounted) {
        setState(() {
          _stats = loadedStats;
          _remainingRecommendations = remainingRecs;
          _remainingReviews = remainingRev;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '통계를 불러오는데 실패했습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPage(int page) {
    if (page < 0 || page >= maxPages) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  /// 카테고리 색상 맵 생성
  Map<String, Color> _buildCategoryColorMap() {
    final foodCategories = ref.watch(foodCategoriesProvider);
    return <String, Color>{
      for (final cat in foodCategories) cat.name: cat.color,
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (_isLoading) return _buildLoadingDialog();
    if (_errorMessage != null) return _buildErrorDialog(_errorMessage!);
    if (_stats == null) return _buildErrorDialog('통계 데이터를 불러올 수 없습니다.');

    final categoryColorMap = _buildCategoryColorMap();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.62,
          minWidth: screenSize.width * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  StatsPageWidget(
                    stats: _stats!,
                    remainingRecommendations: _remainingRecommendations,
                    remainingReviews: _remainingReviews,
                    maxRecommendations: maxRecommendations,
                    maxReviews: maxReviews,
                    history: ref.watch(reviewHistoryProvider),
                  ),
                  CategoryPageWidget(
                    stats: _stats!,
                    categoryColorMap: categoryColorMap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDialog() {
    return const Dialog(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator.adaptive(),
            SizedBox(width: 20),
            Text('불러오는 중...', style: TextStyle(fontFamily: 'Do Hyeon')),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDialog(String message) {
    return CupertinoAlertDialog(
      title: const Text(
        '오류',
        style: TextStyle(fontFamily: 'Do Hyeon', fontWeight: FontWeight.bold),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Text(
          message,
          style: const TextStyle(fontFamily: 'Do Hyeon', fontSize: 16),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인', style: TextStyle(fontFamily: 'Do Hyeon')),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 8.0,
        top: 8.0,
        bottom: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left, size: 24),
                  onPressed: _currentPage > 0
                      ? () => _navigateToPage(_currentPage - 1)
                      : null,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                Expanded(
                  child: Text(
                    _currentPage == 0 ? '통계' : '카테고리별 선호도',
                    style: TextStyle(
                      fontFamily: 'Do Hyeon',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleSmall?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right, size: 24),
                  onPressed: _currentPage < maxPages - 1
                      ? () => _navigateToPage(_currentPage + 1)
                      : null,
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
    );
  }
}

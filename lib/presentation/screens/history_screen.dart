import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/presentation/widgets/history/empty_history.dart';
import 'package:review_ai/presentation/widgets/history/history_card.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';
import 'package:review_ai/presentation/widgets/history/filter_options_sheet.dart';
import 'package:review_ai/presentation/widgets/history/history_search_filter.dart';

enum HistorySortOption { latest, oldest, ratingHigh, ratingLow }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  HistorySortOption _sortOption = HistorySortOption.latest;
  int? _ratingFilter;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String getSortOptionLabel(HistorySortOption option) {
    switch (option) {
      case HistorySortOption.latest:
        return '최신순';
      case HistorySortOption.oldest:
        return '오래된순';
      case HistorySortOption.ratingHigh:
        return '별점 높은순';
      case HistorySortOption.ratingLow:
        return '별점 낮은순';
    }
  }

  double getAverageRating(ReviewHistoryEntry entry) {
    return (entry.deliveryRating +
            entry.tasteRating +
            entry.portionRating +
            entry.priceRating) /
        4;
  }

  void _showFilterOptionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).dialogTheme.backgroundColor ??
                Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16, // 수동으로 하단 패딩 추가
          ),
          child: FilterOptionsSheet(
            currentSortOption: _sortOption,
            currentRatingFilter: _ratingFilter,
          ),
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          _sortOption = result['sortOption'];
          _ratingFilter = result['ratingFilter'];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(reviewHistoryProvider);
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final filteredHistory = history.where((entry) {
      final foodName = entry.foodName.toLowerCase();
      final query = _searchQuery.toLowerCase();
      final averageRating = getAverageRating(entry);

      final searchMatch = foodName.contains(query);
      final ratingMatch =
          _ratingFilter == null ||
          (averageRating >= _ratingFilter! &&
              averageRating < _ratingFilter! + 1);

      return searchMatch && ratingMatch;
    }).toList();

    final sortedHistory = [...filteredHistory];
    sortedHistory.sort((a, b) {
      switch (_sortOption) {
        case HistorySortOption.latest:
          return b.createdAt.compareTo(a.createdAt);
        case HistorySortOption.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case HistorySortOption.ratingHigh:
          return getAverageRating(b).compareTo(getAverageRating(a));
        case HistorySortOption.ratingLow:
          return getAverageRating(a).compareTo(getAverageRating(b));
      }
    });

    // Responsive calculations
    final isTablet = screenWidth >= 768;

    // Dynamic font sizes
    final appBarFontSize = (screenWidth * (isTablet ? 0.032 : 0.05)).clamp(
      16.0,
      28.0,
    );

    // Dynamic spacing
    final horizontalPadding = (screenWidth * (isTablet ? 0.06 : 0.04)).clamp(
      16.0,
      48.0,
    );
    final verticalSpacing = (screenHeight * (isTablet ? 0.025 : 0.02)).clamp(
      12.0,
      24.0,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          '히스토리',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: appBarFontSize,
            fontFamily: 'Do Hyeon',
          ),
        ),
        centerTitle: true,
        elevation: 0,
        // Responsive leading button
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: (screenWidth * (isTablet ? 0.04 : 0.06)).clamp(20.0, 32.0),
          ),
          onPressed: () => Navigator.of(context).pop(),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ),
      // SafeArea를 body 전체에 적용하고 하단 패딩 조정
      body: SafeArea(
        bottom: true, // 하단 SafeArea 활성화
        child: Column(
          children: [
            // 상단 검색 및 필터 영역
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: verticalSpacing),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: HistorySearchBar(
                      controller: _searchController,
                      screenWidth: screenWidth,
                      onFilterTap: _showFilterOptionsSheet,
                    ),
                  ),
                  HistoryFilterChips(
                    searchQuery: _searchQuery,
                    sortOption: _sortOption,
                    ratingFilter: _ratingFilter,
                    screenWidth: screenWidth,
                    onClearSearch: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                    onClearSort: () {
                      setState(() {
                        _sortOption = HistorySortOption.latest;
                      });
                    },
                    onClearRating: () {
                      setState(() {
                        _ratingFilter = null;
                      });
                    },
                    getSortOptionLabel: getSortOptionLabel,
                  ),
                  SizedBox(height: verticalSpacing),
                ],
              ),
            ),
            // 히스토리 리스트 영역 - Expanded로 남은 공간 차지
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: sortedHistory.isEmpty
                    ? EmptyHistory(
                        title:
                            (_searchQuery.isNotEmpty || _ratingFilter != null)
                            ? '검색 결과가 없습니다.'
                            : '아직 생성된 리뷰가 없습니다.',
                        message:
                            (_searchQuery.isNotEmpty || _ratingFilter != null)
                            ? '다른 검색어 혹은 필터 설정을 시도해보세요!'
                            : '메인 화면에서 첫 리뷰를 작성해보세요!',
                        icon: (_searchQuery.isNotEmpty || _ratingFilter != null)
                            ? Icons.search_off
                            : Icons.history_toggle_off,
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          return ref.refresh(reviewHistoryProvider);
                        },
                        color: Theme.of(context).primaryColor,
                        backgroundColor: Theme.of(context).cardColor,
                        strokeWidth: isTablet ? 3.0 : 2.5,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          // 히스토리 항목
                          itemCount: sortedHistory.length,
                          // 하단에 충분한 패딩 추가 - 키보드와 시스템 UI 고려
                          padding: EdgeInsets.only(
                            bottom: keyboardHeight > 0
                                ? keyboardHeight + 20
                                : (screenHeight * 0.02).clamp(12.0, 20.0) +
                                      bottomPadding,
                          ),
                          itemBuilder: (context, index) {
                            final entry = sortedHistory[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    (screenHeight * (isTablet ? 0.015 : 0.01))
                                        .clamp(8.0, 16.0),
                              ),
                              child: AnimatedContainer(
                                duration: Duration(
                                  milliseconds: 300 + (index * 50),
                                ),
                                curve: Curves.easeOutCubic,
                                child: HistoryCard(entry: entry),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

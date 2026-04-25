import 'package:flutter/material.dart';
import 'package:review_ai/presentation/screens/history_screen.dart';

class HistorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final double screenWidth;
  final VoidCallback onFilterTap;

  const HistorySearchBar({
    super.key,
    required this.controller,
    required this.screenWidth,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha((255 * 0.05).round()),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: '음식 이름으로 검색',
                  prefixIcon: const Icon(Icons.search),
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontFamily: 'Do Hyeon',
                    fontSize: (screenWidth * 0.035).clamp(12.0, 16.0),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                ),
                style: TextStyle(
                  fontFamily: 'Do Hyeon',
                  fontSize: (screenWidth * 0.04).clamp(14.0, 18.0),
                ),
              ),
            ),
          ),
          SizedBox(
            width:
                (screenWidth * (screenWidth >= 768 ? 0.06 : 0.04)).clamp(
                  16.0,
                  48.0,
                ) *
                0.2,
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              size: (screenWidth * 0.06).clamp(24.0, 36.0),
            ),
            onPressed: onFilterTap,
            tooltip: '필터 및 정렬',
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class HistoryFilterChips extends StatelessWidget {
  final String searchQuery;
  final HistorySortOption sortOption;
  final int? ratingFilter;
  final double screenWidth;
  final VoidCallback onClearSearch;
  final VoidCallback onClearSort;
  final VoidCallback onClearRating;
  final String Function(HistorySortOption) getSortOptionLabel;

  const HistoryFilterChips({
    super.key,
    required this.searchQuery,
    required this.sortOption,
    required this.ratingFilter,
    required this.screenWidth,
    required this.onClearSearch,
    required this.onClearSort,
    required this.onClearRating,
    required this.getSortOptionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Visibility(
      visible:
          searchQuery.isNotEmpty ||
          sortOption != HistorySortOption.latest ||
          ratingFilter != null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            if (searchQuery.isNotEmpty)
              Chip(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                label: Text(
                  '검색: $searchQuery',
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Do Hyeon',
                  ),
                ),
                shape: RoundedRectangleBorder(
                  side: BorderSide.none,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                onDeleted: onClearSearch,
                deleteIconColor: Theme.of(context).iconTheme.color,
              ),
            if (sortOption != HistorySortOption.latest)
              Chip(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                label: Text(
                  '정렬: ${getSortOptionLabel(sortOption)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Do Hyeon',
                  ),
                ),
                shape: RoundedRectangleBorder(
                  side: BorderSide.none,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                onDeleted: onClearSort,
                deleteIconColor: Theme.of(context).iconTheme.color,
              ),
            if (ratingFilter != null)
              Chip(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    ratingFilter!,
                    (index) =>
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                  ),
                ),
                shape: RoundedRectangleBorder(
                  side: BorderSide.none,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                onDeleted: onClearRating,
                deleteIconColor: Theme.of(context).iconTheme.color,
              ),
          ],
        ),
      ),
    );
  }
}

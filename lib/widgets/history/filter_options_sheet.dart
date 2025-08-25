import 'package:flutter/material.dart';
import 'package:review_ai/screens/history_screen.dart'; // For HistorySortOption enum

class FilterOptionsSheet extends StatefulWidget {
  final HistorySortOption currentSortOption;
  final int? currentRatingFilter;

  const FilterOptionsSheet({
    super.key,
    required this.currentSortOption,
    required this.currentRatingFilter,
  });

  @override
  State<FilterOptionsSheet> createState() => _FilterOptionsSheetState();
}

class _FilterOptionsSheetState extends State<FilterOptionsSheet> {
  late HistorySortOption _selectedSortOption;
  late int? _selectedRatingFilter;

  @override
  void initState() {
    super.initState();
    _selectedSortOption = widget.currentSortOption;
    _selectedRatingFilter = widget.currentRatingFilter;
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '정렬',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Do Hyeon',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: HistorySortOption.values.map((option) {
              final isSelected = _selectedSortOption == option;
              return ChoiceChip(
                label: Text(getSortOptionLabel(option)),
                selected: isSelected,
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedSortOption = option;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            '별점 필터',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Do Hyeon',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final isSelected = _selectedRatingFilter == rating;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(rating, (starIndex) => const Icon(Icons.star, color: Colors.amber, size: 18)),
                ),
                selected: isSelected,
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                onSelected: (selected) {
                  setState(() {
                    _selectedRatingFilter = selected ? rating : null;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'sortOption': _selectedSortOption,
                  'ratingFilter': _selectedRatingFilter,
                });
              },
              child: const Text('적용'),
            ),
          ),
        ],
      ),
    );
  }
}

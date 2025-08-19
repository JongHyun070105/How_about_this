import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 리뷰 기록 항목을 위한 데이터 모델
class ReviewHistoryEntry {
  final String foodName;
  final String? imagePath; // 이미지 파일 경로
  final double deliveryRating;
  final double tasteRating;
  final double portionRating;
  final double priceRating;
  final String reviewStyle;
  final String? emphasis;
  final List<String> generatedReviews;
  final DateTime createdAt;

  ReviewHistoryEntry({
    required this.foodName,
    this.imagePath,
    required this.deliveryRating,
    required this.tasteRating,
    required this.portionRating,
    required this.priceRating,
    required this.reviewStyle,
    this.emphasis,
    required this.generatedReviews,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // JSON 직렬화 (안전하게)
  Map<String, dynamic> toJson() => {
    'foodName': foodName,
    'imagePath': imagePath,
    'deliveryRating': deliveryRating.toString(), // double을 string으로 안전하게 저장
    'tasteRating': tasteRating.toString(),
    'portionRating': portionRating.toString(),
    'priceRating': priceRating.toString(),
    'reviewStyle': reviewStyle,
    'emphasis': emphasis,
    'generatedReviews': generatedReviews,
    'createdAt': createdAt.millisecondsSinceEpoch.toString(),
  };

  // JSON 역직렬화 (안전하게)
  factory ReviewHistoryEntry.fromJson(Map<String, dynamic> json) {
    try {
      return ReviewHistoryEntry(
        foodName: json['foodName']?.toString() ?? '',
        imagePath: json['imagePath']?.toString(),
        deliveryRating: _safeParseDouble(json['deliveryRating']),
        tasteRating: _safeParseDouble(json['tasteRating']),
        portionRating: _safeParseDouble(json['portionRating']),
        priceRating: _safeParseDouble(json['priceRating']),
        reviewStyle: json['reviewStyle']?.toString() ?? '일반',
        emphasis: json['emphasis']?.toString(),
        generatedReviews: _safeParseList(json['generatedReviews']),
        createdAt: _safeParseDateTime(json['createdAt']),
      );
    } catch (e) {
      print('Error parsing ReviewHistoryEntry: $e');
      // 기본값으로 반환하여 앱이 크래시되지 않도록 함
      return ReviewHistoryEntry(
        foodName: '오류 발생',
        deliveryRating: 0.0,
        tasteRating: 0.0,
        portionRating: 0.0,
        priceRating: 0.0,
        reviewStyle: '일반',
        generatedReviews: ['데이터를 불러올 수 없습니다.'],
      );
    }
  }

  // 안전한 double 파싱
  static double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing double: $value, error: $e');
        return 0.0;
      }
    }
    return 0.0;
  }

  // 안전한 List 파싱
  static List<String> _safeParseList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String) {
      try {
        final decoded = json.decode(value);
        if (decoded is List) {
          return decoded.map((item) => item.toString()).toList();
        }
      } catch (e) {
        print('Error parsing list: $value, error: $e');
      }
    }
    return [];
  }

  // 안전한 DateTime 파싱
  static DateTime _safeParseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        final milliseconds = int.parse(value);
        return DateTime.fromMillisecondsSinceEpoch(milliseconds);
      } catch (e) {
        print('Error parsing DateTime: $value, error: $e');
        return DateTime.now();
      }
    }
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        print('Error parsing DateTime from int: $value, error: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

// 1. 선택된 이미지를 관리하는 Provider
final imageProvider = StateProvider<File?>((ref) => null);

// 2. 음식 이름 텍스트를 관리하는 Provider
final foodNameProvider = StateProvider<String>((ref) => '');

// 3. 강조하고 싶은 내용을 관리하는 Provider
final emphasisProvider = StateProvider<String>((ref) => '');

// 4. 별점을 관리하는 Provider들
final deliveryRatingProvider = StateProvider<double>((ref) => 0.0);
final tasteRatingProvider = StateProvider<double>((ref) => 0.0);
final portionRatingProvider = StateProvider<double>((ref) => 0.0);
final priceRatingProvider = StateProvider<double>((ref) => 0.0);

// 5. 리뷰 스타일 리스트 Provider
final reviewStylesProvider = Provider<List<String>>(
  (ref) => ['재미있게', '전문가처럼', '간결하게', 'SNS 스타일', '감성적으로'],
);

// 6. 선택된 리뷰 스타일을 관리하는 Provider
final selectedReviewStyleProvider = StateProvider<String>((ref) {
  // 기본값으로 첫 번째 스타일을 선택 (ref.watch 사용 없이 직접 초기화)
  const defaultStyles = ['재미있게', '전문가처럼', '간결하게', 'SNS 스타일', '감성적으로'];
  return defaultStyles.first;
});

// 7. 리뷰 생성 로딩 상태를 관리하는 Provider
final reviewLoadingProvider = StateProvider<bool>((ref) => false);

// 8. 생성된 리뷰 리스트를 관리하는 Provider
final generatedReviewsProvider = StateProvider<List<String>>((ref) => []);

// 9. 리뷰 기록을 관리하는 StateNotifier 및 Provider
class ReviewHistoryNotifier extends StateNotifier<List<ReviewHistoryEntry>> {
  ReviewHistoryNotifier() : super([]) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('review_history_v2');

      if (historyJson == null || historyJson.isEmpty) {
        print('No history found in SharedPreferences');
        state = [];
        return;
      }

      print(
        'Loading history: ${historyJson.substring(0, historyJson.length > 100 ? 100 : historyJson.length)}...',
      );

      final List<dynamic> historyList = json.decode(historyJson);
      final List<ReviewHistoryEntry> entries = [];

      for (int i = 0; i < historyList.length; i++) {
        try {
          final entry = ReviewHistoryEntry.fromJson(historyList[i]);
          entries.add(entry);
        } catch (e) {
          print('Error parsing entry at index $i: $e');
          continue;
        }
      }

      state = entries;
    } catch (e) {
      print('Error loading review history: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('reviewHistory'); // 기존 키
        await prefs.remove('review_history_v2'); // 새로운 키
        print('Cleared corrupted review history');
      } catch (clearError) {
        print('Error clearing history: $clearError');
      }
      state = [];
    }
  }

  // 중복 저장 방지를 위한 addReview 메서드 수정
  Future<void> addReview(ReviewHistoryEntry newEntry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<ReviewHistoryEntry> currentHistory = [...state];

      // 중복 체크: 같은 시간대(1분 이내)에 같은 음식명과 리뷰 내용이 있는지 확인
      final now = DateTime.now();
      bool isDuplicate = currentHistory.any((entry) {
        final timeDiff = now.difference(entry.createdAt).inMinutes;
        return timeDiff <= 1 && // 1분 이내
            entry.foodName == newEntry.foodName &&
            entry.generatedReviews.length == newEntry.generatedReviews.length &&
            entry.generatedReviews.every(
              (review) => newEntry.generatedReviews.contains(review),
            );
      });

      if (!isDuplicate) {
        currentHistory.add(newEntry);

        // 최대 50개까지만 저장
        if (currentHistory.length > 50) {
          currentHistory.removeRange(0, currentHistory.length - 50);
        }

        final historyJson = json.encode(
          currentHistory.map((entry) => entry.toJson()).toList(),
        );
        await prefs.setString('review_history_v2', historyJson);

        state = currentHistory;
        print('Successfully saved review history');
      } else {
        print('Duplicate review entry detected, not adding to history.');
      }
    } catch (e) {
      print('Error adding review to history: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('reviewHistory'); // 기존 키
      await prefs.remove('review_history_v2'); // 새로운 키
      state = [];
      print('Successfully cleared all review history');
    } catch (e) {
      print('Error clearing review history: $e');
    }
  }
}

final reviewHistoryProvider =
    StateNotifierProvider<ReviewHistoryNotifier, List<ReviewHistoryEntry>>(
      (ref) => ReviewHistoryNotifier(),
    );
// 모든 Provider를 초기화하는 함수
void resetAllProviders(WidgetRef ref) {
  ref.read(imageProvider.notifier).state = null;
  ref.read(foodNameProvider.notifier).state = '';
  ref.read(emphasisProvider.notifier).state = '';
  ref.read(deliveryRatingProvider.notifier).state = 0.0;
  ref.read(tasteRatingProvider.notifier).state = 0.0;
  ref.read(portionRatingProvider.notifier).state = 0.0;
  ref.read(priceRatingProvider.notifier).state = 0.0;
  ref.read(selectedReviewStyleProvider.notifier).state = ref
      .read(reviewStylesProvider)
      .first;
  ref.read(reviewLoadingProvider.notifier).state = false;
  ref.read(generatedReviewsProvider.notifier).state = [];
}

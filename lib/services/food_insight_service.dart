import 'dart:math';
import 'package:review_ai/providers/review_provider.dart';

/// 식습관 분석 서비스
///
/// 리뷰 히스토리 데이터를 기반으로 사용자의 식습관 인사이트를 추출합니다.
/// AI API 호출 없이 순수 로컬 연산으로 동작합니다.
class FoodInsightService {
  /// 카테고리별 이모지 매핑
  static const Map<String, String> categoryEmojis = {
    '한식': '🍚',
    '중식': '🥟',
    '일식': '🍣',
    '양식': '🍝',
    '분식': '🍢',
    '아시안': '🍜',
    '패스트푸드': '🍔',
    '편의점': '🏪',
    '카페': '☕',
    '기타': '🍽️',
  };

  /// 카테고리별 빈도 집계
  ///
  /// 반환값: {카테고리명: 횟수} (횟수 내림차순 정렬)
  static Map<String, int> getCategoryFrequency(
    List<ReviewHistoryEntry> history,
  ) {
    final frequency = <String, int>{};
    for (final entry in history) {
      final category = entry.category.isNotEmpty ? entry.category : '기타';
      frequency[category] = (frequency[category] ?? 0) + 1;
    }

    // 빈도 내림차순 정렬
    final sorted = Map.fromEntries(
      frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }

  /// 가장 많이 먹은 음식 Top N
  ///
  /// [limit] 반환할 최대 개수
  /// 반환값: [{foodName, count}] 리스트
  static List<Map<String, dynamic>> getTopFoods(
    List<ReviewHistoryEntry> history, {
    int limit = 5,
  }) {
    final frequency = <String, int>{};
    for (final entry in history) {
      if (entry.foodName.isNotEmpty) {
        frequency[entry.foodName] = (frequency[entry.foodName] ?? 0) + 1;
      }
    }

    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(limit)
        .map((e) => {'foodName': e.key, 'count': e.value})
        .toList();
  }

  /// 최근 N일간의 리뷰만 필터링
  static List<ReviewHistoryEntry> getRecentEntries(
    List<ReviewHistoryEntry> history, {
    int days = 7,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return history.where((e) => e.createdAt.isAfter(cutoff)).toList();
  }

  /// 연속 동일 카테고리 감지
  ///
  /// 최근 리뷰가 같은 카테고리를 연달아 사용했는지 확인합니다.
  /// 반환값: null이면 연속 없음, {category, count}면 연속 감지
  static Map<String, dynamic>? getRecentStreak(
    List<ReviewHistoryEntry> history,
  ) {
    if (history.length < 2) return null;

    // 최신순 정렬
    final sorted = [...history]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final latestCategory = sorted.first.category;
    int streak = 0;

    for (final entry in sorted) {
      if (entry.category == latestCategory) {
        streak++;
      } else {
        break;
      }
    }

    // 2회 이상 연속이면 반환
    if (streak >= 2) {
      return {'category': latestCategory, 'count': streak};
    }
    return null;
  }

  /// 평균 별점 통계
  static Map<String, double> getAverageRatings(
    List<ReviewHistoryEntry> history,
  ) {
    if (history.isEmpty) {
      return {'taste': 0, 'delivery': 0, 'portion': 0, 'price': 0};
    }

    double tasteSum = 0, deliverySum = 0, portionSum = 0, priceSum = 0;
    for (final entry in history) {
      tasteSum += entry.tasteRating;
      deliverySum += entry.deliveryRating;
      portionSum += entry.portionRating;
      priceSum += entry.priceRating;
    }

    final count = history.length;
    return {
      'taste': double.parse((tasteSum / count).toStringAsFixed(1)),
      'delivery': double.parse((deliverySum / count).toStringAsFixed(1)),
      'portion': double.parse((portionSum / count).toStringAsFixed(1)),
      'price': double.parse((priceSum / count).toStringAsFixed(1)),
    };
  }

  /// 개인화 알림 메시지 생성 (템플릿 기반)
  ///
  /// AI API 호출 없이 히스토리 데이터만으로 메시지를 생성합니다.
  static String generateInsightMessage(List<ReviewHistoryEntry> history) {
    if (history.isEmpty) {
      return '첫 리뷰를 작성하고 맞춤 추천을 받아보세요! ✨';
    }

    final random = Random();
    final messages = <String>[];

    // 1. 연속 카테고리 기반 제안
    final streak = getRecentStreak(history);
    if (streak != null) {
      final category = streak['category'] as String;
      final count = streak['count'] as int;
      final emoji = categoryEmojis[category] ?? '🍽️';
      final suggestions = _getSuggestionForCategory(category);
      messages.add(
        '최근 $category를 $count번 연속 드셨어요! $emoji '
        '오늘은 $suggestions 어떠세요?',
      );
    }

    // 2. 가장 많이 먹은 음식 기반
    final topFoods = getTopFoods(history, limit: 1);
    if (topFoods.isNotEmpty) {
      final food = topFoods.first;
      final name = food['foodName'] as String;
      final count = food['count'] as int;
      if (count >= 3) {
        messages.add('$name을(를) 벌써 $count번이나 드셨네요! 새로운 메뉴 도전해볼까요? 🌟');
      }
    }

    // 3. 이번 주 리뷰 수 기반
    final weeklyEntries = getRecentEntries(history, days: 7);
    if (weeklyEntries.isNotEmpty) {
      final weeklyCategories = getCategoryFrequency(weeklyEntries);
      if (weeklyCategories.length == 1) {
        final onlyCategory = weeklyCategories.keys.first;
        final suggestion = _getSuggestionForCategory(onlyCategory);
        messages.add('이번 주는 $onlyCategory만 드셨어요! 오늘은 $suggestion 도전해보세요 💪');
      } else if (weeklyCategories.length >= 3) {
        messages.add(
          '이번 주 ${weeklyCategories.length}가지 카테고리를 드셨어요! 다양하게 잘 드시고 계시네요 👏',
        );
      }
    }

    // 4. 평균 맛 별점 기반
    final ratings = getAverageRatings(history);
    final tasteAvg = ratings['taste'] ?? 0;
    if (tasteAvg >= 4.0) {
      messages.add('평균 맛 점수 $tasteAvg점! 맛집을 잘 고르시네요 👨‍🍳');
    }

    // 5. 기본 메시지
    if (messages.isEmpty) {
      messages.addAll([
        '오늘은 어떤 맛있는 음식을 드실 건가요? 🍽️',
        '맛있는 한 끼의 시작, 메뉴를 추천받아보세요! 😋',
        '오늘도 맛있는 식사 하세요! 🌈',
      ]);
    }

    return messages[random.nextInt(messages.length)];
  }

  /// 카테고리에 대한 대안 제안
  static String _getSuggestionForCategory(String category) {
    const suggestions = {
      '한식': '양식이나 일식',
      '중식': '한식이나 아시안',
      '일식': '한식이나 중식',
      '양식': '한식이나 아시안',
      '분식': '제대로 된 한식',
      '아시안': '양식이나 일식',
      '패스트푸드': '건강한 한식',
      '편의점': '따끈한 한식이나 일식',
      '카페': '든든한 식사 메뉴',
    };
    return suggestions[category] ?? '새로운 카테고리의 음식';
  }

  /// 히스토리 요약 정보 생성
  ///
  /// 히스토리 화면 상단에 표시할 요약 데이터를 반환합니다.
  static Map<String, dynamic> generateSummary(
    List<ReviewHistoryEntry> history,
  ) {
    final totalReviews = history.length;
    final categoryFrequency = getCategoryFrequency(history);
    final topFoods = getTopFoods(history, limit: 3);
    final weeklyEntries = getRecentEntries(history, days: 7);
    final averageRatings = getAverageRatings(history);
    final streak = getRecentStreak(history);

    // 선호 카테고리 (1위)
    final favoriteCategory = categoryFrequency.isNotEmpty
        ? categoryFrequency.keys.first
        : null;

    return {
      'totalReviews': totalReviews,
      'categoryFrequency': categoryFrequency,
      'topFoods': topFoods,
      'weeklyCount': weeklyEntries.length,
      'averageRatings': averageRatings,
      'favoriteCategory': favoriteCategory,
      'streak': streak,
      'insightMessage': generateInsightMessage(history),
    };
  }
}

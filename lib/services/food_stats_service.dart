import 'dart:math';
import 'package:review_ai/data/constants/food_category_data.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';

/// 식습관 통계 분석 서비스
///
/// 리뷰 히스토리 데이터를 기반으로 사용자의 식습관 통계를 집계합니다.
/// AI API 호출 없이 순수 로컬 연산으로 동작합니다.
abstract class FoodStatsService {
  /// 카테고리별 빈도 집계 (횟수 내림차순 정렬)
  static Map<String, int> getCategoryFrequency(
    List<ReviewHistoryEntry> history,
  ) {
    final frequency = <String, int>{};
    for (final entry in history) {
      final category = entry.category.isNotEmpty ? entry.category : '기타';
      frequency[category] = (frequency[category] ?? 0) + 1;
    }
    return Map.fromEntries(
      frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// 가장 많이 먹은 음식 Top N
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
  static Map<String, dynamic>? getRecentStreak(
    List<ReviewHistoryEntry> history,
  ) {
    if (history.length < 2) return null;

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

    return streak >= 2 ? {'category': latestCategory, 'count': streak} : null;
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

  /// 개인화 알림 메시지 생성 (템플릿 기반, AI 호출 없음)
  static String generateInsightMessage(List<ReviewHistoryEntry> history) {
    if (history.isEmpty) {
      return '첫 리뷰를 작성하시면 맞춤 인사이트를 받아보실 수 있어요! ✨';
    }

    final random = Random();
    final messages = <String>[];

    final streak = getRecentStreak(history);
    if (streak != null) {
      final category = streak['category'] as String;
      final count = streak['count'] as int;
      final emoji = FoodCategoryData.categoryEmojis[category] ?? '🍽️';
      final suggestions = FoodCategoryData.getSuggestionForCategory(category);
      messages.add(
        '최근 $category 음식을 $count번이나 연속으로 드셨네요! $emoji '
        '오늘은 $suggestions 카테고리에 도전해 보시는 건 어떨까요?',
      );
    }

    final topFoods = getTopFoods(history, limit: 1);
    if (topFoods.isNotEmpty) {
      final food = topFoods.first;
      final name = food['foodName'] as String;
      final count = food['count'] as int;
      if (count >= 3) {
        messages.add(
          '$name 메뉴를 벌써 $count번이나 즐기셨네요! 혹시 오늘은 새로운 맛의 발견에 도전해 보시겠어요? 🌟',
        );
      }
    }

    final weeklyEntries = getRecentEntries(history, days: 7);
    if (weeklyEntries.isNotEmpty) {
      final weeklyCategories = getCategoryFrequency(weeklyEntries);
      if (weeklyCategories.length == 1) {
        final onlyCategory = weeklyCategories.keys.first;
        final suggestion = FoodCategoryData.getSuggestionForCategory(
          onlyCategory,
        );
        messages.add(
          '이번 주에는 오직 $onlyCategory 카테고리만 즐기셨네요! 건강을 위해 오늘은 $suggestion 메뉴를 드셔보시는 건 어떨까요? 💪',
        );
      } else if (weeklyCategories.length >= 3) {
        messages.add(
          '이번 주에는 ${weeklyCategories.length}가지 카테고리의 음식을 골고루 드셨네요! 정말 건강하고 다양한 식사를 즐기고 계시네요. 👏',
        );
      }
    }

    final ratings = getAverageRatings(history);
    final tasteAvg = ratings['taste'] ?? 0;
    if (tasteAvg >= 4.0) {
      messages.add('평균 맛 점수가 $tasteAvg점이에요! 역시 맛집을 고르는 안목이 대단하시네요. 👨‍🍳');
    }

    if (messages.isEmpty) {
      messages.addAll([
        '오늘은 어떤 맛있는 음식을 드실 계획이신가요? 🍽️',
        '맛있는 한 끼의 시작, 오늘 메뉴를 AI에게 추천받아 보세요! 😋',
        '오늘도 행복하고 맛있는 식사 시간이 되시길 바랍니다! 🌈',
      ]);
    }

    return messages[random.nextInt(messages.length)];
  }

  /// 히스토리 요약 정보 생성
  static Map<String, dynamic> generateSummary(
    List<ReviewHistoryEntry> history,
  ) {
    final totalReviews = history.length;
    final categoryFrequency = getCategoryFrequency(history);
    final topFoods = getTopFoods(history, limit: 3);
    final weeklyEntries = getRecentEntries(history, days: 7);
    final averageRatings = getAverageRatings(history);
    final streak = getRecentStreak(history);

    return {
      'totalReviews': totalReviews,
      'categoryFrequency': categoryFrequency,
      'topFoods': topFoods,
      'weeklyCount': weeklyEntries.length,
      'averageRatings': averageRatings,
      'favoriteCategory': categoryFrequency.isNotEmpty
          ? categoryFrequency.keys.first
          : null,
      'streak': streak,
      'insightMessage': generateInsightMessage(history),
    };
  }
}

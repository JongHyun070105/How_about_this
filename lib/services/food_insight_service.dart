import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:review_ai/config/api_config.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';
import 'package:review_ai/services/api_proxy_service.dart';

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

  /// 카테고리별 배경색 매핑 (메인화면 카테고리 색상과 동일)
  static const Map<String, Color> categoryColors = {
    '한식': Color(0xFFFFCDD2), // 빨강.shade100
    '중식': Color(0xFFFFE0B2), // 오렌지.shade100
    '일식': Color(0xFFBBDEFB), // 파랑.shade100
    '양식': Color(0xFFC8E6C9), // 초록.shade100
    '분식': Color(0xFFE1BEE7), // 보라.shade100
    '아시안': Color(0xFFB2DFDB), // 청록.shade100
    '패스트푸드': Color(0xFFFFF9C4), // 노랑.shade100
    '편의점': Color(0xFFFFCCBC), // 진한 오렌지.shade100
    '카페': Color(0xFFD7CCC8), // 갈색.shade100
    '기타': Color(0xFFF5F5F5), // 회색.shade100
  };

  /// 음식명 키워드 → 카테고리 매핑
  static const Map<String, List<String>> _categoryKeywords = {
    '한식': [
      '비빔밥',
      '불고기',
      '김치',
      '된장',
      '찌개',
      '국밥',
      '갈비',
      '삼겹살',
      '보쌈',
      '족발',
      '냉면',
      '칼국수',
      '수제비',
      '잡채',
      '전',
      '나물',
      '백반',
      '한정식',
      '제육',
      '돼지',
      '소고기',
      '닭갈비',
      '닭볶음',
      '김밥',
      '삼계탕',
      '설렁탕',
      '감자탕',
      '부대찌개',
      '순두부',
      '해장국',
      '갈비탕',
      '육개장',
      '미역국',
      '떡갈비',
      '곱창',
      '막국수',
      '쌈',
      '볶음밥',
      '덮밥',
      '비빔',
      '구이',
      '탕',
      '조림',
      '무침',
      '젓갈',
      '치킨',
      '닭',
      '삼겹',
      '오리',
      '곰탕',
      '추어탕',
      '매운탕',
      '된장찌개',
      '김치찌개',
      '청국장',
      '떡국',
      '만둣국',
      '수육',
      '편육',
      '양념치킨',
      '후라이드',
    ],
    '중식': [
      '짜장',
      '짬뽕',
      '탕수육',
      '마라',
      '볶음면',
      '중화',
      '양장피',
      '깐풍',
      '유린기',
      '마파두부',
      '군만두',
      '짜장면',
      '짬뽕',
      '울면',
      '잡탕밥',
      '팔보채',
      '고추잡채',
      '라조기',
      '꿔바로우',
    ],
    '일식': [
      '초밥',
      '스시',
      '사시미',
      '라멘',
      '우동',
      '돈까스',
      '돈카츠',
      '카츠',
      '덴푸라',
      '텐동',
      '규동',
      '오니기리',
      '타코야키',
      '오코노미야키',
      '소바',
      '카레',
      '일식',
      '회',
      '롤',
      '연어',
      '참치',
      '장어',
      '히레카츠',
      '가츠동',
    ],
    '양식': [
      '파스타',
      '피자',
      '스테이크',
      '리조또',
      '햄버거스테이크',
      '오므라이스',
      '그라탕',
      '샐러드',
      '수프',
      '양식',
      '크림',
      '토마토',
      '까르보나라',
      '봉골레',
      '알리오올리오',
      '필라프',
      '바비큐',
      '립',
      '폭찹',
    ],
    '분식': [
      '떡볶이',
      '순대',
      '어묵',
      '튀김',
      '라면',
      '라볶이',
      '쫄면',
      '비빔면',
      '잔치국수',
      '콩국수',
      '핫도그',
      '토스트',
      '붕어빵',
      '호떡',
    ],
    '아시안': [
      '쌀국수',
      '팟타이',
      '커리',
      '난',
      '탄두리',
      '분짜',
      '월남쌈',
      '반미',
      '똠양꿍',
      '나시고랭',
      '볶음쌀국수',
      '태국',
      '베트남',
      '인도',
      '태국식',
      '베트남식',
    ],
    '패스트푸드': [
      '버거',
      '햄버거',
      '맥도날드',
      '롯데리아',
      '버거킹',
      '핫도그',
      '감자튀김',
      '너겟',
      '프라이',
      '치즈버거',
      '와퍼',
      '빅맥',
      '맥너겟',
      '서브웨이',
      '샌드위치',
    ],
    '편의점': [
      '도시락',
      '삼각김밥',
      '컵라면',
      '편의점',
      'CU',
      'GS25',
      '세븐일레븐',
      '이마트24',
      '미니스톱',
    ],
    '카페': [
      '커피',
      '아메리카노',
      '라떼',
      '카페',
      '케이크',
      '마카롱',
      '크로와상',
      '베이글',
      '스무디',
      '프라푸치노',
      '아이스티',
      '밀크티',
      '버블티',
      '와플',
      '팬케이크',
      '브런치',
    ],
  };

  /// 음식명으로부터 카테고리를 AI로 추론합니다.
  ///
  /// Gemini API를 호출하여 음식명을 분류합니다.
  /// API 호출 실패 시 키워드 기반 폴백을 사용합니다.
  static Future<String> inferCategory(String foodName) async {
    if (foodName.isEmpty) return '기타';

    // 1차: AI 분류 시도
    try {
      final result = await _inferCategoryWithAI(foodName);
      if (result != null) return result;
    } catch (_) {
      // AI 실패 시 폴백으로 진행
    }

    // 2차: 키워드 기반 폴백
    return _inferCategoryByKeyword(foodName);
  }

  /// AI를 사용한 카테고리 분류
  static Future<String?> _inferCategoryWithAI(String foodName) async {
    final apiService = ApiProxyService(http.Client(), ApiConfig.proxyUrl);
    final categories = categoryEmojis.keys.where((c) => c != '기타').toList();

    final prompt =
        '다음 음식명이 어떤 카테고리에 해당하는지 분류해주세요.\n'
        '음식명: $foodName\n'
        '카테고리 목록: ${categories.join(', ')}\n'
        '반드시 위 카테고리 목록 중 하나만 정확히 출력하세요. 다른 설명은 하지 마세요.';

    final response = await apiService.generateContent(prompt);

    final candidates = response['candidates'] as List?;
    if (candidates != null && candidates.isNotEmpty) {
      final text = candidates[0]['content']['parts'][0]['text'] as String?;
      if (text != null) {
        final trimmed = text.trim();
        // 유효한 카테고리인지 확인
        for (final category in categories) {
          if (trimmed.contains(category)) {
            return category;
          }
        }
      }
    }
    return null;
  }

  /// 키워드 기반 카테고리 추론 (AI 폴백용)
  static String _inferCategoryByKeyword(String foodName) {
    final normalized = foodName.toLowerCase().replaceAll(' ', '');

    String bestCategory = '기타';
    int bestScore = 0;

    for (final entry in _categoryKeywords.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (normalized.contains(keyword.toLowerCase().replaceAll(' ', ''))) {
          score += keyword.length;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestCategory = entry.key;
      }
    }

    return bestCategory;
  }

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
      return '첫 리뷰를 작성하시면 맞춤 인사이트를 받아보실 수 있어요! ✨';
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
        '최근 $category 음식을 $count번이나 연속으로 드셨네요! $emoji '
        '오늘은 $suggestions 카테고리에 도전해 보시는 건 어떨까요?',
      );
    }

    // 2. 가장 많이 먹은 음식 기반
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

    // 3. 이번 주 리뷰 수 기반
    final weeklyEntries = getRecentEntries(history, days: 7);
    if (weeklyEntries.isNotEmpty) {
      final weeklyCategories = getCategoryFrequency(weeklyEntries);
      if (weeklyCategories.length == 1) {
        final onlyCategory = weeklyCategories.keys.first;
        final suggestion = _getSuggestionForCategory(onlyCategory);
        messages.add(
          '이번 주에는 오직 $onlyCategory 카테고리만 즐기셨네요! 건강을 위해 오늘은 $suggestion 메뉴를 드셔보시는 건 어떨까요? 💪',
        );
      } else if (weeklyCategories.length >= 3) {
        messages.add(
          '이번 주에는 ${weeklyCategories.length}가지 카테고리의 음식을 골고루 드셨네요! 정말 건강하고 다양한 식사를 즐기고 계시네요. 👏',
        );
      }
    }

    // 4. 평균 맛 별점 기반
    final ratings = getAverageRatings(history);
    final tasteAvg = ratings['taste'] ?? 0;
    if (tasteAvg >= 4.0) {
      messages.add('평균 맛 점수가 $tasteAvg점이에요! 역시 맛집을 고르는 안목이 대단하시네요. 👨‍🍳');
    }

    // 5. 기본 메시지
    if (messages.isEmpty) {
      messages.addAll([
        '오늘은 어떤 맛있는 음식을 드실 계획이신가요? 🍽️',
        '맛있는 한 끼의 시작, 오늘 메뉴를 AI에게 추천받아 보세요! 😋',
        '오늘도 행복하고 맛있는 식사 시간이 되시길 바랍니다! 🌈',
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

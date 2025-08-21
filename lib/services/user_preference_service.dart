import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 사용자 선택 기록 모델
class FoodSelection {
  final String foodName;
  final String category;
  final DateTime selectedAt;
  final bool liked; // true: 좋아요, false: 싫어요

  FoodSelection({
    required this.foodName,
    required this.category,
    required this.selectedAt,
    required this.liked,
  });

  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'category': category,
      'selectedAt': selectedAt.toIso8601String(),
      'liked': liked,
    };
  }

  factory FoodSelection.fromJson(Map<String, dynamic> json) {
    return FoodSelection(
      foodName: json['foodName'],
      category: json['category'],
      selectedAt: DateTime.parse(json['selectedAt']),
      liked: json['liked'],
    );
  }
}

// 사용자 취향 분석 결과
class UserPreferenceAnalysis {
  final List<String> preferredFoods;
  final List<String> dislikedFoods;
  final List<String> preferredCategories;
  final Map<String, double> categoryScores; // 카테고리별 선호도 점수

  UserPreferenceAnalysis({
    required this.preferredFoods,
    required this.dislikedFoods,
    required this.preferredCategories,
    required this.categoryScores,
  });
}

class UserPreferenceService {
  static const String _selectionHistoryKey = 'food_selection_history';
  static const String _dislikedFoodsKey = 'disliked_foods';
  static const int _maxHistorySize = 100; // 최대 기록 수

  // 음식 선택 기록 저장
  static Future<void> recordFoodSelection({
    required String foodName,
    required String category,
    required bool liked,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final selection = FoodSelection(
      foodName: foodName,
      category: category,
      selectedAt: DateTime.now(),
      liked: liked,
    );

    // 기존 기록 가져오기
    final history = await getFoodSelectionHistory();

    // 새 기록 추가
    history.add(selection);

    // 최대 크기 제한
    if (history.length > _maxHistorySize) {
      history.removeAt(0);
    }

    // 저장
    final jsonList = history.map((s) => s.toJson()).toList();
    await prefs.setString(_selectionHistoryKey, jsonEncode(jsonList));

    // 싫어하는 음식 별도 관리
    if (!liked) {
      await _addDislikedFood(foodName);
    }
  }

  // 음식 선택 기록 조회
  static Future<List<FoodSelection>> getFoodSelectionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_selectionHistoryKey);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => FoodSelection.fromJson(json)).toList();
    } catch (e) {
      debugPrint('선택 기록 로드 오류: $e');
      return [];
    }
  }

  // 싫어하는 음식 추가
  static Future<void> _addDislikedFood(String foodName) async {
    final prefs = await SharedPreferences.getInstance();
    final dislikedFoods = await getDislikedFoods();

    if (!dislikedFoods.contains(foodName)) {
      dislikedFoods.add(foodName);
      await prefs.setStringList(_dislikedFoodsKey, dislikedFoods);
    }
  }

  // 싫어하는 음식 목록 조회
  static Future<List<String>> getDislikedFoods() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_dislikedFoodsKey) ?? [];
  }

  // 싫어하는 음식에서 제거 (다시 추천받고 싶을 때)
  static Future<void> removeFromDislikedFoods(String foodName) async {
    final prefs = await SharedPreferences.getInstance();
    final dislikedFoods = await getDislikedFoods();
    dislikedFoods.remove(foodName);
    await prefs.setStringList(_dislikedFoodsKey, dislikedFoods);
  }

  // 사용자 취향 분석
  static Future<UserPreferenceAnalysis> analyzeUserPreferences() async {
    final history = await getFoodSelectionHistory();
    final dislikedFoods = await getDislikedFoods();

    if (history.isEmpty) {
      return UserPreferenceAnalysis(
        preferredFoods: [],
        dislikedFoods: dislikedFoods,
        preferredCategories: [],
        categoryScores: {},
      );
    }

    // 최근 30일 기록만 분석
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentHistory = history
        .where((s) => s.selectedAt.isAfter(thirtyDaysAgo))
        .toList();

    // 좋아요 받은 음식들
    final likedFoods = recentHistory
        .where((s) => s.liked)
        .map((s) => s.foodName)
        .toSet()
        .toList();

    // 카테고리별 선호도 점수 계산
    final categoryScores = _calculateCategoryScores(recentHistory);

    // 선호 카테고리 (점수 0.6 이상)
    final preferredCategories = categoryScores.entries
        .where((e) => e.value >= 0.6)
        .map((e) => e.key)
        .toList();

    return UserPreferenceAnalysis(
      preferredFoods: likedFoods,
      dislikedFoods: dislikedFoods,
      preferredCategories: preferredCategories,
      categoryScores: categoryScores,
    );
  }

  // 주어진 기록 목록에 대한 카테고리 점수 계산 헬퍼
  static Map<String, double> _calculateCategoryScores(
    List<FoodSelection> history,
  ) {
    final categoryScores = <String, double>{};
    final categoryStats = <String, Map<String, int>>{};

    if (history.isEmpty) return {};

    for (final selection in history) {
      final category = selection.category;

      categoryStats.putIfAbsent(category, () => {'liked': 0, 'total': 0});
      categoryStats[category]!['total'] =
          categoryStats[category]!['total']! + 1;

      if (selection.liked) {
        categoryStats[category]!['liked'] =
            categoryStats[category]!['liked']! + 1;
      }
    }

    for (final entry in categoryStats.entries) {
      final category = entry.key;
      final stats = entry.value;
      final likeRatio = stats['liked']! / stats['total']!;
      final frequencyBonus = (stats['total']! / history.length) * 0.3;

      categoryScores[category] = likeRatio + frequencyBonus;
    }
    return categoryScores;
  }

  // 카테고리 선호도 변화 추이 계산
  static Future<Map<String, String>> getCategoryPreferenceTrends() async {
    final history = await getFoodSelectionHistory();

    if (history.length < 2) {
      return {}; // 충분한 데이터가 없음
    }

    final now = DateTime.now();
    final currentPeriodStart = now.subtract(const Duration(days: 30));
    final previousPeriodStart = now.subtract(const Duration(days: 60));

    final currentPeriodHistory = history
        .where((s) => s.selectedAt.isAfter(currentPeriodStart))
        .toList();
    final previousPeriodHistory = history
        .where(
          (s) =>
              s.selectedAt.isAfter(previousPeriodStart) &&
              s.selectedAt.isBefore(currentPeriodStart),
        )
        .toList();

    final currentScores = _calculateCategoryScores(currentPeriodHistory);
    final previousScores = _calculateCategoryScores(previousPeriodHistory);

    final trends = <String, String>{};

    // 현재 기간에 있는 카테고리 분석
    for (final category in currentScores.keys) {
      final currentScore = currentScores[category]!;
      final previousScore = previousScores[category];

      if (previousScore == null) {
        trends[category] = '신규';
      } else {
        final diff = currentScore - previousScore;
        if (diff > 0.05) {
          trends[category] = '상승';
        } else if (diff < -0.05) {
          trends[category] = '하락';
        } else {
          trends[category] = '유지';
        }
      }
    }

    // 이전 기간에만 있고 현재 기간에는 없는 카테고리 (하락으로 간주)
    for (final category in previousScores.keys) {
      if (!currentScores.containsKey(category)) {
        trends[category] = '하락';
      }
    }

    return trends;
  }

  // 개인화된 추천을 위한 프롬프트 생성
  static Future<String> buildPersonalizedPrompt({
    required String category,
    required List<String> recentFoods,
  }) async {
    final analysis = await analyzeUserPreferences();
    final dislikedFoods = await getDislikedFoods();

    final basePrompt = '''
당신은 음식을 무엇을 먹을지 고민하는 사용자를 위한 개인화된 음식 추천 시스템입니다.

사용자 취향 분석:
''';

    String preferenceInfo = '''''';

    // 선호하는 음식이 있는 경우
    if (analysis.preferredFoods.isNotEmpty) {
      preferenceInfo +=
          '''
- 자주 좋아요를 누른 음식들: ${analysis.preferredFoods.join(', ')}
''';
      preferenceInfo += '''- 이런 음식들과 비슷한 맛이나 스타일의 음식을 우선 추천해주세요.
''';
    }

    // 싫어하는 음식 제외
    if (dislikedFoods.isNotEmpty) {
      preferenceInfo +=
          '''
- 절대 추천하지 말아야 할 음식들: ${dislikedFoods.join(', ')}
''';
      preferenceInfo += '''- 위 음식들과 비슷한 음식도 피해주세요.
''';
    }

    // 카테고리 선호도
    if (analysis.preferredCategories.isNotEmpty && category == '상관없음') {
      preferenceInfo +=
          '''
- 선호하는 카테고리: ${analysis.preferredCategories.join(', ')}
''';
      preferenceInfo += '''- 가능하면 선호 카테고리에서 더 많이 추천해주세요.
''';
    }

    // 최근 먹은 음식
    final recentFoodsText = recentFoods.isEmpty
        ? '''최근에 먹은 음식이 없습니다.'''
        : '''최근에 먹은 음식들: ${recentFoods.join(', ')} (이것들은 제외해주세요)''';

    // 카테고리 제약
    final isAny = category == '상관없음';
    final categoryRule = isAny
        ? '''카테고리 제약 없이 사용자 취향에 맞게 다양하게 추천하세요.'''
        : '''반드시 모든 항목이 정확히 "$category" 카테고리여야 합니다. 다른 카테고리는 절대 포함하지 마세요.''';

    final examples = '''
예시(출력에 포함하지 마세요):
- 한식: 김치찌개, 된장찌개, 비빔밥, 불고기, 갈비탕, 냉면
- 중식: 짜장면, 짬뽕, 탕수육, 마라탕, 마라샹궈, 꿔바로우, 마파두부, 깐풍기, 볶음밥, 딤섬, 훠궈, 우육면
- 일식: 스시, 사시미, 라멘, 우동, 돈카츠, 규동, 오코노미야키
- 양식: 파스타, 피자, 스테이크, 리조또, 라자냐
- 분식: 떡볶이, 순대, 오뎅, 김밥, 라볶이
- 아시안: 쌀국수, 팟타이, 똠얌꿍, 반미, 카오팟
- 패스트푸드: 햄버거, 프라이드치킨, 감자튀김, 핫도그, 나초
''';

    return '''
$basePrompt
$preferenceInfo

$recentFoodsText

요구사항:
- $categoryRule
- 한국에서 흔히 접할 수 있는 메뉴명만 사용하세요.
- 유사/중복 메뉴는 피하고 다양성을 유지하세요.
- 개수: 5~8개.
- 출력은 오직 순수 JSON 배열만. 설명/문장은 금지. 마크다운 금지.
- JSON 형식: [{"name":"메뉴명"}, {"name":"메뉴명"}, ...]

$examples
이제 결과를 JSON 배열로만 출력하세요.
''';
  }
}

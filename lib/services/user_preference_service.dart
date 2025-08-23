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
  static const String _reviewPromptLikeCountKey = 'review_prompt_like_count';

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

    // 싫어하는 음식 별도 관리 또는 좋아요 카운터 증가
    if (!liked) {
      await _addDislikedFood(foodName);
    } else {
      int count = prefs.getInt(_reviewPromptLikeCountKey) ?? 0;
      await prefs.setInt(_reviewPromptLikeCountKey, count + 1);
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

  

  // 리뷰 프롬프트 다이얼로그를 보여줄 시점인지 확인
  static Future<bool> shouldShowReviewPromptDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final likeCount = prefs.getInt(_reviewPromptLikeCountKey) ?? 0;

    // 10번에 한 번씩 보여줌
    if (likeCount > 0 && likeCount % 10 == 0) {
      return true;
    }
    return false;
  }

  // 리뷰 프롬프트 다이얼로그 표시 기록 (카운터 초기화)
  static Future<void> recordReviewPromptDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reviewPromptLikeCountKey, 0); // 카운터 초기화
  }
}
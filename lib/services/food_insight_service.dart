import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:review_ai/config/api_config.dart';
import 'package:review_ai/data/constants/food_category_data.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';
import 'package:review_ai/services/api_proxy_service.dart';
import 'package:review_ai/services/food_stats_service.dart';

export 'package:review_ai/data/constants/food_category_data.dart'
    show FoodCategoryData;
export 'package:review_ai/services/food_stats_service.dart'
    show FoodStatsService;

/// 식습관 분석 서비스 (AI 카테고리 추론 전담)
///
/// 통계 집계: [FoodStatsService]
/// 상수 데이터: [FoodCategoryData]
class FoodInsightService {
  // 하위 호환성을 위해 상수를 위임 노출합니다.
  static Map<String, String> get categoryEmojis => FoodCategoryData.categoryEmojis;
  static Map<String, Color> get categoryColors => FoodCategoryData.categoryColors;

  // ── 하위 호환성 위임 메서드 ──────────────────────────────────────
  // 기존 코드가 FoodInsightService를 통해 접근하므로 FoodStatsService에 위임합니다.

  static Map<String, int> getCategoryFrequency(List<ReviewHistoryEntry> h) =>
      FoodStatsService.getCategoryFrequency(h);

  static List<Map<String, dynamic>> getTopFoods(
    List<ReviewHistoryEntry> h, {
    int limit = 5,
  }) => FoodStatsService.getTopFoods(h, limit: limit);

  static List<ReviewHistoryEntry> getRecentEntries(
    List<ReviewHistoryEntry> h, {
    int days = 7,
  }) => FoodStatsService.getRecentEntries(h, days: days);

  static Map<String, dynamic>? getRecentStreak(List<ReviewHistoryEntry> h) =>
      FoodStatsService.getRecentStreak(h);

  static Map<String, double> getAverageRatings(List<ReviewHistoryEntry> h) =>
      FoodStatsService.getAverageRatings(h);

  static String generateInsightMessage(List<ReviewHistoryEntry> h) =>
      FoodStatsService.generateInsightMessage(h);

  static Map<String, dynamic> generateSummary(List<ReviewHistoryEntry> h) =>
      FoodStatsService.generateSummary(h);
  // ────────────────────────────────────────────────────────────────


  /// 음식명으로부터 카테고리를 추론합니다.
  ///
  /// 1차: Gemini API 추론 → 2차: 키워드 폴백
  static Future<String> inferCategory(String foodName) async {
    if (foodName.isEmpty) return '기타';

    try {
      final result = await _inferCategoryWithAI(foodName);
      if (result != null) return result;
    } catch (_) {
      // AI 실패 시 키워드 폴백으로 진행
    }

    return _inferCategoryByKeyword(foodName);
  }

  /// Gemini API를 사용한 카테고리 분류
  static Future<String?> _inferCategoryWithAI(String foodName) async {
    final apiService = ApiProxyService(http.Client(), ApiConfig.proxyUrl);
    final categories =
        FoodCategoryData.categoryEmojis.keys.where((c) => c != '기타').toList();

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
        for (final category in categories) {
          if (trimmed.contains(category)) return category;
        }
      }
    }
    return null;
  }

  /// 키워드 기반 카테고리 추론 (AI 폴백)
  static String _inferCategoryByKeyword(String foodName) {
    final normalized = foodName.toLowerCase().replaceAll(' ', '');

    String bestCategory = '기타';
    int bestScore = 0;

    for (final entry in FoodCategoryData.categoryKeywords.entries) {
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
}

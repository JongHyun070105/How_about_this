import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:review_ai/config/api_config.dart';
import 'package:review_ai/data/constants/food_category_data.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';
import 'package:review_ai/services/api_proxy_service.dart';
import 'package:review_ai/services/food_stats_service.dart';
import 'package:review_ai/utils/gemini_response_parser.dart';
import 'package:review_ai/core/utils/logger_service.dart';

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
  static Map<String, String> get categoryEmojis =>
      FoodCategoryData.categoryEmojis;
  static Map<String, Color> get categoryColors =>
      FoodCategoryData.categoryColors;

  // 캐싱된 카테고리 목록
  static final List<String> _cachedCategories = FoodCategoryData
      .categoryEmojis
      .keys
      .where((c) => c != '기타')
      .toList();

  // 사전 정규화(정리)된 키워드 맵 캐싱
  static Map<String, List<String>>? _normalizedKeywords;

  static Map<String, List<String>> get _getNormalizedKeywords {
    if (_normalizedKeywords != null) return _normalizedKeywords!;
    final map = <String, List<String>>{};
    for (final entry in FoodCategoryData.categoryKeywords.entries) {
      map[entry.key] = entry.value
          .map((kw) => kw.toLowerCase().replaceAll(' ', ''))
          .toList();
    }
    _normalizedKeywords = map;
    return _normalizedKeywords!;
  }

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
  static Future<String> inferCategory(
    String foodName, {
    http.Client? httpClient,
  }) async {
    if (foodName.isEmpty) return '기타';

    try {
      final result = await _inferCategoryWithAI(
        foodName,
        httpClient: httpClient,
      );
      if (result != null) return result;
    } catch (e, stack) {
      LoggerService.w('AI 카테고리 추론 실패 (키워드 폴백 적용): $e', e, stack);
    }

    return _inferCategoryByKeyword(foodName);
  }

  /// Gemini API를 사용한 카테고리 분류
  static Future<String?> _inferCategoryWithAI(
    String foodName, {
    http.Client? httpClient,
  }) async {
    final client = httpClient ?? http.Client();
    final isOwnClient = httpClient == null;
    try {
      final apiService = ApiProxyService(client, ApiConfig.proxyUrl);
      final categories = _cachedCategories;

      final prompt =
          '다음 음식명이 어떤 카테고리에 해당하는지 분류해주세요.\n'
          '음식명: $foodName\n'
          '카테고리 목록: ${categories.join(', ')}\n'
          '반드시 위 카테고리 목록 중 하나만 정확히 출력하세요. 다른 설명은 하지 마세요.';

      final response = await apiService.generateContent(prompt);
      final text = GeminiResponseParser.extractText(response);
      if (text != null) {
        final trimmed = text.trim();
        for (final category in categories) {
          if (trimmed.contains(category)) return category;
        }
      }
    } finally {
      if (isOwnClient) {
        client.close(); // 소켓 리소스 누수 방지
      }
    }
    return null;
  }

  /// 키워드 기반 카테고리 추론 (AI 폴백)
  static String _inferCategoryByKeyword(String foodName) {
    final normalized = foodName.toLowerCase().replaceAll(' ', '');

    String bestCategory = '기타';
    int bestScore = 0;

    final keywordMap = _getNormalizedKeywords;

    for (final entry in keywordMap.entries) {
      int score = 0;
      final keywords = entry.value;
      for (final keyword in keywords) {
        if (normalized.contains(keyword)) {
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

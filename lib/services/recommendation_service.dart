import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:reviewai_flutter/providers/food_providers.dart';
import 'user_preference_service.dart'; // 위에서 만든 서비스 import
import 'dart:math';
import 'package:reviewai_flutter/config/app_constants.dart';

class RecommendationService {
  static final _apiKey = dotenv.env['GEMINI_API_KEY'];

  static Future<List<FoodRecommendation>> getFoodRecommendations({
    required String category,
    required List<String> history,
  }) async {
    if (_apiKey == null) {
      throw Exception('API 키가 없습니다. .env 파일을 확인하세요.');
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey!,
    );

    // 개인화된 프롬프트 생성
    final prompt = await UserPreferenceService.buildPersonalizedPrompt(
      category: category,
      recentFoods: history,
    );

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final jsonString = response.text;

      if (jsonString == null) {
        throw Exception('Gemini API로부터 응답을 받지 못했습니다.');
      }

      // JSON 문자열 정리 (마크다운 코드 블록 제거)
      final cleanedJson = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final List<dynamic> decodedList = jsonDecode(cleanedJson);

      final recommendations = decodedList
          .map((item) => FoodRecommendation.fromJson(item))
          .toList();

      // 싫어하는 음식 필터링 (추가 안전장치)
      final dislikedFoods = await UserPreferenceService.getDislikedFoods();
      final filteredRecommendations = recommendations
          .where((food) => !dislikedFoods.contains(food.name))
          .toList();

      return filteredRecommendations;
    } catch (e) {
      debugPrint('Gemini API 호출 또는 파싱 오류: $e');
      return Future.error('음식 추천을 받아오는 데 실패했습니다. 다시 시도해주세요.');
    }
  }

  // 개인화된 추천을 위한 스마트 음식 선택
  static FoodRecommendation pickSmartFood(
    List<FoodRecommendation> foods,
    List<String> recentFoods,
    UserPreferenceAnalysis preferences,
  ) {
    if (foods.isEmpty) {
      throw Exception("추천 가능한 음식이 없습니다.");
    }

    final random = Random(); // Create a single Random instance

    // 1단계: 싫어하는 음식과 최근 먹은 음식 제외
    List<FoodRecommendation> available = foods
        .where((f) => !recentFoods.contains(f.name))
        .where((f) => !preferences.dislikedFoods.contains(f.name))
        .toList();

    if (available.isEmpty) {
      // 최근 음식 기록 초기화하고 다시 시도 (싫어하는 음식은 유지)
      recentFoods.clear();
      available = foods
          .where((f) => !preferences.dislikedFoods.contains(f.name))
          .toList();

      if (available.isEmpty) {
        // 모든 음식을 싫어하는 경우 - 전체에서 랜덤 선택
        available = List.from(foods);
      }
    }

    // 2단계: 선호도 기반 가중치 적용
    if (preferences.preferredFoods.isNotEmpty) {
      final preferredAvailable = available
          .where((f) => preferences.preferredFoods.contains(f.name))
          .toList();

      // 선호하는 음식이 있으면 70% 확률로 선호 음식에서 선택
      if (preferredAvailable.isNotEmpty && random.nextDouble() < 0.7) {
        available = preferredAvailable;
      }
    }

    // 3단계: 최종 선택
    final chosen = available[random.nextInt(available.length)];

    // 4단계: 기록 업데이트
    recentFoods.add(chosen.name);
    if (recentFoods.length > AppConstants.recentFoodsLimit) {
      recentFoods.removeAt(0);
    }

    return chosen;
  }

  // 사용자 통계 조회
  static Future<Map<String, dynamic>> getUserStats() async {
    final history = await UserPreferenceService.getFoodSelectionHistory();
    final analysis = await UserPreferenceService.analyzeUserPreferences();

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentSelections = history
        .where((s) => s.selectedAt.isAfter(thirtyDaysAgo))
        .toList();

    // 카테고리별 통계
    final categoryStats = <String, int>{};
    for (final selection in recentSelections) {
      categoryStats[selection.category] =
          (categoryStats[selection.category] ?? 0) + 1;
    }

    // 가장 자주 선택한 음식 TOP 5
    final foodFrequency = <String, int>{};
    for (final selection in recentSelections) {
      foodFrequency[selection.foodName] =
          (foodFrequency[selection.foodName] ?? 0) + 1;
    }

    final topFoods = foodFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalSelections': history.length,
      'recentSelections': recentSelections.length,
      'likedPercentage': recentSelections.isEmpty
          ? 0.0
          : (recentSelections.where((s) => s.liked).length /
                recentSelections.length *
                100),
      'categoryStats': categoryStats,
      'topFoods': topFoods
          .take(5)
          .map((e) => {'name': e.key, 'count': e.value})
          .toList(),
      'preferredCategories': analysis.preferredCategories,
      'dislikedFoodsCount': analysis.dislikedFoods.length,
    };
  }
}

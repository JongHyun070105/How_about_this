import 'package:flutter/foundation.dart';
import 'package:review_ai/data/models/food_recommendation.dart';
import 'package:review_ai/services/api_proxy_service.dart';
import 'package:review_ai/utils/gemini_response_parser.dart';

abstract class RecommendationRemoteDataSource {
  Future<List<FoodRecommendation>> getFoodRecommendations({
    required String category,
    required List<String> recentFoods,
  });
}

class RecommendationRemoteDataSourceImpl
    implements RecommendationRemoteDataSource {
  final ApiProxyService _apiProxyService;

  RecommendationRemoteDataSourceImpl(this._apiProxyService);

  @override
  Future<List<FoodRecommendation>> getFoodRecommendations({
    required String category,
    required List<String> recentFoods,
  }) async {
    try {
      // 개인화 추천 프롬프트 생성
      final prompt = await _apiProxyService
          .buildPersonalizedRecommendationPrompt(
            category: category,
            recentFoods: recentFoods,
          );

      // Gemini API 호출
      final response = await _apiProxyService.generateContent(prompt);

      // 공통 파서를 사용하여 응답 파싱
      return GeminiResponseParser.parseRecommendations(response);
    } catch (e, stackTrace) {
      debugPrint('Gemini API 호출 또는 파싱 오류: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('음식 추천을 받아오는 데 실패했습니다. 다시 시도해주세요.');
    }
  }
}

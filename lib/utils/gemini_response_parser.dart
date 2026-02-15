import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:review_ai/data/models/food_recommendation.dart';

/// Gemini API 응답에서 음식 추천 목록을 파싱하는 공통 유틸리티
class GeminiResponseParser {
  /// Gemini API 응답 Map에서 텍스트를 추출합니다.
  static String? extractText(Map<String, dynamic> response) {
    return response['candidates']?[0]?['content']?['parts']?[0]?['text']
        as String?;
  }

  /// JSON 문자열에서 마크다운 코드 블록을 제거합니다.
  static String cleanMarkdownJson(String jsonString) {
    var cleaned = jsonString.trim();

    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '');
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll('```', '');
    }

    return cleaned.trim();
  }

  /// Gemini API 응답을 FoodRecommendation 리스트로 파싱합니다.
  ///
  /// 마크다운 코드 블록 제거, 숫자 접두사 제거 등을 포함합니다.
  static List<FoodRecommendation> parseRecommendations(
    Map<String, dynamic> response,
  ) {
    final jsonString = extractText(response);

    if (jsonString == null) {
      debugPrint('ERROR: No text in Gemini response');
      throw Exception('Gemini API로부터 응답을 받지 못했습니다.');
    }

    debugPrint(
      'Raw Gemini response (first 200 chars): ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}',
    );

    final cleanedJson = cleanMarkdownJson(jsonString);

    debugPrint(
      'Cleaned JSON for parsing (first 200 chars): ${cleanedJson.substring(0, cleanedJson.length > 200 ? 200 : cleanedJson.length)}',
    );

    final List<dynamic> decodedList = jsonDecode(cleanedJson);

    debugPrint('AI가 생성한 음식 개수: ${decodedList.length}개');

    final recommendations = decodedList.map((item) {
      if (item is Map<String, dynamic> && item['name'] != null) {
        // 숫자 접두사 제거 (예: "1. 치킨" -> "치킨")
        final cleanedName = (item['name'] as String).replaceFirst(
          RegExp(r'^\d+\.\s*'),
          '',
        );
        item['name'] = cleanedName;
      }
      return FoodRecommendation.fromJson(item);
    }).toList();

    debugPrint('파싱 완료: ${recommendations.length}개 음식 추천');

    return recommendations;
  }
}

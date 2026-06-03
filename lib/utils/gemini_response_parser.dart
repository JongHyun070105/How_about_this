import 'dart:convert';
import 'package:review_ai/data/models/food_recommendation.dart';
import 'package:review_ai/core/utils/logger_service.dart';

/// Gemini API 응답에서 음식 추천 목록을 파싱하는 공통 유틸리티
class GeminiResponseParser {
  // 정규식 객체 캐싱
  static final RegExp _openingMarkdownFenceRegex = RegExp(
    r'^```\s*[A-Za-z0-9_-]*\s*\r?\n?',
    caseSensitive: false,
  );
  static final RegExp _closingMarkdownFenceRegex = RegExp(r'\r?\n?```\s*$');
  static final RegExp _numberPrefixRegex = RegExp(r'^\d+\.\s*');

  /// Gemini API 응답 Map에서 텍스트를 추출합니다.
  static String? extractText(Map<String, dynamic> response) {
    final candidates = response['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    if (content == null) return null;

    final parts = content['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;

    return parts[0]['text'] as String?;
  }

  /// JSON 문자열에서 마크다운 코드 블록을 제거합니다.
  static String cleanMarkdownJson(String jsonString) {
    var cleaned = jsonString.trim();

    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(_openingMarkdownFenceRegex, '')
          .replaceFirst(_closingMarkdownFenceRegex, '');
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
      LoggerService.e('ERROR: No text in Gemini response');
      throw Exception('Gemini API로부터 응답을 받지 못했습니다.');
    }

    LoggerService.d(
      'Raw Gemini response (first 200 chars): ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}',
    );

    final cleanedJson = cleanMarkdownJson(jsonString);

    LoggerService.d(
      'Cleaned JSON for parsing (first 200 chars): ${cleanedJson.substring(0, cleanedJson.length > 200 ? 200 : cleanedJson.length)}',
    );

    List<dynamic> decodedList;
    try {
      decodedList = jsonDecode(cleanedJson);
    } catch (e, stack) {
      LoggerService.e('JSON 파싱 실패: $e\nRaw: $cleanedJson', e, stack);
      throw Exception('추천 데이터를 분석하는 중 문제가 발생했습니다. 다시 시도해 주세요.');
    }

    LoggerService.d('AI가 생성한 음식 개수: ${decodedList.length}개');

    final recommendations = <FoodRecommendation>[];
    for (final item in decodedList) {
      if (item is Map<String, dynamic>) {
        final Map<String, dynamic> itemCopy = Map<String, dynamic>.from(item);
        final nameVal = itemCopy['name'];
        if (nameVal is String) {
          // 숫자 접두사 제거 (예: "1. 치킨" -> "치킨")
          itemCopy['name'] = nameVal.replaceFirst(_numberPrefixRegex, '');
        }
        try {
          recommendations.add(FoodRecommendation.fromJson(itemCopy));
        } catch (e, stack) {
          LoggerService.e('FoodRecommendation 변환 실패: $e', e, stack);
        }
      }
    }

    LoggerService.i('파싱 완료: ${recommendations.length}개 음식 추천');

    return recommendations;
  }
}

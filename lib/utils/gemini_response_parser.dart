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

  /// JSON 문자열에서 마크다운 코드 블록과 앞뒤 설명 문장을 제거합니다.
  static String cleanMarkdownJson(String jsonString) {
    var cleaned = jsonString.trim();

    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(_openingMarkdownFenceRegex, '')
          .replaceFirst(_closingMarkdownFenceRegex, '');
    }

    cleaned = cleaned.trim();
    return _extractJsonPayload(cleaned).trim();
  }

  static String _extractJsonPayload(String value) {
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      if (char != '[' && char != '{') continue;

      final payload = _balancedJsonSubstring(value, i);
      if (payload != null) return payload;
    }

    return value;
  }

  static String? _balancedJsonSubstring(String value, int start) {
    final expectedClosings = <String>[];
    var inString = false;
    var escaped = false;

    for (var i = start; i < value.length; i++) {
      final char = value[i];

      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (char == '\\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
        }
        continue;
      }

      if (char == '"') {
        inString = true;
      } else if (char == '[') {
        expectedClosings.add(']');
      } else if (char == '{') {
        expectedClosings.add('}');
      } else if (char == ']' || char == '}') {
        if (expectedClosings.isEmpty || expectedClosings.last != char) {
          return null;
        }
        expectedClosings.removeLast();
        if (expectedClosings.isEmpty) {
          return value.substring(start, i + 1);
        }
      }
    }

    return null;
  }

  static String _removeTrailingCommas(String value) {
    final buffer = StringBuffer();
    var inString = false;
    var escaped = false;

    for (var i = 0; i < value.length; i++) {
      final char = value[i];

      if (inString) {
        buffer.write(char);
        if (escaped) {
          escaped = false;
        } else if (char == '\\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
        }
        continue;
      }

      if (char == '"') {
        inString = true;
        buffer.write(char);
        continue;
      }

      if (char == ',') {
        var next = i + 1;
        while (next < value.length && value[next].trim().isEmpty) {
          next++;
        }
        if (next < value.length && (value[next] == ']' || value[next] == '}')) {
          continue;
        }
      }

      buffer.write(char);
    }

    return buffer.toString();
  }

  static List<dynamic> _extractRecommendationItems(dynamic decodedJson) {
    if (decodedJson is List) {
      return List<dynamic>.from(decodedJson);
    }

    if (decodedJson is Map) {
      const candidateKeys = ['recommendations', 'items', 'foods', 'results'];
      for (final key in candidateKeys) {
        final value = decodedJson[key];
        if (value is List) return List<dynamic>.from(value);
      }
    }

    throw const FormatException('추천 JSON 배열을 찾을 수 없습니다.');
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

    final cleanedJson = _removeTrailingCommas(cleanMarkdownJson(jsonString));

    LoggerService.d(
      'Cleaned JSON for parsing (first 200 chars): ${cleanedJson.substring(0, cleanedJson.length > 200 ? 200 : cleanedJson.length)}',
    );

    List<dynamic> decodedList;
    try {
      final decodedJson = jsonDecode(cleanedJson);
      decodedList = _extractRecommendationItems(decodedJson);
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

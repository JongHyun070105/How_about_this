import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:review_ai/models/exceptions.dart';
import 'package:review_ai/services/user_preference_service.dart';

class GeminiService {
  final http.Client _client;
  final String _apiKey;
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const Duration _timeout = Duration(seconds: 15);

  GeminiService(this._client, this._apiKey);

  Future<Map<String, dynamic>> _postContent(
    String model,
    Map<String, dynamic> requestBody,
  ) async {
    final url = Uri.parse('$_baseUrl/$model:generateContent?key=$_apiKey');

    try {
      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        debugPrint('Raw API Response: ${utf8.decode(response.bodyBytes)}');
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw GeminiApiException(
          utf8.decode(response.bodyBytes),
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw NetworkException('요청 시간이 초과되었습니다.');
    } on SocketException {
      throw NetworkException('인터넷 연결을 확인해주세요.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('알 수 없는 오류가 발생했습니다: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> generateContent(String prompt) async {
    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.4,
        'topK': 32,
        'topP': 0.9,
        'maxOutputTokens': 512,
      },
    };
    return await _postContent('gemini-2.5-flash-lite', requestBody);
  }

  Future<List<String>> generateReviews({
    required String foodName,
    required double deliveryRating,
    required double tasteRating,
    required double portionRating,
    required double priceRating,
    required String reviewStyle,
    File? foodImage,
  }) async {
    final prompt = _buildReviewPrompt(
      foodName: foodName,
      deliveryRating: deliveryRating,
      tasteRating: tasteRating,
      portionRating: portionRating,
      priceRating: priceRating,
      reviewStyle: reviewStyle,
      foodImage: foodImage,
    );

    try {
      Uint8List? imageBytes = foodImage != null
          ? await foodImage.readAsBytes()
          : null;
      final parts = await _buildParts(prompt, imageBytes);

      final requestBody = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 0.9,
          'maxOutputTokens': 512,
        },
      };

      final data = await _postContent('gemini-2.5-flash-lite', requestBody);

      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw ParsingException('API 응답에 후보가 없습니다.');
      }

      final content =
          candidates[0]['content']?['parts']?[0]?['text'] as String?;
      if (content == null) {
        throw ParsingException('리뷰 텍스트를 찾을 수 없습니다.');
      }

      try {
        // Clean the response to ensure it's valid JSON
        final cleanedContent = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final decoded = json.decode(cleanedContent) as List<dynamic>;
        final reviews = decoded.map((e) => e.toString()).toList();

        if (reviews.isEmpty) {
          throw ParsingException('유효한 리뷰가 생성되지 않았습니다.');
        }

        return reviews;
      } on FormatException catch (e) {
        throw ParsingException('API 응답을 파싱하는 데 실패했습니다: ${e.message}');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ParsingException('리뷰 생성 중 알 수 없는 오류: ${e.toString()}');
    }
  }

  Future<bool> validateImage(File foodImage) async {
    const prompt =
        'Analyze the attached image. Is this a picture of prepared food suitable for a food review? Do not consider raw ingredients like a single raw onion or a piece of raw meat as prepared food. Respond with only a JSON object in the format {"is_food": boolean}.';

    try {
      Uint8List imageBytes = await foodImage.readAsBytes();
      final parts = await _buildParts(prompt, imageBytes);

      final requestBody = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {'temperature': 0.0, 'maxOutputTokens': 10},
      };

      final data = await _postContent('gemini-2.5-flash-lite', requestBody);

      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw ImageValidationException('모델이 이미지를 분석할 수 없습니다.');
      }

      final content =
          candidates[0]['content']?['parts']?[0]?['text'] as String?;
      if (content == null) {
        throw ImageValidationException('모델의 응답을 파싱할 수 없습니다.');
      }

      try {
        // Clean the response to ensure it's valid JSON
        final cleanedContent = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final decoded = json.decode(cleanedContent) as Map<String, dynamic>;
        final isFood = decoded['is_food'] as bool?;

        if (isFood == true) {
          return true;
        } else {
          throw ImageValidationException('이 사진은 음식 사진이 아니거나 리뷰에 적합하지 않습니다.');
        }
      } on FormatException catch (e) {
        throw ImageValidationException('API 응답을 파싱하는 데 실패했습니다: ${e.message}');
      } catch (e) {
        // Catch other potential errors during parsing, like type errors
        throw ImageValidationException('이미지 검증 중 알 수 없는 오류: ${e.toString()}');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ImageValidationException('이미지 검증 중 알 수 없는 오류: ${e.toString()}');
    }
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return '매우좋음';
    if (rating >= 4.0) return '좋음';
    if (rating >= 3.5) return '보통';
    if (rating >= 3.0) return '아쉬움';
    if (rating >= 2.5) return '별로';
    return '나쁨';
  }

  Future<List<Map<String, dynamic>>> _buildParts(
    String prompt,
    Uint8List? imageBytes,
  ) async {
    List<Map<String, dynamic>> parts = [
      {'text': prompt},
    ];

    if (imageBytes != null) {
      if (imageBytes.length > 4 * 1024 * 1024) {
        throw ImageValidationException('이미지 크기가 너무 큽니다 (최대 4MB).');
      }
      final base64Image = base64Encode(imageBytes);
      parts.add({
        'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
      });
    }
    return parts;
  }

  String _buildReviewPrompt({
    required String foodName,
    required double deliveryRating,
    required double tasteRating,
    required double portionRating,
    required double priceRating,
    required String reviewStyle,
    File? foodImage,
  }) {
    String foodNameDescription = foodName;
    if (foodName.contains('아시아 음식')) {
      foodNameDescription = '$foodName (예: 똠양꿍, 팟타이, 베트남 쌀국수 등 동남아시아 요리 느낌으로)';
    }
    return '''
당신은 음식 리뷰 작성 전문가입니다.

아래 정보와 이미지를 바탕으로 음식 리뷰 3개를 작성하세요:

**음식 정보:**
- 사용자 입력 음식명: $foodNameDescription
- 배달: ${_getRatingText(deliveryRating)}
- 맛: ${_getRatingText(tasteRating)}
- 양: ${_getRatingText(portionRating)}
- 가격: ${_getRatingText(priceRating)}
- 리뷰 스타일: $reviewStyle

${foodImage != null ? '''
**이미지 기준 우선**: 이미지의 실제 음식과 입력된 음식명이 다르면 이미지를 우선하여 리뷰하세요.
''' : ''}

**리뷰 작성 규칙:**
1. 각 리뷰는 자연스럽고 구체적으로 작성
2. 별점이나 숫자 직접 언급 금지
3. 정확히 3개만 생성

**출력 형식:**
오직 순수 JSON 배열만. 설명/문장은 금지. 마크다운 금지.
["리뷰1", "리뷰2", "리뷰3"]''';
  }

  Future<String> buildPersonalizedRecommendationPrompt({
    required String category,
    required List<String> recentFoods,
  }) async {
    final analysis = await UserPreferenceService.analyzeUserPreferences();
    final dislikedFoods = await UserPreferenceService.getDislikedFoods();

    final basePrompt = '''
당신은 음식을 무엇을 먹을지 고민하는 사용자를 위한 개인화된 음식 추천 시스템입니다.

사용자 취향 분석:
''';

    String preferenceInfo = '';

    if (analysis.preferredFoods.isNotEmpty) {
      preferenceInfo +=
          '''
- 자주 좋아요를 누른 음식들: ${analysis.preferredFoods.join(', ')}
''';
      preferenceInfo += '''- 이런 음식들과 비슷한 맛이나 스타일의 음식을 우선 추천해주세요.
''';
    }

    if (dislikedFoods.isNotEmpty) {
      preferenceInfo +=
          '''
- 절대 추천하지 말아야 할 음식들: ${dislikedFoods.join(', ')}
''';
      preferenceInfo += '''- 위 음식들과 비슷한 음식도 피해주세요.
''';
    }

    if (analysis.preferredCategories.isNotEmpty && category == '상관없음') {
      preferenceInfo +=
          '''
- 선호하는 카테고리: ${analysis.preferredCategories.join(', ')}
''';
      preferenceInfo += '''- 가능하면 선호 카테고리에서 더 많이 추천해주세요.
''';
    }

    final recentFoodsText = recentFoods.isEmpty
        ? '''최근에 먹은 음식이 없습니다.'''
        : '''최근에 먹은 음식들: ${recentFoods.join(', ')} (이것들은 제외해주세요)''';

    final isAny = category == '상관없음';
    String categoryRule;

    if (isAny) {
      categoryRule = '카테고리 제약 없이 사용자 취향에 맞게 다양하게 추천하세요.';
    } else if (category == '아시안') {
      categoryRule =
          '요청된 카테고리는 "아시안"입니다. "아시안" 카테고리는 동남아시아(베트남, 태국, 인도네시아 등)와 남아시아(인도, 파키스탄 등) 음식을 포함합니다. **절대로 한식, 중식, 일식 메뉴를 포함해서는 안 됩니다.**';
    } else {
      categoryRule =
          '반드시 모든 항목이 정확히 "$category" 카테고리여야 합니다. 다른 카테고리는 절대 포함하지 마세요.';
    }

    final examples = '''
예시(출력에 포함하지 마세요):
- 한식: 김치찌개, 된장찌개, 비빔밥, 불고기, 제육볶음, 닭갈비, 갈비탕, 냉면
- 중식: 짜장면, 짬뽕, 탕수육, 마라탕, 마라샹궈, 꿔바로우, 마파두부, 깐풍기, 볶음밥, 딤섬, 훠궈, 우육면
- 일식: 스시, 사시미, 라멘, 우동, 돈카츠, 규동, 오코노미야키, 텐동, 야키토리
- 양식: 파스타, 피자, 스테이크, 리조또, 라자냐, 감바스 알 아히요
- 분식: 떡볶이, 순대, 오뎅, 김밥, 라볶이, 쫄면
- 아시안: 쌀국수, 팟타이, 똠얌꿍, 반미, 카오팟, 분짜, 나시고랭, 미고랭, 커리
- 패스트푸드: 햄버거, 프라이드치킨, 감자튀김, 핫도그, 나초, 타코
''';

    return '''
$basePrompt
$preferenceInfo

$recentFoodsText

요구사항:
- $categoryRule
- 한국에서 흔히 접할 수 있는 메뉴명만 사용하세요.
- 추천하는 메뉴들은 서로 다른 국가의, 다양한 종류의 음식으로 구성해주세요. 예를 들어, 쌀국수, 분짜, 나시고랭처럼 여러 국가의 대표 메뉴를 섞어주세요.
- 개수: 8-12개.
- 출력은 오직 순수 JSON 배열만. 설명/문장은 금지. 마크다운 금지.
- JSON 형식: [{ "name":"메뉴명"}, { "name":"메뉴명"}, ...]

$examples
이제 결과를 JSON 배열로만 출력하세요.
''';
  }

  String buildGenericRecommendationPrompt({required String category}) {
    final isAny = category == '상관없음';
    String categoryRule;

    if (isAny) {
      categoryRule = '다양한 카테고리에서 인기 있는 음식들을 추천해주세요.';
    } else if (category == '아시안') {
      categoryRule =
          '요청된 카테고리는 "아시안"입니다. "아시안" 카테고리는 동남아시아(베트남, 태국, 인도네시아 등)와 남아시아(인도, 파키스탄 등) 음식을 포함합니다. **절대로 한식, 중식, 일식 메뉴를 포함해서는 안 됩니다.**';
    } else {
      categoryRule =
          '반드시 모든 항목이 정확히 "$category" 카테고리여야 합니다. 다른 카테고리는 절대 포함하지 마세요.';
    }

    final examples = '''
예시(출력에 포함하지 마세요):
- 한식: 김치찌개, 된장찌개, 비빔밥, 불고기, 제육볶음, 닭갈비, 갈비탕, 냉면
- 중식: 짜장면, 짬뽕, 탕수육, 마라탕, 마라샹궈, 꿔바로우, 마파두부, 깐풍기, 볶음밥, 딤섬, 훠궈, 우육면
- 일식: 스시, 사시미, 라멘, 우동, 돈카츠, 규동, 오코노미야키, 텐동, 야키토리
- 양식: 파스타, 피자, 스테이크, 리조또, 라자냐, 감바스 알 아히요
- 분식: 떡볶이, 순대, 오뎅, 김밥, 라볶이, 쫄면
- 아시안: 쌀국수, 팟타이, 똠얌꿍, 반미, 카오팟, 분짜, 나시고랭, 미고랭, 커리
- 패스트푸드: 햄버거, 프라이드치킨, 감자튀김, 핫도그, 나초, 타코
''';

    return '''
당신은 특정 카테고리의 음식 메뉴를 추천하는 시스템입니다.

요구사항:
- $categoryRule
- 사용자 개인 취향은 고려하지 말고, 해당 카테고리에서 가장 대표적이고 인기 있는 메뉴들을 추천해주세요.
- 한국에서 흔히 접할 수 있는 메뉴명만 사용하세요.
- 매우 다양한 종류의 음식으로 구성해주세요.
- 개수: 15-20개.
- 출력은 오직 순수 JSON 배열만. 설명/문장은 금지. 마크다운 금지.
- JSON 형식: [{ "name":"메뉴명"}, { "name":"메뉴명"}, ...]

$examples
이제 결과를 JSON 배열로만 출력하세요.
''';
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static Future<List<String>> generateReviews({
    required String foodName,
    required double deliveryRating,
    required double tasteRating,
    required double portionRating,
    required double priceRating,
    required String reviewStyle,
    File? foodImage,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('API Key not found in .env file');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=$apiKey',
    );

    final prompt =
        '''
당신은 음식 리뷰 작성 전문가입니다.

아래 정보와 이미지를 바탕으로 음식 리뷰 3개를 작성하세요:

**음식 정보:**
- 사용자 입력 음식명: $foodName
- 배달: ${_getRatingText(deliveryRating)}
- 맛: ${_getRatingText(tasteRating)} 
- 양: ${_getRatingText(portionRating)}
- 가격: ${_getRatingText(priceRating)}
- 리뷰 스타일: $reviewStyle

${foodImage != null ? '''
**이미지 기준 우선**: 이미지의 실제 음식과 입력된 음식명이 다르면 이미지를 우선하여 리뷰하세요.
''' : ''}

**리뷰 작성 규칙:**
1. 각 리뷰는 "- "로 시작
2. 자연스럽고 구체적으로 작성
3. 별점이나 숫자 직접 언급 금지
4. 정확히 3개만 출력

**출력 형식:**
- [리뷰1]
- [리뷰2] 
- [리뷰3]''';

    try {
      final parts = await _buildParts(prompt, foodImage);

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

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('API 응답에 후보가 없습니다');
        }

        final content = 
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        final cleanContent = content.trim();

        final reviews = cleanContent
            .split('\n')
            .where((line) => line.trim().startsWith('- '))
            .map((line) {
              final reviewText = line.substring(line.indexOf('- ') + 2).trim();
              return reviewText.isEmpty ? null : reviewText;
            })
            .where((review) => review != null)
            .cast<String>()
            .toList();

        if (reviews.isEmpty) {
          throw Exception('유효한 리뷰가 생성되지 않았습니다');
        }

        return reviews.length >= 3 ? reviews.take(3).toList() : reviews;
      } else {
        throw Exception('API 호출 실패 (${response.statusCode})');
      }
    } on FormatException {
      throw Exception('응답 파싱 실패');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('알 수 없는 오류: $e');
    }
  }

  static String _getRatingText(double rating) {
    if (rating >= 4.5) return '매우좋음';
    if (rating >= 4.0) return '좋음';
    if (rating >= 3.5) return '보통';
    if (rating >= 3.0) return '아쉬움';
    if (rating >= 2.5) return '별로';
    return '나쁨';
  }

  static Future<List<Map<String, dynamic>>> _buildParts(
    String prompt,
    File? imageFile,
  ) async {
    List<Map<String, dynamic>> parts = [
      {'text': prompt},
    ];

    if (imageFile != null) {
      try {
        final imageBytes = await imageFile.readAsBytes();

        if (imageBytes.length > 4 * 1024 * 1024) {
          throw Exception('이미지 크기가 너무 큽니다 (최대 4MB)');
        }

        final base64Image = base64Encode(imageBytes);

        String mimeType = 'image/jpeg';
        final extension = imageFile.path.split('.').last.toLowerCase();
        if (extension == 'png') {
          mimeType = 'image/png';
        } else if (extension == 'webp') {
          mimeType = 'image/webp';
        }

        parts.add({
          'inline_data': {'mime_type': mimeType, 'data': base64Image},
        });
      } catch (e) {
        throw Exception('이미지 처리 실패: $e');
      }
    }

    return parts;
  }

  static Future<bool> validateImage(File foodImage) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('API Key not found in .env file');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=$apiKey',
    );

    const prompt =
        'Analyze the attached image. Is this a picture of prepared food suitable for a food review? Answer with only "YES" or "NO". Do not consider raw ingredients like a single raw onion or a piece of raw meat as prepared food.';

    try {
      final parts = await _buildParts(prompt, foodImage);

      final requestBody = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {
          'temperature': 0.0,
          'maxOutputTokens': 5,
        },
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('부적절한 이미지: 모델이 이미지를 분석할 수 없습니다.');
        }

        final content = 
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        final cleanContent = content.trim().toUpperCase();

        if (cleanContent.contains('YES')) {
          return true;
        } else {
          throw Exception('부적절한 이미지: 이 사진은 음식 사진이 아니거나 리뷰에 적합하지 않습니다.');
        }
      } else {
        throw Exception('이미지 검증 API 호출 실패 (${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('이미지 검증 중 알 수 없는 오류: $e');
    }
  }
}
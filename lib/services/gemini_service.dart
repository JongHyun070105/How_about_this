import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For Uint8List
import 'package:reviewai_flutter/services/gemini_api_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Keep for now, might be needed for initialization elsewhere

class GeminiService {
  final GeminiApiClient _apiClient;

  GeminiService(this._apiClient);

  Future<List<String>> generateReviews({
    required String foodName,
    required double deliveryRating,
    required double tasteRating,
    required double portionRating,
    required double priceRating,
    required String reviewStyle,
    File? foodImage,
  }) async {
    String foodNameDescription = foodName;
    if (foodName.contains('아시아 음식')) {
      foodNameDescription = '$foodName (예: 똠양꿍, 팟타이, 베트남 쌀국수 등 동남아시아 요리 느낌으로)';
    }

    final prompt =
        '''
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
1. 각 리뷰는 "- "로 시작
2. 자연스럽고 구체적으로 작성
3. 별점이나 숫자 직접 언급 금지
4. 정확히 3개만 출력

**출력 형식:**
- [리뷰1]
- [리뷰2]
- [리뷰3]''';

    try {
      Uint8List? imageBytes;
      if (foodImage != null) {
        imageBytes = await foodImage.readAsBytes();
      }
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

      final data = await _apiClient.postContent(
        'gemini-2.5-flash-lite',
        requestBody,
      );

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
    } on FormatException catch (e) {
      throw Exception('응답 파싱 실패: $e');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('알 수 없는 오류: $e');
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
      try {
        if (imageBytes.length > 4 * 1024 * 1024) {
          throw Exception('이미지 크기가 너무 큽니다 (최대 4MB)');
        }

        final base64Image = base64Encode(imageBytes);

        // Determine mime type based on the first few bytes (magic numbers)
        // This is a more robust way than relying on file extension.
        String mimeType = 'application/octet-stream'; // Default to generic
        if (imageBytes.length >= 4) {
          final header = imageBytes.sublist(0, 4);
          if (header[0] == 0x89 &&
              header[1] == 0x50 &&
              header[2] == 0x4E &&
              header[3] == 0x47) {
            mimeType = 'image/png';
          } else if (header[0] == 0xFF &&
              header[1] == 0xD8 &&
              header[2] == 0xFF) {
            mimeType = 'image/jpeg';
          } else if (header[0] == 0x52 &&
              header[1] == 0x49 &&
              header[2] == 0x46 &&
              header[3] == 0x46) {
            // RIFF header, check for WEBP
            if (imageBytes.length >= 12 &&
                imageBytes[8] == 0x57 &&
                imageBytes[9] == 0x45 &&
                imageBytes[10] == 0x42 &&
                imageBytes[11] == 0x50) {
              mimeType = 'image/webp';
            }
          }
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

  Future<bool> validateImage(File foodImage) async {
    const prompt =
        'Analyze the attached image. Is this a picture of prepared food suitable for a food review? Answer with only "YES" or "NO". Do not consider raw ingredients like a single raw onion or a piece of raw meat as prepared food.';

    try {
      Uint8List? imageBytes = await foodImage.readAsBytes();
      final parts = await _buildParts(prompt, imageBytes);

      final requestBody = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {'temperature': 0.0, 'maxOutputTokens': 5},
      };

      final data = await _apiClient.postContent(
        'gemini-2.5-flash-lite',
        requestBody,
      );

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
    } on FormatException catch (e) {
      throw Exception('응답 파싱 실패: $e');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('이미지 검증 중 알 수 없는 오류: $e');
    }
  }
}

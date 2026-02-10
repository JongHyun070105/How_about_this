import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:review_ai/models/exceptions.dart';
import 'package:review_ai/services/prompt_builder.dart';
import 'package:review_ai/services/auth_service.dart';
import 'package:review_ai/config/api_config.dart';
import '../utils/error_handler.dart';

/// Cloudflare Workers API 프록시 서버를 통한 Gemini API 호출 서비스
class ApiProxyService {
  final http.Client _client;
  final String _proxyUrl;
  final Future<String?> Function()? _tokenProvider;

  ApiProxyService(
    this._client,
    this._proxyUrl, {
    Future<String?> Function()? tokenProvider,
  }) : _tokenProvider = tokenProvider;

  /// 프록시 서버를 통한 Gemini API 호출 (JWT 인증 사용)
  Future<Map<String, dynamic>> _callGeminiApi(
    String endpoint,
    Map<String, dynamic> requestBody,
  ) async {
    final url = Uri.parse('$_proxyUrl/api/gemini-proxy');

    try {
      // JWT 토큰 가져오기 (주입된 provider가 있으면 사용, 없으면 기본 AuthService 사용)
      final accessToken = _tokenProvider != null
          ? await _tokenProvider()
          : await AuthService.getValidAccessToken();

      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'endpoint': endpoint,
              'requestBody': requestBody,
            }),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        if (kDebugMode) {
          debugPrint(
            'Proxy API Response received (length: ${responseBody.length})',
          );
        }
        return jsonDecode(responseBody);
      } else {
        // 에러 응답 처리 - JSON이 아닐 수도 있음
        final responseBody = utf8.decode(response.bodyBytes);
        if (kDebugMode) {
          debugPrint(
            'API Error Response (${response.statusCode}): $responseBody',
          );
        }

        // JSON 파싱 시도
        try {
          final errorData = jsonDecode(responseBody);
          throw GeminiApiException(
            errorData['details'] ?? errorData['error'] ?? 'API 호출 실패',
            statusCode: response.statusCode,
          );
        } catch (e) {
          // JSON 파싱 실패 시 로그만 남기고 사용자에게는 일반 메시지
          debugPrint(
            'API Error Response (non-JSON): ${responseBody.length > 100 ? responseBody.substring(0, 100) : responseBody}',
          );
          throw GeminiApiException(
            'API 서버 응답 오류가 발생했습니다.',
            statusCode: response.statusCode,
          );
        }
      }
    } on TimeoutException {
      throw NetworkException('요청 시간이 초과되었습니다.');
    } on SocketException {
      throw NetworkException('인터넷 연결을 확인해주세요.');
    } catch (e) {
      debugPrint('ApiProxyService Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException(ErrorHandler.sanitizeMessage(e));
    }
  }

  /// 콘텐츠 생성
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
        'temperature': 0.0,
        'topK': 10,
        'topP': 0.6,
        'maxOutputTokens': 2048,
      },
    };
    return await _callGeminiApi('generateContent', requestBody);
  }

  /// 리뷰 생성
  Future<List<String>> generateReviews({
    required String foodName,
    required double deliveryRating,
    required double tasteRating,
    required double portionRating,
    required double priceRating,
    required String reviewStyle,
    File? foodImage,
  }) async {
    final prompt = PromptBuilder.buildReviewPrompt(
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
          'temperature': 0.3,
          'topK': 40,
          'topP': 0.8,
          'maxOutputTokens': 512,
        },
      };

      final data = await _callGeminiApi('generateContent', requestBody);

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
        var cleanedContent = content.trim();

        if (cleanedContent.startsWith('```json')) {
          cleanedContent = cleanedContent
              .replaceAll('```json', '')
              .replaceAll('```', '');
        } else if (cleanedContent.startsWith('```')) {
          cleanedContent = cleanedContent.replaceAll('```', '');
        }

        cleanedContent = cleanedContent.trim();

        final decoded = json.decode(cleanedContent) as List<dynamic>;
        final reviews = decoded.map((e) => e.toString()).toList();

        if (reviews.isEmpty) {
          throw ParsingException('유효한 리뷰가 생성되지 않았습니다.');
        }

        return reviews;
      } on FormatException {
        throw ParsingException('API 응답 형식이 올바르지 않습니다.');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ParsingException('리뷰 생성 중 오류가 발생했습니다.');
    }
  }

  /// 이미지 검증
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

      final data = await _callGeminiApi('generateContent', requestBody);

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
        var cleanedContent = content.trim();

        if (cleanedContent.startsWith('```json')) {
          cleanedContent = cleanedContent
              .replaceAll('```json', '')
              .replaceAll('```', '');
        } else if (cleanedContent.startsWith('```')) {
          cleanedContent = cleanedContent.replaceAll('```', '');
        }

        cleanedContent = cleanedContent.trim();

        final decoded = json.decode(cleanedContent) as Map<String, dynamic>;
        final isFood = decoded['is_food'] as bool?;

        if (isFood == true) {
          return true;
        } else {
          throw ImageValidationException('이 사진은 음식 사진이 아니거나 리뷰에 적합하지 않습니다.');
        }
      } on FormatException {
        throw ImageValidationException('이미지 분석 결과를 처리하는 데 실패했습니다.');
      } catch (e) {
        throw ImageValidationException('이미지 검증 중 오류가 발생했습니다.');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ImageValidationException('이미지 검증 중 오류가 발생했습니다.');
    }
  }

  /// 음식 이미지 분석 (Vision AI)
  Future<String> analyzeFoodImage(File foodImage) async {
    const prompt =
        'Analyze this image. Is it food? If NO, return "NOT_FOOD". If YES, return its name in Korean. Return ONLY the name or "NOT_FOOD". Do not add any punctuation or extra words.';

    try {
      Uint8List imageBytes = await foodImage.readAsBytes();
      final parts = await _buildParts(prompt, imageBytes);

      final requestBody = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {'temperature': 0.0, 'maxOutputTokens': 20},
      };

      final data = await _callGeminiApi('generateContent', requestBody);

      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw ParsingException('모델이 이미지를 분석할 수 없습니다.');
      }

      final content =
          candidates[0]['content']?['parts']?[0]?['text'] as String?;
      if (content == null) {
        throw ParsingException('모델의 응답을 파싱할 수 없습니다.');
      }

      return content.trim();
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Vision AI Error: $e');
      throw ParsingException('이미지 분석 중 오류가 발생했습니다.');
    }
  }

  /// 개인화된 추천 프롬프트 생성 (PromptBuilder에 위임)
  Future<String> buildPersonalizedRecommendationPrompt({
    required String category,
    required List<String> recentFoods,
  }) {
    return PromptBuilder.buildPersonalizedRecommendationPrompt(
      category: category,
      recentFoods: recentFoods,
    );
  }

  /// 이미지 파트 구성
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
}

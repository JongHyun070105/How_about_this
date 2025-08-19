import 'dart:convert';
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
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('API Key not found in .env file');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final prompt =
        '''
    You are a helpful assistant, a food lover, and an expert at writing compelling reviews in natural-sounding Korean.

    Based on the following information, please generate 3 distinct and creative reviews.

    **Food Information:**
    - Food Name: $foodName
    - Delivery Rating: ${deliveryRating.toStringAsFixed(1)}/5.0
    - Taste Rating: ${tasteRating.toStringAsFixed(1)}/5.0
    - Portion Size Rating: ${portionRating.toStringAsFixed(1)}/5.0
    - Price Rating: ${priceRating.toStringAsFixed(1)}/5.0
    - Desired Review Style: $reviewStyle

    **Instructions:**
    1. Analyze the combination of ratings to create nuanced reviews. For example, if the taste is excellent but the price is high, the review should reflect this trade-off. If the portion size is generous but the delivery was slow, mention that.
    2. Write three completely different reviews based on the requested style.
    3. Each review MUST start with a hyphen and a space ('- ')
    4. Do NOT add any introductory text, closing remarks, or any other text besides the three reviews.

    **Example Output:**
    - [Review 1]
    - [Review 2]
    - [Review 3]
    ''';

    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.9,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        final reviews = content
            .split('\n')
            .where((line) => line.startsWith('- '))
            .map((e) => e.substring(2))
            .toList();
        return reviews.isNotEmpty ? reviews : ['리뷰 생성에 실패했습니다. 다시 시도해주세요.'];
      } else {
        return ['API 오류가 발생했습니다. 상태 코드: ${response.statusCode}'];
      }
    } catch (e) {
      return ['리뷰 생성 중 오류가 발생했습니다.'];
    }
  }
}

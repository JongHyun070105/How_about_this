import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:reviewai_flutter/providers/food_providers.dart';

class RecommendationService {
  static final _apiKey = dotenv.env['GEMINI_API_KEY'];

  static Future<List<FoodRecommendation>> getFoodRecommendations({
    required String category,
    required List<String> history,
  }) async {
    if (_apiKey == null) {
      throw Exception('API 키가 없습니다. .env 파일을 확인하세요.');
    }

    // 사용 중인 패키지 버전에 따라 responseMimeType 설정이 가능하면 아래 주석 해제
    // final model = GenerativeModel(
    //   model: 'gemini-1.5-flash',
    //   apiKey: _apiKey!,
    //   generationConfig: GenerationConfig(
    //     responseMimeType: 'application/json',
    //     temperature: 0.6,
    //   ),
    // );

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey!);

    final prompt = _buildPrompt(category, history);

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

      return decodedList
          .map((item) => FoodRecommendation.fromJson(item))
          .toList();
    } catch (e) {
      print('Gemini API 호출 또는 파싱 오류: $e');
      return Future.error('음식 추천을 받아오는 데 실패했습니다. 다시 시도해주세요.');
    }
  }

  static String _buildPrompt(String category, List<String> history) {
    final historyText = history.isEmpty
        ? '최근에 먹은 음식이 없습니다.'
        : '최근에 먹은 음식들은 다음과 같습니다: ${history.join(', ')}';

    // 카테고리 제약 문구를 더 강하게
    final isAny = category == '상관없음';
    final categoryRule = isAny
        ? '카테고리 제약 없이 다양하게 추천하세요.'
        : '반드시 모든 항목이 정확히 "$category" 카테고리여야 합니다. 다른 카테고리(한식/일식/양식/분식/아시안/패스트푸드 등)는 절대 포함하지 마세요.';

    // 참고 예시로 모델을 바이어스 (출력에 포함 X)
    final examples = '''
예시(출력에 포함하지 마세요):
- 한식: 김치찌개, 된장찌개, 비빔밥, 불고기, 갈비탕, 냉면
- 중식: 짜장면, 짬뽕, 탕수육, 마라탕, 마라샹궈, 꿔바로우, 마파두부, 깐풍기, 볶음밥, 딤섬, 훠궈, 우육면
- 일식: 스시, 사시미, 라멘, 우동, 돈카츠, 규동, 오코노미야키
- 양식: 파스타, 피자, 스테이크, 리조또, 라자냐
- 분식: 떡볶이, 순대, 오뎅, 김밥, 라볶이
- 아시안: 쌀국수, 팟타이, 똠얌꿍, 반미, 카오팟
- 패스트푸드: 햄버거, 프라이드치킨, 감자튀김, 핫도그, 나초
''';

    return '''
당신은 음식을 무엇을 먹을지 고민하는 사용자를 위한 음식 추천 시스템입니다.
$historyText

요구사항:
- $categoryRule
- 한국에서 흔히 접할 수 있는 메뉴명만 사용하세요.
- 유사/중복 메뉴는 피하고 다양성을 유지하세요.
- 개수: 5~8개.
- 출력은 오직 순수 JSON 배열만. 설명/문장은 금지. 마크다운 금지.
- JSON 형식: [{"name":"메뉴명"}, {"name":"메뉴명"}, ...]

$examples
이제 결과를 JSON 배열로만 출력하세요.
''';
  }
}

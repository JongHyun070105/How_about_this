import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/utils/gemini_response_parser.dart';
import 'package:review_ai/data/models/food_recommendation.dart';

void main() {
  group('GeminiResponseParser', () {
    group('extractText', () {
      test('정상적인 응답에서 텍스트를 추출한다', () {
        final response = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Hello World'},
                ],
              },
            },
          ],
        };

        expect(GeminiResponseParser.extractText(response), 'Hello World');
      });

      test('candidates가 없으면 null을 반환한다', () {
        final response = <String, dynamic>{};
        expect(GeminiResponseParser.extractText(response), isNull);
      });

      test('candidates가 빈 리스트이면 null을 반환한다', () {
        final response = {'candidates': []};
        expect(GeminiResponseParser.extractText(response), isNull);
      });

      test('text가 없으면 null을 반환한다', () {
        final response = {
          'candidates': [
            {
              'content': {
                'parts': [{}],
              },
            },
          ],
        };
        expect(GeminiResponseParser.extractText(response), isNull);
      });
    });

    group('cleanMarkdownJson', () {
      test('```json 코드 블록을 제거한다', () {
        const input = '```json\n[{"name": "치킨"}]\n```';
        final result = GeminiResponseParser.cleanMarkdownJson(input);
        expect(result, '[{"name": "치킨"}]');
      });

      test('``` 코드 블록을 제거한다', () {
        const input = '```\n[{"name": "피자"}]\n```';
        final result = GeminiResponseParser.cleanMarkdownJson(input);
        expect(result, '[{"name": "피자"}]');
      });

      test('코드 블록이 없으면 그대로 반환한다', () {
        const input = '[{"name": "김밥"}]';
        final result = GeminiResponseParser.cleanMarkdownJson(input);
        expect(result, '[{"name": "김밥"}]');
      });

      test('앞뒤 공백을 제거한다', () {
        const input = '  [{"name": "라면"}]  ';
        final result = GeminiResponseParser.cleanMarkdownJson(input);
        expect(result, '[{"name": "라면"}]');
      });
    });

    group('parseRecommendations', () {
      test('정상 응답을 FoodRecommendation 리스트로 파싱한다', () {
        final response = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text':
                        '[{"name": "김치찌개", "imageUrl": ""}, {"name": "된장찌개", "imageUrl": ""}]',
                  },
                ],
              },
            },
          ],
        };

        final result = GeminiResponseParser.parseRecommendations(response);
        expect(result.length, 2);
        expect(result[0].name, '김치찌개');
        expect(result[1].name, '된장찌개');
      });

      test('숫자 접두사가 있는 이름을 정리한다', () {
        final response = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text':
                        '[{"name": "1. 삼겹살", "imageUrl": ""}, {"name": "2. 냉면", "imageUrl": ""}]',
                  },
                ],
              },
            },
          ],
        };

        final result = GeminiResponseParser.parseRecommendations(response);
        expect(result[0].name, '삼겹살');
        expect(result[1].name, '냉면');
      });

      test('마크다운 코드 블록으로 감싼 응답을 파싱한다', () {
        final response = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': '```json\n[{"name": "우동", "imageUrl": ""}]\n```'},
                ],
              },
            },
          ],
        };

        final result = GeminiResponseParser.parseRecommendations(response);
        expect(result.length, 1);
        expect(result[0].name, '우동');
      });

      test('텍스트가 없는 응답은 예외를 던진다', () {
        final response = {
          'candidates': [
            {
              'content': {
                'parts': [{}],
              },
            },
          ],
        };

        expect(
          () => GeminiResponseParser.parseRecommendations(response),
          throwsException,
        );
      });
    });
  });

  group('FoodRecommendation', () {
    test('fromJson으로 생성된다', () {
      final json = {'name': '비빔밥', 'imageUrl': 'https://example.com/img.jpg'};
      final food = FoodRecommendation.fromJson(json);
      expect(food.name, '비빔밥');
      expect(food.imageUrl, 'https://example.com/img.jpg');
    });

    test('toJson으로 직렬화된다', () {
      const food = FoodRecommendation(
        name: '갈비탕',
        imageUrl: 'https://example.com/galbitang.jpg',
      );
      final json = food.toJson();
      expect(json['name'], '갈비탕');
      expect(json['imageUrl'], 'https://example.com/galbitang.jpg');
    });
  });
}

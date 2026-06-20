import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:review_ai/services/auth_service.dart';
import 'package:review_ai/services/food_insight_service.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';

/// FoodInsightService 테스트
///
/// 식습관 분석 서비스의 모든 핵심 기능을 검증합니다.
void main() {
  /// 테스트용 ReviewHistoryEntry 생성 헬퍼
  ReviewHistoryEntry createEntry({
    String foodName = '김치찌개',
    String category = '한식',
    double tasteRating = 4.0,
    double deliveryRating = 4.0,
    double portionRating = 3.5,
    double priceRating = 3.0,
    DateTime? createdAt,
  }) {
    return ReviewHistoryEntry(
      foodName: foodName,
      category: category,
      tasteRating: tasteRating,
      deliveryRating: deliveryRating,
      portionRating: portionRating,
      priceRating: priceRating,
      reviewStyle: '일반',
      generatedReviews: ['좋은 리뷰'],
      createdAt: createdAt,
    );
  }

  group('getCategoryFrequency', () {
    test('빈 히스토리에서 빈 맵 반환', () {
      final result = FoodInsightService.getCategoryFrequency([]);
      expect(result, isEmpty);
    });

    test('카테고리별 빈도를 정확하게 집계', () {
      final history = [
        createEntry(category: '한식'),
        createEntry(category: '한식'),
        createEntry(category: '중식'),
        createEntry(category: '일식'),
        createEntry(category: '중식'),
        createEntry(category: '한식'),
      ];

      final result = FoodInsightService.getCategoryFrequency(history);

      expect(result['한식'], 3);
      expect(result['중식'], 2);
      expect(result['일식'], 1);
    });

    test('빈도 내림차순으로 정렬', () {
      final history = [
        createEntry(category: '일식'),
        createEntry(category: '한식'),
        createEntry(category: '한식'),
        createEntry(category: '한식'),
        createEntry(category: '중식'),
        createEntry(category: '중식'),
      ];

      final result = FoodInsightService.getCategoryFrequency(history);
      final keys = result.keys.toList();

      expect(keys[0], '한식'); // 3회
      expect(keys[1], '중식'); // 2회
      expect(keys[2], '일식'); // 1회
    });

    test('빈 카테고리는 기타로 분류', () {
      final history = [createEntry(category: '')];

      final result = FoodInsightService.getCategoryFrequency(history);
      expect(result['기타'], 1);
    });
  });

  group('getTopFoods', () {
    test('빈 히스토리에서 빈 리스트 반환', () {
      final result = FoodInsightService.getTopFoods([]);
      expect(result, isEmpty);
    });

    test('음식별 빈도를 정확하게 집계', () {
      final history = [
        createEntry(foodName: '김치찌개'),
        createEntry(foodName: '김치찌개'),
        createEntry(foodName: '된장찌개'),
        createEntry(foodName: '김치찌개'),
        createEntry(foodName: '비빔밥'),
      ];

      final result = FoodInsightService.getTopFoods(history);

      expect(result[0]['foodName'], '김치찌개');
      expect(result[0]['count'], 3);
      expect(result[1]['foodName'], '된장찌개');
      expect(result[1]['count'], 1);
    });

    test('limit 파라미터로 결과 수 제한', () {
      final history = [
        createEntry(foodName: '김치찌개'),
        createEntry(foodName: '된장찌개'),
        createEntry(foodName: '비빔밥'),
        createEntry(foodName: '불고기'),
        createEntry(foodName: '갈비탕'),
        createEntry(foodName: '떡볶이'),
      ];

      final result = FoodInsightService.getTopFoods(history, limit: 3);
      expect(result.length, 3);
    });

    test('빈 음식명은 무시', () {
      final history = [
        createEntry(foodName: ''),
        createEntry(foodName: '김치찌개'),
      ];

      final result = FoodInsightService.getTopFoods(history);
      expect(result.length, 1);
      expect(result[0]['foodName'], '김치찌개');
    });
  });

  group('getRecentEntries', () {
    test('최근 7일 이내 항목만 반환', () {
      final now = DateTime.now();
      final history = [
        createEntry(createdAt: now.subtract(const Duration(days: 1))),
        createEntry(createdAt: now.subtract(const Duration(days: 3))),
        createEntry(createdAt: now.subtract(const Duration(days: 10))),
        createEntry(createdAt: now.subtract(const Duration(days: 30))),
      ];

      final result = FoodInsightService.getRecentEntries(history, days: 7);
      expect(result.length, 2);
    });

    test('기간 파라미터 정상 동작', () {
      final now = DateTime.now();
      final history = [
        createEntry(createdAt: now.subtract(const Duration(days: 1))),
        createEntry(createdAt: now.subtract(const Duration(days: 5))),
        createEntry(createdAt: now.subtract(const Duration(days: 15))),
        createEntry(createdAt: now.subtract(const Duration(days: 35))),
      ];

      final result30 = FoodInsightService.getRecentEntries(history, days: 30);
      expect(result30.length, 3);

      final result3 = FoodInsightService.getRecentEntries(history, days: 3);
      expect(result3.length, 1);
    });
  });

  group('getRecentStreak', () {
    test('1개 이하 히스토리에서 null 반환', () {
      expect(FoodInsightService.getRecentStreak([]), isNull);
      expect(FoodInsightService.getRecentStreak([createEntry()]), isNull);
    });

    test('연속 동일 카테고리 감지', () {
      final now = DateTime.now();
      final history = [
        createEntry(
          category: '한식',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        createEntry(
          category: '한식',
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
        createEntry(
          category: '한식',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        createEntry(
          category: '중식',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      final result = FoodInsightService.getRecentStreak(history);

      expect(result, isNotNull);
      expect(result!['category'], '한식');
      expect(result['count'], 3);
    });

    test('연속이 아닌 경우 null 반환', () {
      final now = DateTime.now();
      final history = [
        createEntry(
          category: '한식',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        createEntry(
          category: '중식',
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
      ];

      final result = FoodInsightService.getRecentStreak(history);
      expect(result, isNull);
    });
  });

  group('getAverageRatings', () {
    test('빈 히스토리에서 모든 값 0 반환', () {
      final result = FoodInsightService.getAverageRatings([]);

      expect(result['taste'], 0);
      expect(result['delivery'], 0);
      expect(result['portion'], 0);
      expect(result['price'], 0);
    });

    test('평균 별점 정확하게 계산', () {
      final history = [
        createEntry(
          tasteRating: 5.0,
          deliveryRating: 4.0,
          portionRating: 3.0,
          priceRating: 2.0,
        ),
        createEntry(
          tasteRating: 3.0,
          deliveryRating: 2.0,
          portionRating: 5.0,
          priceRating: 4.0,
        ),
      ];

      final result = FoodInsightService.getAverageRatings(history);

      expect(result['taste'], 4.0);
      expect(result['delivery'], 3.0);
      expect(result['portion'], 4.0);
      expect(result['price'], 3.0);
    });
  });

  group('generateInsightMessage', () {
    test('빈 히스토리에서 기본 메시지 반환', () {
      final result = FoodInsightService.generateInsightMessage([]);
      expect(result, contains('첫 리뷰'));
    });

    test('히스토리가 있으면 비어있지 않은 메시지 반환', () {
      final history = [
        createEntry(foodName: '김치찌개', category: '한식'),
        createEntry(foodName: '된장찌개', category: '한식'),
        createEntry(foodName: '비빔밥', category: '한식'),
      ];

      final result = FoodInsightService.generateInsightMessage(history);
      expect(result, isNotEmpty);
      expect(result.length, greaterThan(5));
    });

    test('연속 카테고리가 있으면 대안 제안 포함', () {
      final now = DateTime.now();
      final history = [
        createEntry(
          category: '한식',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        createEntry(
          category: '한식',
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
        createEntry(
          category: '한식',
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
      ];

      // 여러 번 호출해서 연속 카테고리 메시지가 나오는지 확인
      // (랜덤 선택이므로 통계적으로 확인)
      final messages = List.generate(
        20,
        (_) => FoodInsightService.generateInsightMessage(history),
      );

      // 최소 하나의 메시지에 '한식' 또는 '연속' 관련 내용이 있어야 함
      final hasRelevantMessage = messages.any(
        (m) => m.contains('한식') || m.contains('연속') || m.contains('이번 주'),
      );
      expect(hasRelevantMessage, isTrue);
    });
  });

  group('generateSummary', () {
    test('빈 히스토리에서 기본 요약 반환', () {
      final result = FoodInsightService.generateSummary([]);

      expect(result['totalReviews'], 0);
      expect(result['weeklyCount'], 0);
      expect(result['favoriteCategory'], isNull);
      expect(result['streak'], isNull);
    });

    test('전체 요약 정보 정확하게 생성', () {
      final now = DateTime.now();
      final history = [
        createEntry(
          foodName: '김치찌개',
          category: '한식',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        createEntry(
          foodName: '짜장면',
          category: '중식',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        createEntry(
          foodName: '김치찌개',
          category: '한식',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        createEntry(
          foodName: '초밥',
          category: '일식',
          createdAt: now.subtract(const Duration(days: 10)),
        ),
      ];

      final result = FoodInsightService.generateSummary(history);

      expect(result['totalReviews'], 4);
      expect(result['weeklyCount'], 3); // 최근 7일: 3개
      expect(result['favoriteCategory'], '한식'); // 2회로 1위
      expect(result['insightMessage'], isNotEmpty);

      final categoryFreq = result['categoryFrequency'] as Map<String, int>;
      expect(categoryFreq['한식'], 2);
      expect(categoryFreq['중식'], 1);
      expect(categoryFreq['일식'], 1);

      final topFoods = result['topFoods'] as List<Map<String, dynamic>>;
      expect(topFoods[0]['foodName'], '김치찌개');
      expect(topFoods[0]['count'], 2);
    });
  });

  group('categoryEmojis', () {
    test('주요 카테고리에 이모지 매핑 존재', () {
      expect(FoodInsightService.categoryEmojis['한식'], '🍚');
      expect(FoodInsightService.categoryEmojis['중식'], '🥟');
      expect(FoodInsightService.categoryEmojis['일식'], '🍣');
      expect(FoodInsightService.categoryEmojis['양식'], '🍝');
      expect(FoodInsightService.categoryEmojis['패스트푸드'], '🍔');
    });
  });

  group('inferCategory 테스트', () {
    setUp(() {
      AuthService.setMockToken(
        accessToken: 'test_token',
        expiry: DateTime.now().add(const Duration(hours: 1)),
      );
    });

    tearDown(() {
      AuthService.setMockToken(
        accessToken: null,
        refreshToken: null,
        expiry: null,
      );
    });

    test('음식명이 비어있을 때 즉시 기타 반환', () async {
      final result = await FoodInsightService.inferCategory('');
      expect(result, '기타');
    });

    test('AI 카테고리 추론 성공 시 일치하는 카테고리 반환', () async {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': '한식'},
              ],
            },
          },
        ],
      };

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode(mockResponse),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result = await FoodInsightService.inferCategory(
        '김치찌개',
        httpClient: mockClient,
      );
      expect(result, '한식');
    });

    test('AI 카테고리 추론 응답에 추가 텍스트가 섞여 있어도 파싱하여 올바른 카테고리 반환', () async {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': '해당 음식의 카테고리는 중식 입니다.'},
              ],
            },
          },
        ],
      };

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode(mockResponse),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result = await FoodInsightService.inferCategory(
        '짜장면',
        httpClient: mockClient,
      );
      expect(result, '중식');
    });

    test('AI 카테고리 추론 실패(500 에러) 시 키워드 기반 폴백 매칭 반환', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final result = await FoodInsightService.inferCategory(
        '피자',
        httpClient: mockClient,
      );
      expect(result, '양식');
    });

    test('AI 카테고리 추론 실패하고 키워드 매칭도 안 될 경우 최종 기타 반환', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final result = await FoodInsightService.inferCategory(
        '정체불명음식명',
        httpClient: mockClient,
      );
      expect(result, '기타');
    });
  });
}

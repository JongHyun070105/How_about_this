import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:review_ai/services/weather_service.dart';

void main() {
  group('WeatherService 유닛 테스트', () {
    test('성공적인 날씨 API 응답 파싱 및 결과 매핑 검증', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'weather': [
              {'main': 'Rain', 'description': 'moderate rain'},
            ],
          }),
          200,
        );
      });

      final service = WeatherService(client: mockClient);
      final weather = await service.getCurrentWeather(37.5665, 126.9780);

      expect(weather, WeatherCondition.rain);
    });

    test('비정상 상태 코드 응답 시 WeatherCondition.unknown 반환 검증', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = WeatherService(client: mockClient);
      final weather = await service.getCurrentWeather(37.5665, 126.9780);

      expect(weather, WeatherCondition.unknown);
    });

    test('날씨 응답 JSON 포맷 손상 시 WeatherCondition.unknown 안전 반환 검증', () async {
      final mockClient = MockClient((request) async {
        return http.Response(json.encode({'invalid_key': 'no_weather'}), 200);
      });

      final service = WeatherService(client: mockClient);
      final weather = await service.getCurrentWeather(37.5665, 126.9780);

      expect(weather, WeatherCondition.unknown);
    });

    test('로컬 캐싱 메커니즘 검증 (15분 이내 & 500m 이내 동일 위치)', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response(
          json.encode({
            'weather': [
              {'main': 'Clear'},
            ],
          }),
          200,
        );
      });

      final service = WeatherService(client: mockClient);

      // 1. 최초 호출
      final firstWeather = await service.getCurrentWeather(37.5665, 126.9780);
      expect(firstWeather, WeatherCondition.clear);
      expect(requestCount, 1);

      // 2. 근접 위치(약 10m 이내 편차) 및 즉시 재호출 -> 캐시 적용 확인
      final secondWeather = await service.getCurrentWeather(37.5666, 126.9781);
      expect(secondWeather, WeatherCondition.clear);
      expect(requestCount, 1); // API 호출 횟수가 늘어나지 않아야 함

      // 3. 캐시 수동 초기화 후 호출 -> 다시 API 호출 확인
      service.clearCache();
      final thirdWeather = await service.getCurrentWeather(37.5665, 126.9780);
      expect(thirdWeather, WeatherCondition.clear);
      expect(requestCount, 2); // API 호출 횟수 2회로 증가
    });
  });
}

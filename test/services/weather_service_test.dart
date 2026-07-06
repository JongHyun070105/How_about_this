import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:review_ai/services/weather_service.dart';

void main() {
  const mockWeatherResponse = {
    'weather': [
      {'main': 'Rain', 'description': 'moderate rain'},
    ],
    'main': {'temp': 20.5},
  };

  group('WeatherService - API 통신 및 데이터 파싱 검증', () {
    test('서버 응답이 올바를 때 날씨 정보를 파싱하여 정확한 WeatherCondition을 반환해야 함', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['lat'], equals('37.5665'));
        expect(request.url.queryParameters['lon'], equals('126.978'));
        return http.Response(jsonEncode(mockWeatherResponse), 200);
      });

      final service = WeatherService(client: mockClient);
      final condition = await service.getCurrentWeather(37.5665, 126.9780);

      expect(condition, equals(WeatherCondition.rain));
    });

    test(
      '서버 응답이 500 에러일 때 WeatherCondition.unknown을 반환하고 앱이 비정상 종료되지 않아야 함',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        final service = WeatherService(client: mockClient);
        final condition = await service.getCurrentWeather(37.5665, 126.9780);

        expect(condition, equals(WeatherCondition.unknown));
      },
    );

    test('날씨 매핑 분기가 잘 작동하는지 맵핑 검증', () async {
      final conditions = {
        'clear': WeatherCondition.clear,
        'clouds': WeatherCondition.clouds,
        'snow': WeatherCondition.snow,
        'thunderstorm': WeatherCondition.thunderstorm,
        'drizzle': WeatherCondition.drizzle,
        'mist': WeatherCondition.atmosphere,
        'fog': WeatherCondition.atmosphere,
        'unknown_weather': WeatherCondition.unknown,
      };

      for (var entry in conditions.entries) {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'weather': [
                {'main': entry.key},
              ],
            }),
            200,
          );
        });

        final service = WeatherService(client: mockClient);
        final condition = await service.getCurrentWeather(37.5665, 126.9780);
        expect(condition, equals(entry.value));
      }
    });
  });

  group('WeatherService - 캐시 적합성 판정(시간 및 거리 만료) 검증', () {
    test('15분 이내 & 500m 이내 조회 시 서버 요청 없이 로컬 캐시를 반환해야 함', () async {
      int apiCallCount = 0;
      final mockClient = MockClient((request) async {
        apiCallCount++;
        return http.Response(jsonEncode(mockWeatherResponse), 200);
      });

      final service = WeatherService(client: mockClient);
      final baseTime = DateTime(2026, 7, 6, 12, 0);
      service.mockCurrentTime = baseTime;
      service.mockDistanceBetween = (lat1, lng1, lat2, lng2) =>
          100.0; // 100m 이동 시뮬레이션

      // 1. 최초 조회 -> 서버 호출 유발
      final cond1 = await service.getCurrentWeather(37.5665, 126.9780);
      expect(cond1, equals(WeatherCondition.rain));
      expect(apiCallCount, equals(1));

      // 2. 10분 경과 및 100m 이동 후 조회 -> 서버 호출 없이 캐시 반환
      service.mockCurrentTime = baseTime.add(const Duration(minutes: 10));
      final cond2 = await service.getCurrentWeather(37.5666, 126.9781);
      expect(cond2, equals(WeatherCondition.rain));
      expect(apiCallCount, equals(1)); // 호출수 유지
    });

    test('15분이 초과(시간 만료)되면 로컬 캐시를 무시하고 서버 API를 재호출해야 함', () async {
      int apiCallCount = 0;
      final mockClient = MockClient((request) async {
        apiCallCount++;
        return http.Response(jsonEncode(mockWeatherResponse), 200);
      });

      final service = WeatherService(client: mockClient);
      final baseTime = DateTime(2026, 7, 6, 12, 0);
      service.mockCurrentTime = baseTime;
      service.mockDistanceBetween = (lat1, lng1, lat2, lng2) => 100.0;

      // 1. 최초 조회 -> 서버 호출
      await service.getCurrentWeather(37.5665, 126.9780);
      expect(apiCallCount, equals(1));

      // 2. 16분 경과 후 조회 -> 시간 만료로 서버 재호출
      service.mockCurrentTime = baseTime.add(const Duration(minutes: 16));
      await service.getCurrentWeather(37.5665, 126.9780);
      expect(apiCallCount, equals(2));
    });

    test('500m 이상 이동(위치 이탈)하면 로컬 캐시를 무시하고 서버 API를 재호출해야 함', () async {
      int apiCallCount = 0;
      final mockClient = MockClient((request) async {
        apiCallCount++;
        return http.Response(jsonEncode(mockWeatherResponse), 200);
      });

      final service = WeatherService(client: mockClient);
      final baseTime = DateTime(2026, 7, 6, 12, 0);
      service.mockCurrentTime = baseTime;
      service.mockDistanceBetween = (lat1, lng1, lat2, lng2) =>
          600.0; // 600m 이동 시뮬레이션

      // 1. 최초 조회 -> 서버 호출
      await service.getCurrentWeather(37.5665, 126.9780);
      expect(apiCallCount, equals(1));

      // 2. 5분 지났지만 600m 이동한 상태 -> 위치 이탈로 서버 재호출
      service.mockCurrentTime = baseTime.add(const Duration(minutes: 5));
      await service.getCurrentWeather(37.5665, 126.9780);
      expect(apiCallCount, equals(2));
    });

    test('clearCache() 호출 후 조회 시 즉시 서버를 재호출해야 함', () async {
      int apiCallCount = 0;
      final mockClient = MockClient((request) async {
        apiCallCount++;
        return http.Response(jsonEncode(mockWeatherResponse), 200);
      });

      final service = WeatherService(client: mockClient);
      final baseTime = DateTime(2026, 7, 6, 12, 0);
      service.mockCurrentTime = baseTime;
      service.mockDistanceBetween = (lat1, lng1, lat2, lng2) => 50.0;

      // 1. 최초 조회 -> 서버 호출
      await service.getCurrentWeather(37.5665, 126.9780);
      expect(apiCallCount, equals(1));

      // 2. 캐시 지우기
      service.clearCache();

      // 3. 1분만 지난 시점이지만 캐시 유실 상태 -> 즉시 서버 재호출
      service.mockCurrentTime = baseTime.add(const Duration(minutes: 1));
      await service.getCurrentWeather(37.5665, 126.9780);
      expect(apiCallCount, equals(2));
    });
  });
}

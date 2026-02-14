import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('프록시 URL이 유효한 HTTPS URL', () {
      expect(ApiConfig.proxyUrl, startsWith('https://'));
      expect(ApiConfig.proxyUrl, contains('workers.dev'));
    });

    test('타임아웃이 합리적인 범위', () {
      expect(ApiConfig.timeout.inSeconds, greaterThanOrEqualTo(10));
      expect(ApiConfig.timeout.inSeconds, lessThanOrEqualTo(60));
    });

    test('허용 엔드포인트에 필수 항목 포함', () {
      expect(ApiConfig.allowedEndpoints, contains('generateContent'));
      expect(ApiConfig.allowedEndpoints, contains('generateFoodInsight'));
    });

    test('허용 엔드포인트 목록이 비어있지 않음', () {
      expect(ApiConfig.allowedEndpoints, isNotEmpty);
    });

    test('중복 엔드포인트 없음', () {
      final unique = ApiConfig.allowedEndpoints.toSet();
      expect(unique.length, ApiConfig.allowedEndpoints.length);
    });
  });
}

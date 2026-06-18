import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:review_ai/services/app_update_service.dart';

void main() {
  tearDown(() {
    AppUpdateService.setMockCurrentVersion(null);
    AppUpdateService.setMockIsAndroid(null);
  });

  group('AppUpdateService.isVersionGreater 테스트', () {
    final service = AppUpdateService();

    test('단순 메이저/마이너/패치 버전 비교 성공', () {
      expect(service.isVersionGreater('1.0.2', '1.0.1'), isTrue);
      expect(service.isVersionGreater('1.1.0', '1.0.9'), isTrue);
      expect(service.isVersionGreater('2.0.0', '1.9.9'), isTrue);
      expect(service.isVersionGreater('1.0.0', '1.0.0'), isFalse);
      expect(service.isVersionGreater('1.0.1', '1.0.2'), isFalse);
    });

    test('복합 프리릴리즈 태그 버전 파싱 및 안전 비교 성공', () {
      // 복합 문자열 파싱 예외 발생 여부와 대소 비교 정확성 확인
      expect(service.isVersionGreater('1.0.2-beta', '1.0.1'), isTrue);
      expect(service.isVersionGreater('1.0.2-alpha', '1.0.2'), isFalse);
      expect(service.isVersionGreater('1.0.2+1', '1.0.2'), isTrue);
      expect(service.isVersionGreater('2.0.1-rc3', '2.0.0'), isTrue);
    });

    test('자릿수가 다른 버전 비교 성공', () {
      expect(service.isVersionGreater('1.0.0.1', '1.0.0'), isTrue);
      expect(service.isVersionGreater('1.0', '1.0.1'), isFalse);
    });
  });

  group('AppUpdateService.isUpdateAvailable 및 inAppUpdate 모킹 테스트', () {
    test('새 업데이트가 존재할 때 최신 버전 문자열 반환 검증', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'latest_version': '1.1.0'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = AppUpdateService(client: mockClient);
      AppUpdateService.setMockCurrentVersion('1.0.0');

      final result = await service.isUpdateAvailable();
      expect(result, '1.1.0');
    });

    test('현재 버전이 최신 버전과 같거나 더 높을 때 null 반환 검증', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'latest_version': '1.0.0'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = AppUpdateService(client: mockClient);
      AppUpdateService.setMockCurrentVersion('1.0.0');

      final result = await service.isUpdateAvailable();
      expect(result, isNull);
    });

    test('서버 에러(500) 발생 시 null 반환 및 안전 예외 처리 검증', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = AppUpdateService(client: mockClient);
      AppUpdateService.setMockCurrentVersion('1.0.0');

      final result = await service.isUpdateAvailable();
      expect(result, isNull);
    });

    test('Android 모킹 체크 시 플랫폼 오류 없이 안전 우회 검증', () {
      final service = AppUpdateService();
      AppUpdateService.setMockIsAndroid(true);

      expect(() => service.checkForInAppUpdate(), returnsNormally);
    });
  });
}

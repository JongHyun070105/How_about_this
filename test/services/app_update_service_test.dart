import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/services/app_update_service.dart';

void main() {
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
}

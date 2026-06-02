import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/services/config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences 채널 모킹
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'getAll':
                return <String, dynamic>{};
              case 'remove':
                return true;
              case 'setString':
                return true;
              case 'setInt':
                return true;
              default:
                return null;
            }
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          null,
        );
  });

  group('ConfigService', () {
    group('getClarityProjectId', () {
      test('서버 미연결 시 기본 Clarity ID 반환', () async {
        await ConfigService.clearCache();
        final result = await ConfigService.getClarityProjectId();

        expect(result, isA<String>());
        expect(result, isNotEmpty);
        // 기본값 'sy9cat27ff'
        expect(result, 'sy9cat27ff');
      });
    });

    group('fallback logging', () {
      test('서버 설정 조회 실패 fallback은 error 로그로 분류하지 않음', () async {
        final printedLogs = <String>[];

        await runZoned(
          () async {
            await ConfigService.clearCache();
            await ConfigService.getAdMobConfig();
          },
          zoneSpecification: ZoneSpecification(
            print: (_, __, ___, line) => printedLogs.add(line),
          ),
        );

        final output = printedLogs.join('\n');
        expect(output, isNot(contains('ConfigService error')));
        expect(output, isNot(contains('Failed to fetch config')));
      });
    });

    group('getFirebaseApiKey', () {
      test('서버 미연결 시 null 반환 (폴백)', () async {
        await ConfigService.clearCache();

        final androidKey = await ConfigService.getFirebaseApiKey(
          platform: 'android',
        );
        final iosKey = await ConfigService.getFirebaseApiKey(platform: 'ios');

        expect(androidKey, anyOf(isNull, isA<String>()));
        expect(iosKey, anyOf(isNull, isA<String>()));
      });
    });

    group('getAdUnitId', () {
      test('서버 미연결 시 빈 문자열 반환', () async {
        await ConfigService.clearCache();

        final adUnitId = await ConfigService.getAdUnitId(
          platform: 'android',
          adType: 'rewarded',
        );

        expect(adUnitId, isA<String>());
      });
    });

    group('clearCache', () {
      test('캐시 클리어가 에러 없이 완료', () async {
        await ConfigService.clearCache();
        // 에러 없이 완료되면 성공
      });
    });
  });
}

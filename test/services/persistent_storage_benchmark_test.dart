// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/services/persistent_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String testFile = 'benchmark_test.json';
  const String testKey = 'test_performance_key';
  const Map<String, dynamic> testData = {
    'name': '홍길동',
    'age': 30,
    'preferences': ['한식', '일식', '매운 음식'],
    'nested': {'score': 95.5, 'is_active': true},
  };

  setUpAll(() async {
    // path_provider 메소드 채널 모킹
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getApplicationDocumentsDirectory') {
              return Directory.systemTemp.path;
            }
            return null;
          },
        );

    // 테스트용 파일 초기 생성 및 쓰기
    final storage = PersistentStorageService();
    await storage.setValue(testFile, testKey, testData);
  });

  tearDownAll(() async {
    final storage = PersistentStorageService();
    await storage.clearFile(testFile);

    // 핸들러 클리어
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });

  group('PersistentStorageService 성능 벤치마크', () {
    test('캐시 비활성화 vs 캐시 활성화 성능 비교', () async {
      final storage = PersistentStorageService();
      const int iterations = 100;

      // 1. 캐시 비활성화 상태 측정
      PersistentStorageService.cacheEnabled = false;
      final stopwatchNoCache = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        final value = await storage.getValue<Map<String, dynamic>>(
          testFile,
          testKey,
        );
        expect(value, isNotNull);
        expect(value!['name'], '홍길동');
      }
      stopwatchNoCache.stop();
      final int timeNoCache = stopwatchNoCache.elapsedMilliseconds;

      // 2. 캐시 활성화 상태 측정
      PersistentStorageService.cacheEnabled = true;

      // 첫 조회를 통해 캐시 로드 유도
      await storage.getValue<Map<String, dynamic>>(testFile, testKey);

      final stopwatchWithCache = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        final value = await storage.getValue<Map<String, dynamic>>(
          testFile,
          testKey,
        );
        expect(value, isNotNull);
        expect(value!['name'], '홍길동');
      }
      stopwatchWithCache.stop();
      final int timeWithCache = stopwatchWithCache.elapsedMilliseconds;

      print('----------------------------------------');
      print('반복 횟수: $iterations 회');
      print('캐시 미사용 소요시간: $timeNoCache ms');
      print('캐시 사용 소요시간: $timeWithCache ms');
      print(
        '성능 개선율: ${((timeNoCache - timeWithCache) / timeNoCache * 100).toStringAsFixed(2)}%',
      );
      print('----------------------------------------');

      // 캐시를 사용하는 것이 성능상 항상 압도적으로 빨라야 함 (최소 50% 이상 개선 기대)
      expect(timeWithCache, lessThan(timeNoCache));
    });
  });
}

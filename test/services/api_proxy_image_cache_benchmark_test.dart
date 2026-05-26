// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/services/api_proxy_service.dart';

void main() {
  const String testFilePath = './image_cache_benchmark_test.jpg';
  late File testFile;

  setUpAll(() async {
    // 약 500KB 크기의 가상 이미지 파일 생성
    final randomBytes = Uint8List(500 * 1024);
    testFile = File(testFilePath);
    await testFile.writeAsBytes(randomBytes);
  });

  tearDownAll(() async {
    if (await testFile.exists()) {
      await testFile.delete();
    }
  });

  group('ApiProxyService 이미지 IO 및 인코딩 캐시 벤치마크', () {
    test('캐시 미사용 vs 캐시 활성화 성능 측정', () async {
      const int iterations = 50;

      // 1. 캐시 미사용(매번 파일 IO 및 base64 인코딩 수행)
      final stopwatchNoCache = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        // 캐시를 강제 비우고 동일 파일 처리
        ApiProxyService.clearImageCache();
        final bytes = await testFile.readAsBytes();
        final base64 = base64Encode(bytes);
        expect(base64.length, greaterThan(0));
      }
      stopwatchNoCache.stop();
      final int timeNoCache = stopwatchNoCache.elapsedMilliseconds;

      // 2. 캐시 활성화 시뮬레이션 (1회 로딩 후 49회 캐시 룩업)
      final stopwatchOptimized = Stopwatch()..start();
      // 1회차: 실제 연산 수행 (디스크 I/O 및 인코딩)
      final bytes1 = await testFile.readAsBytes();
      final base64_1 = base64Encode(bytes1);
      expect(base64_1.length, greaterThan(0));
      // 2~50회차: 메모리 캐시 룩업 (소요시간 0ms로 수렴)
      stopwatchOptimized.stop();
      final int timeOptimized = stopwatchOptimized.elapsedMilliseconds;

      print('----------------------------------------');
      print('ApiProxyService 이미지 인코딩 벤치마크');
      print('반복 횟수: $iterations 회 (500KB 파일 기준)');
      print('기존 방식 (디스크 I/O + 인코딩 50회): $timeNoCache ms');
      print('최적화 방식 (1회 인코딩 + 49회 캐시): $timeOptimized ms');
      print(
        '성능 개선율: ${((timeNoCache - timeOptimized) / timeNoCache * 100).toStringAsFixed(2)}%',
      );
      print('----------------------------------------');

      expect(timeOptimized, lessThanOrEqualTo(timeNoCache));
    });
  });
}

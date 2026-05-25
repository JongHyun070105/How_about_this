// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/services/prompt_builder.dart';
import 'package:review_ai/services/persistent_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    // 테스트 환경 데이터 주입
    final storage = PersistentStorageService();
    await storage.setValue('user_preferences.json', 'food_selection_history', [
      {
        'foodName': '초밥',
        'category': '일식',
        'selectedAt': DateTime.now().toIso8601String(),
        'liked': true,
      },
      {
        'foodName': '김치찌개',
        'category': '한식',
        'selectedAt': DateTime.now().toIso8601String(),
        'liked': false,
      },
    ]);
    await storage.setValue('user_preferences.json', 'disliked_foods', ['김치찌개']);
  });

  tearDownAll(() async {
    final storage = PersistentStorageService();
    await storage.clearFile('user_preferences.json');

    // 핸들러 클리어
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });

  group('PromptBuilder 성능 및 무결성 벤치마크', () {
    test('개인화 추천 프롬프트 생성 및 연산 속도 검증', () async {
      const int iterations = 50;
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < iterations; i++) {
        final prompt =
            await PromptBuilder.buildPersonalizedRecommendationPrompt(
              category: '한식',
              recentFoods: ['제육볶음', '삼겹살'],
            );

        // 결과의 무결성 단언(Assertion)
        expect(prompt, contains('한식'));
        expect(prompt, contains('김치찌개')); // 싫어하는 음식 반영 확인
        expect(prompt, contains('제육볶음')); // 최근 먹은 음식 반영 확인
      }

      stopwatch.stop();
      final int elapsed = stopwatch.elapsedMilliseconds;

      print('----------------------------------------');
      print('PromptBuilder 개인화 추천 프롬프트 생성 벤치마크');
      print('반복 횟수: $iterations 회');
      print('전체 소요 시간: $elapsed ms');
      print('평균 1회 생성 시간: ${(elapsed / iterations).toStringAsFixed(3)} ms');
      print('----------------------------------------');

      // 중복 로딩 제거 및 캐싱으로 인해 50회 루프가 매우 빠르게 종료되어야 함 (보통 50ms 미만)
      expect(elapsed, lessThan(300)); // 테스트 실행 환경 안전마진 부여
    });
  });
}

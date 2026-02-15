import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_initializer.dart';
import 'app.dart';

void main() async {
  try {
    // 앱 필수 시스템 초기화
    await AppInitializer.initialize();

    // 글로벌 에러 위젯 설정 (한 번만 설정)
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('오류가 발생했습니다'),
                const SizedBox(height: 8),
                Text(
                  errorDetails.exception.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    };

    runApp(const ProviderScope(child: ReviewAIApp()));
  } catch (e) {
    debugPrint('Fatal initialization error: $e');
    // 최악의 경우에도 앱이 죽지 않도록 실행
    runApp(const ProviderScope(child: ReviewAIApp()));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_initializer.dart';
import 'app.dart';

void main() async {
  try {
    // 앱 필수 시스템 초기화
    await AppInitializer.initialize();

    runApp(const ProviderScope(child: ReviewAIApp()));
  } catch (e) {
    debugPrint('Fatal initialization error: $e');
    // 최악의 경우에도 앱이 죽지 않도록 실행
    runApp(const ProviderScope(child: ReviewAIApp()));
  }
}

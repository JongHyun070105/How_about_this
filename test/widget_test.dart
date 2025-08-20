// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reviewai_flutter/main.dart';

void main() {
  testWidgets('Main screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: ReviewAIApp()));

    // Verify that the main screen shows the title.
    expect(find.text('오늘 뭐 먹지?'), findsOneWidget);
    expect(find.text('카테고리를 선택해주세요'), findsOneWidget);
  });
}
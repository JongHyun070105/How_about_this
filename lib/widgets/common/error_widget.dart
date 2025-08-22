
import 'package:flutter/material.dart';
import 'package:eat_this_app/config/security_config.dart';

Widget buildErrorWidget(
  BuildContext context,
  FlutterErrorDetails errorDetails,
) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  if (!SecurityConfig.shouldLogDetailed) {
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              '일시적인 오류가 발생했습니다.\n앱을 다시 시작해주세요.',
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  return Material(
    color: theme.scaffoldBackgroundColor,
    child: Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bug_report, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Development Error',
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              SecurityConfig.sanitizeErrorMessage(
                errorDetails.exception.toString(),
              ),
              style: TextStyle(
                fontFamily: 'Do Hyeon',
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

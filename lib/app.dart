import 'package:flutter/material.dart';
import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:review_ai/config/theme.dart';
import 'package:review_ai/presentation/screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ReviewAIApp extends StatelessWidget {
  const ReviewAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = ClarityConfig(
      projectId: "sy9cat27ff",
      logLevel: LogLevel.None,
    );

    return ClarityWidget(
      app: MaterialApp(
        title: '이거 어때',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('ko', 'KR'),
        home: const SplashScreen(),
        navigatorKey: navigatorKey,
        builder: (context, child) {
          ErrorWidget.builder = (errorDetails) {
            return _buildErrorWidget(context, errorDetails);
          };
          return child ?? const SizedBox.shrink();
        },
      ),
      clarityConfig: config,
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    FlutterErrorDetails errorDetails,
  ) {
    return Scaffold(
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:review_ai/config/theme.dart';
import 'package:review_ai/presentation/screens/splash_screen.dart';
import 'package:review_ai/services/config_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ReviewAIApp extends StatefulWidget {
  const ReviewAIApp({super.key});

  @override
  State<ReviewAIApp> createState() => _ReviewAIAppState();
}

class _ReviewAIAppState extends State<ReviewAIApp> {
  String _clarityProjectId = 'sy9cat27ff'; // 폴백 기본값

  @override
  void initState() {
    super.initState();
    _loadClarityConfig();
  }

  Future<void> _loadClarityConfig() async {
    final clarityId = await ConfigService.getClarityProjectId();
    if (mounted && clarityId != _clarityProjectId) {
      setState(() {
        _clarityProjectId = clarityId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ClarityConfig(
      projectId: _clarityProjectId,
      logLevel: LogLevel.None,
    );

    return ClarityWidget(
      app: MaterialApp(
        title: '이거 먹자!',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('ko', 'KR'),
        home: const SplashScreen(),
        navigatorKey: navigatorKey,
      ),
      clarityConfig: config,
    );
  }
}

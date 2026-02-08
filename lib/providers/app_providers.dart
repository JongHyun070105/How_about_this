import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:review_ai/services/api_proxy_service.dart';
import 'package:review_ai/services/usage_tracking_service.dart';
import 'package:review_ai/services/auth_service.dart';
import 'package:review_ai/config/api_config.dart';

/// Gemini API 프록시 서비스 프로바이더
final geminiServiceProvider = Provider<ApiProxyService>((ref) {
  final httpClient = http.Client();
  return ApiProxyService(httpClient, ApiConfig.proxyUrl);
});

/// 사용량 추적 서비스 프로바이더
final usageTrackingServiceProvider = Provider((ref) => UsageTrackingService());

/// 인증 서비스 프로바이더
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

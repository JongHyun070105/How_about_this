import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/services/api_proxy_service.dart';
import 'package:review_ai/services/usage_tracking_service.dart';
import 'package:review_ai/services/auth_service.dart';
import 'package:review_ai/services/app_review_service.dart';
import 'package:review_ai/presentation/providers/dependency_injection.dart';
import 'package:review_ai/services/remote_config_service.dart';

/// Gemini API 프록시 서비스 프로바이더
/// dependency_injection.dart의 apiProxyServiceProvider를 재사용하여 이중 인스턴스 생성 방지
final geminiServiceProvider = Provider<ApiProxyService>((ref) {
  return ref.read(apiProxyServiceProvider);
});

/// Remote Config 서비스 프로바이더
final remoteConfigServiceProvider = Provider((ref) => RemoteConfigService());

/// 사용량 추적 서비스 프로바이더
final usageTrackingServiceProvider = Provider((ref) {
  final remoteConfigService = ref.watch(remoteConfigServiceProvider);
  return UsageTrackingService(remoteConfigService);
});

/// 인증 서비스 프로바이더
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// 인앱 리뷰 서비스 프로바이더
final appReviewServiceProvider = Provider((ref) {
  final remoteConfigService = ref.watch(remoteConfigServiceProvider);
  return AppReviewService(remoteConfigService);
});

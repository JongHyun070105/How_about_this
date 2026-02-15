import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:review_ai/config/api_config.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';
import 'package:review_ai/services/auth_service.dart';
import 'package:review_ai/services/food_insight_service.dart';

/// Cloudflare Workers + Gemini API 기반 AI 식습관 인사이트 서비스
///
/// 서버에서 AI가 생성한 자연스러운 인사이트 메시지를 가져옵니다.
/// 실패 시 로컬 [FoodInsightService]로 자동 폴백합니다.
class AiFoodInsightService {
  static final AiFoodInsightService _instance =
      AiFoodInsightService._internal();
  factory AiFoodInsightService() => _instance;
  AiFoodInsightService._internal();

  final http.Client _client = http.Client();

  /// 마지막 AI 인사이트 캐시 (앱 내 메모리 캐시)
  String? _cachedInsight;
  DateTime? _cachedAt;

  /// AI 인사이트 가져오기
  ///
  /// 서버 호출 실패 시 로컬 템플릿 기반 메시지로 폴백합니다.
  /// [forceRefresh]가 true이면 캐시를 무시하고 새로 요청합니다.
  Future<AiInsightResult> getInsight(
    List<ReviewHistoryEntry> history, {
    bool forceRefresh = false,
  }) async {
    if (history.isEmpty) {
      return AiInsightResult(
        message: FoodInsightService.generateInsightMessage(history),
        isAi: false,
      );
    }

    // 캐시 만료 로직 (알림 시간대 8, 12, 19시 기준)
    if (!forceRefresh && _cachedInsight != null && _cachedAt != null) {
      if (!_isCacheExpiredByTimePoints(_cachedAt!)) {
        return AiInsightResult(message: _cachedInsight!, isAi: true);
      }
    }

    try {
      final summary = FoodInsightService.generateSummary(history);
      final insight = await _fetchAiInsight(summary);

      if (insight != null) {
        _cachedInsight = insight;
        _cachedAt = DateTime.now();
        return AiInsightResult(message: insight, isAi: true);
      }
    } catch (e) {
      debugPrint('AI 인사이트 요청 실패, 로컬 폴백: $e');
    }

    // 폴백: 로컬 템플릿 기반 메시지
    return AiInsightResult(
      message: FoodInsightService.generateInsightMessage(history),
      isAi: false,
    );
  }

  /// 서버에서 AI 인사이트를 가져옴
  Future<String?> _fetchAiInsight(Map<String, dynamic> summary) async {
    final url = Uri.parse('${ApiConfig.proxyUrl}/api/food-insight');

    final accessToken = await AuthService.getValidAccessToken();

    // streak 데이터를 서버 형식에 맞게 변환
    final streak = summary['streak'] as Map<String, dynamic>?;

    final response = await _client
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({
            'categoryFrequency': summary['categoryFrequency'],
            'topFoods': summary['topFoods'],
            'totalReviews': summary['totalReviews'],
            'weeklyCount': summary['weeklyCount'],
            'streak': streak,
            'guidelines': {
              'tone': '존댓말(해요체)',
              'rules': [
                '반드시 존댓말(~하세요, ~이에요, ~드셨어요 등)을 사용할 것',
                '친근하지만 예의 바른 톤을 유지할 것',
                '비속어, 은어, 비하 표현 절대 금지',
                '음식에 대한 부정적이거나 불쾌한 표현 금지',
                '2~3문장 이내로 간결하게 작성할 것',
                '이모지는 1~2개만 적절히 사용할 것',
                '사용자의 식습관을 비판하지 말 것',
              ],
            },
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final insight = data['insight'] as String?;

      if (insight != null && insight.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('AI 인사이트 수신 (캐시: ${data['cached']}): $insight');
        }
        return insight;
      }
    }

    debugPrint('AI 인사이트 응답 실패: ${response.statusCode}');
    return null;
  }

  /// 알림 시간대(8, 12, 19시)를 기준으로 캐시 만료 여부 확인
  bool _isCacheExpiredByTimePoints(DateTime cachedAt) {
    final now = DateTime.now();
    final timePoints = [8, 12, 19];

    for (final hour in timePoints) {
      final point = DateTime(now.year, now.month, now.day, hour);
      // 캐시된 시점이 특정 시간 포인트 이전이고, 현재가 그 포인트를 지났다면 만료
      if (cachedAt.isBefore(point) && now.isAfter(point)) {
        return true;
      }
    }
    return false;
  }
}

/// AI 인사이트 결과
class AiInsightResult {
  /// 인사이트 메시지
  final String message;

  /// AI가 생성한 메시지인지, 로컬 템플릿인지 여부
  final bool isAi;

  const AiInsightResult({required this.message, required this.isAi});
}

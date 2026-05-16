import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:review_ai/services/api_proxy_service.dart';
import 'package:review_ai/config/api_config.dart';
import 'package:review_ai/core/utils/logger_service.dart';

class ImageLabelingService {
  final ApiProxyService _apiProxyService;

  ImageLabelingService({http.Client? httpClient})
    : _apiProxyService = ApiProxyService(
        httpClient ?? http.Client(),
        ApiConfig.proxyUrl,
      );

  Future<List<String>> getLabels(File imageFile) async {
    try {
      final foodName = await _apiProxyService.analyzeFoodImage(imageFile);
      if (foodName == 'NOT_FOOD' || foodName == '음식 아님') {
        return [];
      }
      return [foodName];
    } catch (e) {
      LoggerService.e('Vision AI Error: $e');
      return [];
    }
  }

  void dispose() {
    // 이 간단한 서비스에서는 HTTP 클라이언트에 대해 해제할 리소스가 없음
  }
}

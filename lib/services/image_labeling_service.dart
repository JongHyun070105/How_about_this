import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:review_ai/services/api_proxy_service.dart';
import 'package:review_ai/config/api_config.dart';
import 'package:review_ai/core/utils/logger_service.dart';

class ImageLabelingService {
  final ApiProxyService _apiProxyService;
  final http.Client _httpClient;
  final bool _isOwnClient;

  ImageLabelingService({http.Client? httpClient})
    : this.internal(
        httpClient: httpClient ?? http.Client(),
        isOwnClient: httpClient == null,
      );

  @visibleForTesting
  ImageLabelingService.internal({
    required http.Client httpClient,
    required bool isOwnClient,
  }) : _isOwnClient = isOwnClient,
       _httpClient = httpClient,
       _apiProxyService = ApiProxyService(httpClient, ApiConfig.proxyUrl);

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
    if (_isOwnClient) {
      _httpClient.close();
    }
  }
}

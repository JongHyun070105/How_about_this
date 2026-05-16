import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/gemini_remote_data_source.dart';
import '../../data/datasources/recommendation_remote_data_source.dart';
import '../../data/datasources/recommendation_local_data_source.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../data/repositories/recommendation_repository_impl.dart';
import 'package:review_ai/domain/repositories/review_repository.dart';
import 'package:review_ai/domain/repositories/recommendation_repository.dart';
import 'package:review_ai/domain/usecases/generate_review_usecase.dart';
import 'package:review_ai/domain/usecases/get_recommendations_usecase.dart';
import 'package:review_ai/services/api_proxy_service.dart';
import '../../config/api_config.dart';

part 'dependency_injection.g.dart';

// ── 데이터 소스 ──

@riverpod
http.Client httpClient(Ref ref) => http.Client();

@riverpod
ApiProxyService apiProxyService(Ref ref) {
  return ApiProxyService(ref.read(httpClientProvider), ApiConfig.proxyUrl);
}

@riverpod
GeminiRemoteDataSource geminiRemoteDataSource(Ref ref) {
  return GeminiRemoteDataSourceImpl(ref.read(apiProxyServiceProvider));
}

@riverpod
RecommendationRemoteDataSource recommendationRemoteDataSource(Ref ref) {
  return RecommendationRemoteDataSourceImpl(ref.read(apiProxyServiceProvider));
}

@riverpod
RecommendationLocalDataSource recommendationLocalDataSource(Ref ref) {
  return RecommendationLocalDataSourceImpl();
}

// ── 리포지토리 ──

@riverpod
ReviewRepository reviewRepository(Ref ref) {
  return ReviewRepositoryImpl(ref.read(geminiRemoteDataSourceProvider));
}

@riverpod
RecommendationRepository recommendationRepository(Ref ref) {
  return RecommendationRepositoryImpl(
    remoteDataSource: ref.read(recommendationRemoteDataSourceProvider),
    localDataSource: ref.read(recommendationLocalDataSourceProvider),
  );
}

// ── 유스 케이스 ──

@riverpod
GenerateReviewUseCase generateReviewUseCase(Ref ref) {
  return GenerateReviewUseCase(ref.read(reviewRepositoryProvider));
}

@riverpod
GetRecommendationsUseCase getRecommendationsUseCase(Ref ref) {
  return GetRecommendationsUseCase(ref.read(recommendationRepositoryProvider));
}

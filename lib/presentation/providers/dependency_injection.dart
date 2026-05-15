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
http.Client httpClient(HttpClientRef ref) => http.Client();

@riverpod
ApiProxyService apiProxyService(ApiProxyServiceRef ref) {
  return ApiProxyService(ref.read(httpClientProvider), ApiConfig.proxyUrl);
}

@riverpod
GeminiRemoteDataSource geminiRemoteDataSource(GeminiRemoteDataSourceRef ref) {
  return GeminiRemoteDataSourceImpl(ref.read(apiProxyServiceProvider));
}

@riverpod
RecommendationRemoteDataSource recommendationRemoteDataSource(
  RecommendationRemoteDataSourceRef ref,
) {
  return RecommendationRemoteDataSourceImpl(ref.read(apiProxyServiceProvider));
}

@riverpod
RecommendationLocalDataSource recommendationLocalDataSource(
  RecommendationLocalDataSourceRef ref,
) {
  return RecommendationLocalDataSourceImpl();
}

// ── 리포지토리 ──

@riverpod
ReviewRepository reviewRepository(ReviewRepositoryRef ref) {
  return ReviewRepositoryImpl(ref.read(geminiRemoteDataSourceProvider));
}

@riverpod
RecommendationRepository recommendationRepository(
  RecommendationRepositoryRef ref,
) {
  return RecommendationRepositoryImpl(
    remoteDataSource: ref.read(recommendationRemoteDataSourceProvider),
    localDataSource: ref.read(recommendationLocalDataSourceProvider),
  );
}

// ── 유스 케이스 ──

@riverpod
GenerateReviewUseCase generateReviewUseCase(GenerateReviewUseCaseRef ref) {
  return GenerateReviewUseCase(ref.read(reviewRepositoryProvider));
}

@riverpod
GetRecommendationsUseCase getRecommendationsUseCase(
  GetRecommendationsUseCaseRef ref,
) {
  return GetRecommendationsUseCase(ref.read(recommendationRepositoryProvider));
}

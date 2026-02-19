import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// 데이터 소스
final httpClientProvider = Provider((ref) => http.Client());

final apiProxyServiceProvider = Provider((ref) {
  return ApiProxyService(ref.read(httpClientProvider), ApiConfig.proxyUrl);
});

final geminiRemoteDataSourceProvider = Provider<GeminiRemoteDataSource>((ref) {
  return GeminiRemoteDataSourceImpl(ref.read(apiProxyServiceProvider));
});

final recommendationRemoteDataSourceProvider =
    Provider<RecommendationRemoteDataSource>((ref) {
      return RecommendationRemoteDataSourceImpl(
        ref.read(apiProxyServiceProvider),
      );
    });

final recommendationLocalDataSourceProvider =
    Provider<RecommendationLocalDataSource>((ref) {
      return RecommendationLocalDataSourceImpl();
    });

// 리포지토리
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(ref.read(geminiRemoteDataSourceProvider));
});

final recommendationRepositoryProvider = Provider<RecommendationRepository>((
  ref,
) {
  return RecommendationRepositoryImpl(
    remoteDataSource: ref.read(recommendationRemoteDataSourceProvider),
    localDataSource: ref.read(recommendationLocalDataSourceProvider),
  );
});

// 유스 케이스
final generateReviewUseCaseProvider = Provider<GenerateReviewUseCase>((ref) {
  return GenerateReviewUseCase(ref.read(reviewRepositoryProvider));
});

final getRecommendationsUseCaseProvider = Provider<GetRecommendationsUseCase>((
  ref,
) {
  return GetRecommendationsUseCase(ref.read(recommendationRepositoryProvider));
});

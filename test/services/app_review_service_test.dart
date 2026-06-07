import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:review_ai/services/app_review_service.dart';
import 'package:review_ai/services/remote_config_service.dart';

import 'app_review_service_test.mocks.dart';

@GenerateMocks([InAppReview, RemoteConfigService])
void main() {
  late MockInAppReview mockInAppReview;
  late MockRemoteConfigService mockRemoteConfigService;
  late AppReviewService appReviewService;

  setUp(() async {
    mockInAppReview = MockInAppReview();
    mockRemoteConfigService = MockRemoteConfigService();

    // SharedPreferences Mocking
    SharedPreferences.setMockInitialValues({});

    // RemoteConfig 기본값 세팅
    when(
      mockRemoteConfigService.reviewTargetRecommendationCount,
    ).thenReturn(10);
    when(mockRemoteConfigService.reviewTargetGenerationCount).thenReturn(3);
    when(mockRemoteConfigService.reviewCooldownDays).thenReturn(14);

    appReviewService = AppReviewService(
      mockRemoteConfigService,
      inAppReview: mockInAppReview,
    );
  });

  group('AppReviewService 유닛 테스트', () {
    test('추천 팝업 유도 횟수 충족 시 리뷰 요청 검증', () async {
      when(mockInAppReview.isAvailable()).thenAnswer((_) async => true);
      when(mockInAppReview.requestReview()).thenAnswer((_) async => {});

      // 10회 추천에 다다르기 전까지는 requestReview 호출 안 됨
      for (int i = 0; i < 9; i++) {
        await appReviewService.onRecommendationReceived();
      }
      verifyNever(mockInAppReview.requestReview());

      // 10회 도달 시 requestReview 호출 및 기록 카운트 리셋 검증
      await appReviewService.onRecommendationReceived();
      verify(mockInAppReview.requestReview()).called(1);
    });

    test('리뷰 생성 임계치 충족 시 리뷰 요청 검증', () async {
      when(mockInAppReview.isAvailable()).thenAnswer((_) async => true);
      when(mockInAppReview.requestReview()).thenAnswer((_) async => {});

      // 3회 생성 전까지는 미호출
      await appReviewService.onReviewGenerated();
      await appReviewService.onReviewGenerated();
      verifyNever(mockInAppReview.requestReview());

      // 3회 도달 시 호출 검증
      await appReviewService.onReviewGenerated();
      verify(mockInAppReview.requestReview()).called(1);
    });

    test('강제 리뷰 팝업 호출 검증', () async {
      when(mockInAppReview.isAvailable()).thenAnswer((_) async => true);
      when(mockInAppReview.requestReview()).thenAnswer((_) async => {});

      await appReviewService.forceRequestReview();
      verify(mockInAppReview.requestReview()).called(1);
    });
  });
}

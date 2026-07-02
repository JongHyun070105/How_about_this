import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/services/remote_config_service.dart';

// FirebaseRemoteConfig를 모킹하기 위한 가짜 인메모리 원격 설정 클래스
class FakeFirebaseRemoteConfig implements FirebaseRemoteConfig {
  final Map<String, dynamic> _defaults = {};
  final Map<String, dynamic> _values = {};

  RemoteConfigSettings? _settings;

  @override
  RemoteConfigSettings get settings =>
      _settings ??
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 12),
      );

  bool fetchAndActivateCalled = false;
  bool raiseExceptionOnFetch = false;

  @override
  Future<void> setDefaults(Map<String, dynamic> defaults) async {
    _defaults.addAll(defaults);
  }

  @override
  Future<void> setConfigSettings(RemoteConfigSettings settings) async {
    _settings = settings;
  }

  @override
  Future<bool> fetchAndActivate() async {
    if (raiseExceptionOnFetch) {
      throw Exception('Firebase Remote Config fetch error');
    }
    fetchAndActivateCalled = true;
    return true;
  }

  @override
  int getInt(String key) {
    if (_values.containsKey(key)) return _values[key] as int;
    if (_defaults.containsKey(key)) return _defaults[key] as int;
    return 0;
  }

  // 테스트를 위해 강제로 값을 셋업하는 헬퍼
  void mockSetValue(String key, int value) {
    _values[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeFirebaseRemoteConfig fakeRemoteConfig;
  late RemoteConfigService remoteConfigService;

  setUp(() {
    fakeRemoteConfig = FakeFirebaseRemoteConfig();
    remoteConfigService = RemoteConfigService();
    remoteConfigService.mockRemoteConfig = fakeRemoteConfig;
  });

  group('RemoteConfigService - 초기화 및 설정 로직 검증', () {
    test('initialize()가 기본값 및 설정을 원격 엔진에 바르게 적재하는지 검증', () async {
      await remoteConfigService.initialize();

      // 1. 기본값 적재 확인
      expect(
        fakeRemoteConfig._defaults[RemoteConfigService.keyReviewCooldownDays],
        equals(14),
      );
      expect(
        fakeRemoteConfig._defaults[RemoteConfigService.keyMaxDailyAiReviews],
        equals(5),
      );
      expect(
        fakeRemoteConfig._defaults[RemoteConfigService
            .keyMaxDailyRecommendations],
        equals(40),
      );
      expect(
        fakeRemoteConfig._defaults[RemoteConfigService
            .keyReviewTargetRecommendationCount],
        equals(10),
      );
      expect(
        fakeRemoteConfig._defaults[RemoteConfigService
            .keyReviewTargetGenerationCount],
        equals(3),
      );

      // 2. 타임아웃 및 패치 셋팅 확인
      expect(fakeRemoteConfig._settings, isNotNull);
      expect(
        fakeRemoteConfig._settings!.fetchTimeout,
        equals(const Duration(minutes: 1)),
      );

      // 3. fetchAndActivate 구동 확인
      expect(fakeRemoteConfig.fetchAndActivateCalled, isTrue);
    });

    test('원격 설정 조회 시 해당 값을 정확히 파싱해 반환하는지 겟터 검증', () async {
      // 강제 원격 값 셋업
      fakeRemoteConfig.mockSetValue(
        RemoteConfigService.keyReviewCooldownDays,
        30,
      );
      fakeRemoteConfig.mockSetValue(
        RemoteConfigService.keyMaxDailyAiReviews,
        10,
      );
      fakeRemoteConfig.mockSetValue(
        RemoteConfigService.keyMaxDailyRecommendations,
        50,
      );
      fakeRemoteConfig.mockSetValue(
        RemoteConfigService.keyReviewTargetRecommendationCount,
        15,
      );
      fakeRemoteConfig.mockSetValue(
        RemoteConfigService.keyReviewTargetGenerationCount,
        5,
      );

      expect(remoteConfigService.reviewCooldownDays, equals(30));
      expect(remoteConfigService.maxDailyAiReviews, equals(10));
      expect(remoteConfigService.maxDailyRecommendations, equals(50));
      expect(remoteConfigService.reviewTargetRecommendationCount, equals(15));
      expect(remoteConfigService.reviewTargetGenerationCount, equals(5));
    });

    test(
      'initialize() 수행 시 Firebase 예외가 터져도 정상적으로 안전 예외 처리를 거치는지 검증',
      () async {
        fakeRemoteConfig.raiseExceptionOnFetch = true;

        // 예외 발생 시 에러를 잡아내서 crash 없이 안전하게 통과해야 함
        await expectLater(remoteConfigService.initialize(), completes);
        expect(fakeRemoteConfig.fetchAndActivateCalled, isFalse);
      },
    );
  });
}

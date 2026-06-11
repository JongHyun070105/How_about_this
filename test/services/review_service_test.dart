import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:review_ai/services/review_service.dart';
import 'package:review_ai/services/api_proxy_service.dart';
import 'package:review_ai/presentation/providers/app_providers.dart';
import 'package:review_ai/presentation/providers/review_provider.dart';

// Mock/Fake 구현체 정의
class FakeApiProxyService extends ApiProxyService {
  final Future<List<String>> Function()? onGenerateReviews;

  FakeApiProxyService({this.onGenerateReviews})
    : super(http.Client(), 'http://fake');

  @override
  Future<List<String>> generateReviews({
    required String foodName,
    required double deliveryRating,
    required double tasteRating,
    required double portionRating,
    required double priceRating,
    required String reviewStyle,
    File? foodImage,
  }) async {
    if (onGenerateReviews != null) {
      return await onGenerateReviews!();
    }
    return ['정말 맛있어요!'];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // path_provider 플랫폼 채널 모킹
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getTemporaryDirectory') {
              return Directory.systemTemp.path;
            }
            return null;
          },
        );
  });

  late ProviderContainer container;
  late FakeApiProxyService fakeApiProxy;
  late File testImageFile;
  Future<List<String>> Function()? mockHandler;

  setUp(() async {
    fakeApiProxy = FakeApiProxyService(
      onGenerateReviews: () =>
          mockHandler != null ? mockHandler!() : Future.value(['기본 맛있다']),
    );

    // 디코딩 가능하고 최적화 대상인 900x900 크기의 JPEG 파일 생성
    final image = img.Image(width: 900, height: 900);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    final jpegBytes = img.encodeJpg(image);

    testImageFile = File('${Directory.systemTemp.path}/test_image.jpg');
    await testImageFile.writeAsBytes(jpegBytes);

    container = ProviderContainer(
      overrides: [geminiServiceProvider.overrideWithValue(fakeApiProxy)],
    );
  });

  tearDown(() async {
    if (await testImageFile.exists()) {
      await testImageFile.delete();
    }
    container.dispose();
  });

  group('ReviewService 자원 정리 및 캐싱 검증', () {
    test('API가 정상 완료되었을 때 임시 이미지가 안전하게 삭제된다', () async {
      final notifier = container.read(reviewProvider.notifier);
      notifier.setFoodName('치킨');
      notifier.setDeliveryRating(4.0);
      notifier.setTasteRating(4.0);
      notifier.setPortionRating(4.0);
      notifier.setPriceRating(4.0);
      notifier.setSelectedReviewStyle('SNS 스타일');
      notifier.setImage(testImageFile);

      mockHandler = () async => ['정말 맛있어요!'];

      final reviewService = container.read(reviewServiceProvider);
      final results = await reviewService.generateReviewsFromState();

      expect(results, ['정말 맛있어요!']);

      // 임시 파일 삭제 대기
      await Future.delayed(const Duration(milliseconds: 100));

      final tempDir = Directory(Directory.systemTemp.path);
      final hasTempOptimizedFiles = tempDir.listSync().any(
        (file) => file.path.contains('optimized_'),
      );
      expect(hasTempOptimizedFiles, isFalse, reason: '임시 최적화 파일이 삭제되어야 합니다.');
    });

    test('API 호출 시 예외가 발생하더라도 임시 이미지는 삭제된다', () async {
      final notifier = container.read(reviewProvider.notifier);
      notifier.setFoodName('치킨');
      notifier.setDeliveryRating(4.0);
      notifier.setTasteRating(4.0);
      notifier.setPortionRating(4.0);
      notifier.setPriceRating(4.0);
      notifier.setSelectedReviewStyle('SNS 스타일');
      notifier.setImage(testImageFile);

      mockHandler = () async => throw Exception('API Error');

      final reviewService = container.read(reviewServiceProvider);

      expect(() => reviewService.generateReviewsFromState(), throwsException);

      await Future.delayed(const Duration(milliseconds: 100));

      final tempDir = Directory(Directory.systemTemp.path);
      final hasTempOptimizedFiles = tempDir.listSync().any(
        (file) => file.path.contains('optimized_'),
      );
      expect(
        hasTempOptimizedFiles,
        isFalse,
        reason: '예외 발생 시에도 임시 파일이 정리되어야 합니다.',
      );
    });

    test('API 호출 시 타임아웃이 발생하더라도 임시 이미지는 성공적으로 정리된다', () async {
      final notifier = container.read(reviewProvider.notifier);
      notifier.setFoodName('치킨');
      notifier.setDeliveryRating(4.0);
      notifier.setTasteRating(4.0);
      notifier.setPortionRating(4.0);
      notifier.setPriceRating(4.0);
      notifier.setSelectedReviewStyle('SNS 스타일');
      notifier.setImage(testImageFile);

      mockHandler = () async => throw TimeoutException('처리 시간 초과');

      final reviewService = container.read(reviewServiceProvider);

      expect(
        () => reviewService.generateReviewsFromState(),
        throwsA(isA<TimeoutException>()),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      final tempDir = Directory(Directory.systemTemp.path);
      final hasTempOptimizedFiles = tempDir.listSync().any(
        (file) => file.path.contains('optimized_'),
      );
      expect(
        hasTempOptimizedFiles,
        isFalse,
        reason: '타임아웃 발생 시에도 임시 파일이 삭제되어야 합니다.',
      );
    });
  });
}

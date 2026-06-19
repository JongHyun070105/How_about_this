import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:review_ai/services/auth_service.dart';
import 'package:review_ai/services/image_labeling_service.dart';

class CloseTrackingClient extends http.BaseClient {
  final http.Client _inner;
  bool isClosed = false;

  CloseTrackingClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request);
  }

  @override
  void close() {
    isClosed = true;
    _inner.close();
    super.close();
  }
}

void main() {
  late Directory tempDir;

  setUp(() {
    AuthService.setMockToken(
      accessToken: 'test_token',
      expiry: DateTime.now().add(const Duration(hours: 1)),
    );
    tempDir = Directory.systemTemp.createTempSync('image_labeling_test');
  });

  tearDown(() {
    AuthService.setMockToken(
      accessToken: null,
      refreshToken: null,
      expiry: null,
    );
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ImageLabelingService Resource Lifecycle 테스트', () {
    test('외부에서 주입한 http.Client는 dispose 시 close되지 않아야 함', () {
      final mockInner = MockClient((request) async => http.Response('', 200));
      final trackingClient = CloseTrackingClient(mockInner);

      final service = ImageLabelingService(httpClient: trackingClient);
      service.dispose();

      expect(trackingClient.isClosed, isFalse);
    });

    test('내부에서 직접 생성한 http.Client는 dispose 시 close되어야 함', () {
      final mockInner = MockClient((request) async => http.Response('', 200));
      final trackingClient = CloseTrackingClient(mockInner);

      final service = ImageLabelingService.internal(
        httpClient: trackingClient,
        isOwnClient: true,
      );
      service.dispose();

      expect(trackingClient.isClosed, isTrue);
    });
  });

  group('ImageLabelingService.getLabels 테스트', () {
    test('음식 이미지 분석 성공 시 음식 이름 리스트 반환', () async {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': '피자'},
              ],
            },
          },
        ],
      };

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode(mockResponse),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = ImageLabelingService(httpClient: mockClient);
      final dummyFile = File('${tempDir.path}/pizza.jpg')
        ..writeAsBytesSync([1, 2, 3, 4]);

      final labels = await service.getLabels(dummyFile);
      expect(labels, contains('피자'));
      expect(labels.length, 1);
    });

    test('음식이 아닌 이미지 분석 결과("NOT_FOOD") 수신 시 빈 리스트 반환', () async {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'NOT_FOOD'},
              ],
            },
          },
        ],
      };

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode(mockResponse),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = ImageLabelingService(httpClient: mockClient);
      final dummyFile = File('${tempDir.path}/chair.jpg')
        ..writeAsBytesSync([1, 2, 3, 4]);

      final labels = await service.getLabels(dummyFile);
      expect(labels, isEmpty);
    });

    test('음식이 아닌 이미지 분석 결과("음식 아님") 수신 시 빈 리스트 반환', () async {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': '음식 아님'},
              ],
            },
          },
        ],
      };

      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode(mockResponse),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = ImageLabelingService(httpClient: mockClient);
      final dummyFile = File('${tempDir.path}/chair.jpg')
        ..writeAsBytesSync([1, 2, 3, 4]);

      final labels = await service.getLabels(dummyFile);
      expect(labels, isEmpty);
    });

    test('API 통신 오류(500 에러) 발생 시 예외 없이 빈 리스트 안전 반환', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ImageLabelingService(httpClient: mockClient);
      final dummyFile = File('${tempDir.path}/pizza.jpg')
        ..writeAsBytesSync([1, 2, 3, 4]);

      final labels = await service.getLabels(dummyFile);
      expect(labels, isEmpty);
    });
  });
}

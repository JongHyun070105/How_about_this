import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:review_ai/services/notification_service.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {
  final Map<String, bool> _store = {};
  int getCallCount = 0;
  int setCallCount = 0;

  @override
  bool? getBool(String key) {
    getCallCount++;
    return _store[key];
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    setCallCount++;
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }
}

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {
  int initializeCalls = 0;
  int cancelCalls = 0;
  int cancelAllCalls = 0;
  int zonedScheduleCalls = 0;
  List<int> cancelledIds = [];
  List<Map<String, dynamic>> scheduledNotifications = [];

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    onDidReceiveNotificationResponse,
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCalls++;
    return true;
  }

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelCalls++;
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    cancelledIds.clear();
    scheduledNotifications.clear();
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    zonedScheduleCalls++;
    scheduledNotifications.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
    });
  }
}

void main() {
  late MockSharedPreferences mockPrefs;
  late MockFlutterLocalNotificationsPlugin mockNotifications;
  late NotificationService notificationService;

  setUpAll(() {
    // 타임존 데이터베이스 초기화 (테스트 실행 에러 방지)
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  });

  setUp(() {
    mockPrefs = MockSharedPreferences();
    mockNotifications = MockFlutterLocalNotificationsPlugin();
    notificationService = NotificationService();
    notificationService.configure(
      notifications: mockNotifications,
      prefs: mockPrefs,
    );
    notificationService.clearCache();
  });

  group('NotificationService 캐싱 및 기능 단위 테스트', () {
    test(
      '최초 알림 상태 조회 시 SharedPreferences I/O가 발생하고 이후에는 캐싱된 메모리를 사용한다',
      () async {
        mockPrefs._store['notification_lunch_enabled'] = true;
        mockPrefs._store['notification_dinner_enabled'] = false;

        // 1. 최초 조회
        final lunch1 = await notificationService.isLunchNotificationEnabled();
        final dinner1 = await notificationService.isDinnerNotificationEnabled();

        expect(lunch1, isTrue);
        expect(dinner1, isFalse);
        expect(mockPrefs.getCallCount, 2); // 2번 조회 (점심, 저녁 각각 최초 1회)

        final initialGetCalls = mockPrefs.getCallCount;

        // 2. 2회차 연속 조회
        final lunch2 = await notificationService.isLunchNotificationEnabled();
        final dinner2 = await notificationService.isDinnerNotificationEnabled();

        expect(lunch2, isTrue);
        expect(dinner2, isFalse);
        expect(
          mockPrefs.getCallCount,
          initialGetCalls,
        ); // 추가적인 SharedPreferences I/O가 발생하지 않음 (캐시 적용)
      },
    );

    test('알림 상태 토글 시 메모리 캐시 및 디스크에 즉시 반영된다', () async {
      mockPrefs._store['notification_lunch_enabled'] = false;
      mockPrefs._store['notification_dinner_enabled'] = false;

      // 1. 최초 조회로 캐시 채움
      await notificationService.isLunchNotificationEnabled();
      mockPrefs.getCallCount = 0;
      mockPrefs.setCallCount = 0;

      // 2. 점심 알림 켜기
      await notificationService.toggleLunchNotification(true);

      expect(mockPrefs.setCallCount, 1); // 쓰기 1회 발생
      expect(mockPrefs.getCallCount, 0); // 캐시가 있으므로 추가 읽기 I/O는 0회

      // 3. 알림 값 재확인
      final lunchEnabled = await notificationService
          .isLunchNotificationEnabled();
      expect(lunchEnabled, isTrue);
      expect(mockPrefs.getCallCount, 0); // 여전히 읽기 I/O는 0회 (캐시 반환)
      expect(mockNotifications.zonedScheduleCalls, 1); // 알림 예약 호출 검증
    });

    test('모든 알림 취소 시 캐시가 false로 리셋되고 알림 취소 API가 실행된다', () async {
      mockPrefs._store['notification_lunch_enabled'] = true;
      mockPrefs._store['notification_dinner_enabled'] = true;

      // 캐시 채우기
      await notificationService.isLunchNotificationEnabled();
      await notificationService.isDinnerNotificationEnabled();

      mockPrefs.getCallCount = 0;
      mockPrefs.setCallCount = 0;

      // 전체 취소
      await notificationService.cancelAllNotifications();

      expect(mockNotifications.cancelAllCalls, 1); // cancelAll API 호출
      expect(mockPrefs.setCallCount, 2); // 점심, 저녁에 각각 false 쓰는 동작

      // 캐시 상태가 false인지 디스크 I/O 없이 확인
      final lunch = await notificationService.isLunchNotificationEnabled();
      final dinner = await notificationService.isDinnerNotificationEnabled();

      expect(lunch, isFalse);
      expect(dinner, isFalse);
      expect(mockPrefs.getCallCount, 0); // 읽기 I/O 0회
    });
  });
}

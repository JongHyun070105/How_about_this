import 'dart:io';
import 'package:review_ai/core/utils/logger_service.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:review_ai/presentation/providers/review_provider.dart';
import 'package:review_ai/services/food_insight_service.dart';

/// 로컬 푸시 알림 서비스
///
/// 점심(12:00)과 저녁(19:00) 시간에 음식 추천 알림을 전송합니다.
/// 서버 없이 로컬에서 동작하며, 앱 재시작/폰 재부팅 후에도 알림이 유지됩니다.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 개인화 메시지용 히스토리 데이터
  List<ReviewHistoryEntry> _history = [];

  /// 권한 요청 중복 방지 플래그
  bool _isRequestingPermission = false;

  /// SharedPreferences 캐시
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // 알림 ID
  static const int _lunchNotificationId = 1001;
  static const int _dinnerNotificationId = 1002;

  // SharedPreferences 키
  static const String _lunchEnabledKey = 'notification_lunch_enabled';
  static const String _dinnerEnabledKey = 'notification_dinner_enabled';

  // 알림 시간
  static const int _lunchHour = 12;
  static const int _lunchMinute = 0;
  static const int _dinnerHour = 19;
  static const int _dinnerMinute = 0;

  /// 알림 서비스 초기화
  Future<void> initialize() async {
    // 타임존 초기화
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (e, stack) {
      LoggerService.e('타임존 초기화 실패', e, stack);
    }

    // Android 설정
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS 설정
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 저장된 알림 설정에 따라 알림 예약
    await _restoreNotifications();
  }

  /// 알림 탭 시 처리
  void _onNotificationTapped(NotificationResponse response) {
    LoggerService.d('알림 탭됨: ${response.payload}');
    // 앱이 열리면 자동으로 메인 화면으로 이동
  }

  /// 알림 권한 상태 확인
  Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      // Android 13 이상에서는 별도의 알림 권한이 필요함
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS에서는 알림 플러그인의 권한 체크 사용
      final settings = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return false;
  }

  /// 알림 권한 요청
  Future<bool> requestPermissions() async {
    if (_isRequestingPermission) return false;
    _isRequestingPermission = true;

    try {
      if (Platform.isIOS) {
        final result = await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return result ?? false;
      } else if (Platform.isAndroid) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        // Android 13+ 알림 권한 요청
        final result = await androidPlugin?.requestNotificationsPermission();
        return result ?? false;
      }
      return false;
    } finally {
      _isRequestingPermission = false;
    }
  }

  /// 저장된 설정에 따라 알림 복원
  Future<void> _restoreNotifications() async {
    final prefs = await _getPrefs();

    final lunchEnabled = prefs.getBool(_lunchEnabledKey) ?? false;
    final dinnerEnabled = prefs.getBool(_dinnerEnabledKey) ?? false;

    if (lunchEnabled) {
      await _scheduleLunchNotification();
    }
    if (dinnerEnabled) {
      await _scheduleDinnerNotification();
    }
  }

  /// 점심 알림 활성화/비활성화
  Future<void> toggleLunchNotification(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_lunchEnabledKey, enabled);

    if (enabled) {
      await _scheduleLunchNotification();
    } else {
      await _notifications.cancel(_lunchNotificationId);
    }
  }

  /// 저녁 알림 활성화/비활성화
  Future<void> toggleDinnerNotification(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_dinnerEnabledKey, enabled);

    if (enabled) {
      await _scheduleDinnerNotification();
    } else {
      await _notifications.cancel(_dinnerNotificationId);
    }
  }

  /// 개인화 알림 메시지 업데이트
  ///
  /// 히스토리 데이터를 받아 개인화된 알림 메시지로 알림을 재예약합니다.
  Future<void> updatePersonalizedMessages(
    List<ReviewHistoryEntry> history,
  ) async {
    _history = List.unmodifiable(history);
    // 활성화된 알림이 있으면 개인화 메시지로 재예약
    await _restoreNotifications();
  }

  /// 점심 알림 예약
  Future<void> _scheduleLunchNotification() async {
    final message = _history.isNotEmpty
        ? FoodInsightService.generateInsightMessage(_history)
        : '오늘의 추천 메뉴를 확인해보세요!';
    await _scheduleDailyNotification(
      id: _lunchNotificationId,
      hour: _lunchHour,
      minute: _lunchMinute,
      title: '🍽️ 점심 메뉴 추천',
      body: message,
    );
  }

  /// 저녁 알림 예약
  Future<void> _scheduleDinnerNotification() async {
    final message = _history.isNotEmpty
        ? FoodInsightService.generateInsightMessage(_history)
        : '오늘 저녁은 뭐 먹을까요?';
    await _scheduleDailyNotification(
      id: _dinnerNotificationId,
      hour: _dinnerHour,
      minute: _dinnerMinute,
      title: '🌙 저녁 식사 시간!',
      body: message,
    );
  }

  /// 매일 반복 알림 예약
  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'meal_reminder_channel',
      '식사 알림',
      channelDescription: '점심/저녁 식사 시간 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_notification',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 반복
    );

    LoggerService.d('알림 예약됨: $title at $hour:$minute');
  }

  /// 다음 알림 시간 계산
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // 이미 지난 시간이면 다음 날로 설정
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 점심 알림 활성화 상태
  Future<bool> isLunchNotificationEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_lunchEnabledKey) ?? false;
  }

  /// 저녁 알림 활성화 상태
  Future<bool> isDinnerNotificationEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_dinnerEnabledKey) ?? false;
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();

    final prefs = await _getPrefs();
    await prefs.setBool(_lunchEnabledKey, false);
    await prefs.setBool(_dinnerEnabledKey, false);
  }
}

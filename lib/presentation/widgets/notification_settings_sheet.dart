import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:review_ai/services/notification_service.dart';

/// 알림 설정 바텀시트
///
/// 점심/저녁 알림을 on/off 할 수 있는 설정 UI입니다.
class NotificationSettingsSheet extends StatefulWidget {
  const NotificationSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const NotificationSettingsSheet(),
    );
  }

  @override
  State<NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  final NotificationService _notificationService = NotificationService();

  bool _lunchEnabled = false;
  bool _dinnerEnabled = false;
  bool _isLoading = true;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lunch = await _notificationService.isLunchNotificationEnabled();
    final dinner = await _notificationService.isDinnerNotificationEnabled();
    // 실제 OS 권한 상태 확인
    final hasPermission = await _notificationService.hasPermission();

    if (mounted) {
      setState(() {
        _lunchEnabled = lunch;
        _dinnerEnabled = dinner;
        _permissionGranted = hasPermission;
        _isLoading = false;
      });
    }
  }

  Future<bool> _ensurePermission() async {
    // 이미 권한이 있으면 true 반환
    if (await _notificationService.hasPermission()) {
      if (!_permissionGranted && mounted) {
        setState(() => _permissionGranted = true);
      }
      return true;
    }

    // 권한 요청
    final granted = await _notificationService.requestPermissions();
    if (mounted) {
      setState(() => _permissionGranted = granted);
    }

    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('알림 권한이 필요합니다. 설정에서 알림을 허용해주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return granted;
  }

  Future<void> _toggleLunch(bool value) async {
    // 알림을 켤 때만 권한 체크
    if (value) {
      final hasPermission = await _ensurePermission();
      if (!hasPermission) {
        // 권한이 없으면 다시 꺼진 상태로 유지
        if (mounted) setState(() => _lunchEnabled = false);
        return;
      }
    }

    await _notificationService.toggleLunchNotification(value);
    // 설정 변경 후 전체 상태 다시 로드하여 확실하게 UI 반영
    await _loadSettings();
  }

  Future<void> _toggleDinner(bool value) async {
    // 알림을 켤 때만 권한 체크
    if (value) {
      final hasPermission = await _ensurePermission();
      if (!hasPermission) {
        // 권한이 없으면 다시 꺼진 상태로 유지
        if (mounted) setState(() => _dinnerEnabled = false);
        return;
      }
    }

    await _notificationService.toggleDinnerNotification(value);
    // 설정 변경 후 전체 상태 다시 로드하여 확실하게 UI 반영
    await _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context).dialogTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 헤더
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '식사 알림',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SCDream',
                        ),
                      ),
                      Text(
                        '식사 시간에 알림을 받아보세요',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              Theme.of(context).textTheme.bodySmall?.color ??
                              Colors.grey,
                          fontFamily: 'SCDream',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 알림 설정 목록
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CupertinoActivityIndicator(),
              )
            else ...[
              _buildNotificationTile(
                icon: Icons.wb_sunny_outlined,
                iconColor:
                    Theme.of(context).iconTheme.color ?? Colors.grey[800]!,
                title: '점심 알림',
                subtitle: '매일 오후 12:00',
                value: _lunchEnabled,
                onChanged: _toggleLunch,
              ),
              _buildNotificationTile(
                icon: Icons.nightlight_outlined,
                iconColor:
                    Theme.of(context).iconTheme.color ?? Colors.grey[800]!,
                title: '저녁 알림',
                subtitle: '매일 오후 7:00',
                value: _dinnerEnabled,
                onChanged: _toggleDinner,
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SCDream',
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey[600],
                    fontFamily: 'SCDream',
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: Theme.of(
              context,
            ).colorScheme.primary.withAlpha(255),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

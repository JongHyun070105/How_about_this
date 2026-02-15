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

    if (mounted) {
      setState(() {
        _lunchEnabled = lunch;
        _dinnerEnabled = dinner;
        _permissionGranted = lunch || dinner;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissionIfNeeded() async {
    if (!_permissionGranted) {
      final granted = await _notificationService.requestPermissions();
      if (mounted) {
        setState(() {
          _permissionGranted = granted;
        });
      }
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('알림 권한이 필요합니다. 설정에서 알림을 허용해주세요.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }
  }

  Future<void> _toggleLunch(bool value) async {
    if (value) await _requestPermissionIfNeeded();
    if (!_permissionGranted && value) return;

    await _notificationService.toggleLunchNotification(value);
    if (mounted) {
      setState(() => _lunchEnabled = value);
    }
  }

  Future<void> _toggleDinner(bool value) async {
    if (value) await _requestPermissionIfNeeded();
    if (!_permissionGranted && value) return;

    await _notificationService.toggleDinnerNotification(value);
    if (mounted) {
      setState(() => _dinnerEnabled = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: Colors.grey[300],
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
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: Colors.grey[800],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
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
                          color: Colors.grey,
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
                iconColor: Colors.grey[800]!,
                title: '점심 알림',
                subtitle: '매일 오후 12:00',
                value: _lunchEnabled,
                onChanged: _toggleLunch,
              ),
              _buildNotificationTile(
                icon: Icons.nightlight_outlined,
                iconColor: Colors.grey[800]!,
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
                    color: Colors.grey[600],
                    fontFamily: 'SCDream',
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: Colors.black,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

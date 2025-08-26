
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void _showStyledDialog({
  required BuildContext context,
  required String title,
  required String content,
  required List<Widget> actions,
  bool isError = false,
}) {
  final cupertinoActions = actions.map((widget) {
    if (widget is TextButton && widget.child is Text) {
      final textWidget = widget.child as Text;
      final isDestructive = textWidget.data == '설정으로 이동';

      return CupertinoDialogAction(
        onPressed: widget.onPressed,
        isDestructiveAction: isDestructive,
        child: Text(
          textWidget.data ?? '',
          style: TextStyle(
            fontFamily: 'Do Hyeon',
            fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }
    return widget;
  }).toList();

  showCupertinoDialog(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Do Hyeon',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            content,
            style: const TextStyle(fontFamily: 'Do Hyeon', fontSize: 16),
          ),
        ),
        actions: cupertinoActions,
      );
    },
  );
}

/// 위치 서비스 비활성화 안내 다이얼로그
void showLocationServiceDialog(BuildContext context) {
  _showStyledDialog(
    context: context,
    title: '위치 서비스 필요',
    content: '주변 음식점 추천을 위해 위치 서비스가 필요합니다.\n' '설정에서 위치 서비스를 활성화해주세요.',
    isError: true,
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('나중에'),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          Geolocator.openLocationSettings();
        },
        child: const Text('설정으로 이동'),
      ),
    ],
  );
}

/// 위치 권한 관련 다이얼로그
void showLocationPermissionDialog(
  BuildContext context,
  LocationPermission permission,
) {
  String title = '위치 권한 필요';
  String content = '위치 권한이 필요합니다.';
  List<Widget> actions = [];

  if (permission == LocationPermission.denied) {
    title = '위치 권한 필요';
    content = '주변 음식점 추천을 위해 위치 권한이 필요합니다.\n' '나중에 설정에서 변경할 수 있습니다.';
    actions = [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('확인'),
      ),
    ];
  } else if (permission == LocationPermission.deniedForever) {
    title = '위치 권한 설정 필요';
    content = '위치 권한이 영구적으로 거부되었습니다.\n' '앱 설정에서 위치 권한을 허용해주세요.';
    actions = [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('나중에'),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          Geolocator.openAppSettings();
        },
        child: const Text('설정으로 이동'),
      ),
    ];
  } else {
    title = '위치 권한 확인';
    content = '위치 권한 상태를 확인할 수 없습니다.\n' '설정에서 권한을 확인해주세요.';
    actions = [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('확인'),
      ),
    ];
  }

  _showStyledDialog(
    context: context,
    title: title,
    content: content,
    actions: actions,
    isError: true,
  );
}

void showFeatureRestrictedDialog(
  BuildContext context,
  String featureName,
  String message,
) {
  _showStyledDialog(
    context: context,
    title: '$featureName 사용 불가',
    content: message,
    isError: true,
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('확인'),
      ),
    ],
  );
}

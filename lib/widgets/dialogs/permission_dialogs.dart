
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// 위치 서비스 비활성화 안내 다이얼로그
void showLocationServiceDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('위치 서비스 필요'),
        content: const Text(
          '주변 음식점 추천을 위해 위치 서비스가 필요합니다.\n' 
          '설정에서 위치 서비스를 활성화해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('나중에'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Geolocator.openLocationSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      );
    },
  );
}

/// 위치 권한 관련 다이얼로그
void showLocationPermissionDialog(
  BuildContext context,
  LocationPermission permission,
) {
  String title = '위치 권한 필요'; // 기본값 설정
  String content = '위치 권한이 필요합니다.'; // 기본값 설정
  List<Widget> actions = [];

  if (permission == LocationPermission.denied) {
    title = '위치 권한 필요';
    content =
        '주변 음식점 추천을 위해 위치 권한이 필요합니다.\n' 
        '나중에 설정에서 변경할 수 있습니다.';
    actions = [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('확인'),
      ),
    ];
  } else if (permission == LocationPermission.deniedForever) {
    title = '위치 권한 설정 필요';
    content =
        '위치 권한이 영구적으로 거부되었습니다.\n' 
        '앱 설정에서 위치 권한을 허용해주세요.';
    actions = [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
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
    // 기타 경우에 대한 처리
    title = '위치 권한 확인';
    content =
        '위치 권한 상태를 확인할 수 없습니다.\n' 
        '설정에서 권한을 확인해주세요.';
    actions = [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('확인'),
      ),
    ];
  }

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions,
      );
    },
  );
}

void showFeatureRestrictedDialog(
  BuildContext context,
  String featureName,
  String message,
) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('$featureName 권한 필요'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('확인'),
          ),
        ],
      );
    },
  );
}

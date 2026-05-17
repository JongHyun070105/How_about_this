import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 스플래시 화면 초기화 시 사용되는 유틸리티성 헬퍼 메소드 제공
class SplashHelper {
  /// 인터넷 연결 활성화 여부 확인
  static Future<bool> checkInternetConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) return false;

      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 앱 업데이트용 스토어 URL 열기
  static Future<void> launchStoreUrl() async {
    final url = Platform.isIOS
        ? 'https://itunes.apple.com/app/id6751484486'
        : 'https://play.google.com/store/apps/details?id=com.jonghyun.reviewai_flutter';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

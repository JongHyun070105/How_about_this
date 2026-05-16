// lib/utils/network_utils.dart
import 'dart:io';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:review_ai/core/utils/logger_service.dart';

class NetworkUtils {
  static Future<bool> checkInternetConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false; // 네트워크 인터페이스 없음
      }

      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true; // 인터넷 접근 가능
      }
      return false;
    } on TimeoutException catch (_) {
      return false; // 조회 시간 초과
    } on SocketException catch (_) {
      return false; // 인터넷 접근 불가
    } catch (e) {
      LoggerService.e('Error checking internet connectivity: $e');
      return false;
    }
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:flutter/material.dart';
import 'package:review_ai/widgets/common/app_dialogs.dart';
import 'package:url_launcher/url_launcher.dart'; // Added url_launcher import
import 'app_constants.dart';
import 'environment_config.dart';

/// 앱의 보안 설정을 관리하는 클래스
class SecurityConfig {
  SecurityConfig._();

  // Ad ID Management (as before)

  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  // iOS Production Ad Unit IDs
  // static const String _prodRewardedAdUnitIdIOS =
  //     'ca-app-pub-6555743055922387/1329741925';
  // static const String _prodBannerAdUnitIdIOS =
  //     'ca-app-pub-6555743055922387/7591365110';

  static String get rewardedAdUnitId {
    if (Platform.isIOS) {
      return _testRewardedAdUnitId; // Use test ID for iOS
    }
    return _testRewardedAdUnitId; // Use test ID for Android and other platforms
  }

  static String get bannerAdUnitId {
    if (Platform.isIOS) {
      return _testBannerAdUnitId; // Use test ID for iOS
    }
    return _testBannerAdUnitId; // Use test ID for Android and other platforms
  }

  static bool get isUsingTestAds {
    // If it's iOS, and we are using production IDs, then it's not using test ads.
    // Otherwise, it's using test ads.
    return !Platform.isIOS;
  }

  static void logAdConfiguration() {
    if (shouldLogDetailed) {
      debugPrint('=== 광고 설정 상태 ===');
      debugPrint('테스트 모드: 활성');
      debugPrint('리워드 광고 ID: $rewardedAdUnitId');
      debugPrint('배너 광고 ID: $bannerAdUnitId');
      debugPrint('==================');
    }
  }

  // API Key Management (as before)
  static String? get geminiApiKey => dotenv.env['GEMINI_API_KEY'];
  static bool get hasValidApiKey => isValidApiKey(geminiApiKey);
  static bool isValidApiKey(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) return false;
    return apiKey.length > 20 && apiKey.startsWith('AIza');
  }

  // Logging & Error Handling (as before)
  static bool get shouldLogDetailed => EnvironmentConfig.enableVerboseLogging;
  static String sanitizeErrorMessage(String error) {
    return error
        .replaceAll(RegExp(AppConstants.apiKeyHiddenPattern), 'API_KEY_HIDDEN')
        .replaceAll(RegExp(AppConstants.tokenHiddenPattern), 'TOKEN_HIDDEN')
        .replaceAll(RegExp(AppConstants.pathHiddenPattern), 'PATH_HIDDEN/');
  }

  // App Integrity & Security Checks (as before)
  static Future<bool> verifyAppIntegrity() async => true; // Simplified for now
  static bool detectDebugger() => kDebugMode || kProfileMode;

  /// 직접 구현한 루팅/탈옥 탐지
  static Future<bool> detectRootingOrJailbreak() async {
    try {
      if (Platform.isAndroid) {
        return await _checkAndroidRoot();
      } else if (Platform.isIOS) {
        return await _checkIOSJailbreak();
      }
      return false;
    } catch (e) {
      debugPrint('Jailbreak detection failed: $e');
      return false;
    }
  }

  /// Android 루팅 탐지
  static Future<bool> _checkAndroidRoot() async {
    try {
      // 1. 일반적인 루트 파일들 체크
      const rootFiles = [
        '/system/app/Superuser.apk',
        '/sbin/su',
        '/system/bin/su',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
        '/system/xbin/which',
        '/data/data/com.noshufou.android.su',
        '/system/bin/.ext/.su',
        '/system/usr/we-need-root/su-backup',
        '/system/xbin/mu',
      ];

      for (String filePath in rootFiles) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            debugPrint('Root file detected: $filePath');
            return true;
          }
        } catch (e) {
          // 파일 접근 실패는 정상 (권한 부족)
          continue;
        }
      }

      // 2. 루트 앱들 체크
      const rootApps = [
        'com.noshufou.android.su',
        'com.noshufou.android.su.elite',
        'eu.chainfire.supersu',
        'com.koushikdutta.superuser',
        'com.thirdparty.superuser',
        'com.yellowes.su',
        'com.koushikdutta.rommanager',
        'com.koushikdutta.rommanager.license',
        'com.dimonvideo.luckypatcher',
        'com.chelpus.lackypatch',
        'com.ramdroid.appquarantine',
        'com.ramdroid.appquarantinepro',
        'com.topjohnwu.magisk',
        'com.kingroot.kinguser',
        'com.kingo.root',
        'com.smedialink.oneclickroot',
        'com.zhiqupk.root.global',
        'com.alephzain.framaroot',
      ];

      for (String packageName in rootApps) {
        if (await _isPackageInstalled(packageName)) {
          debugPrint('Root app detected: $packageName');
          return true;
        }
      }

      // 3. BUILD 태그 체크
      if (await _checkBuildTags()) {
        debugPrint('Suspicious build tags detected');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Android root check error: $e');
      return false;
    }
  }

  /// iOS 탈옥 탐지
  static Future<bool> _checkIOSJailbreak() async {
    try {
      // iOS에서는 파일 시스템 접근이 제한적이므로 기본적인 체크만 수행
      const jailbreakFiles = [
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
        '/private/var/lib/apt/',
        '/private/var/lib/cydia',
        '/private/var/mobile/Library/SBSettings/Themes',
        '/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist',
        '/System/Library/LaunchDaemons/com.ikey.bbot.plist',
        '/private/var/cache/apt',
        '/private/var/lib/apt',
        '/private/var/tmp/cydia.log',
        '/Applications/MxTube.app',
        '/Applications/RockApp.app',
        '/Applications/blackra1n.app',
        '/Applications/FakeCarrier.2app',
        '/Applications/Icy.app',
        '/Applications/IntelliScreen.app',
        '/Applications/SBSettings.app',
      ];

      for (String filePath in jailbreakFiles) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            debugPrint('Jailbreak file detected: $filePath');
            return true;
          }
        } catch (e) {
          // 파일 접근 실패는 정상 (샌드박스 제한)
          continue;
        }
      }

      // URL scheme 체크
      const jailbreakSchemes = [
        'cydia://',
        'sileo://',
        'zbra://',
        'filza://',
        'activator://',
      ];

      for (String scheme in jailbreakSchemes) {
        try {
          if (await canLaunchUrl(Uri.parse(scheme))) {
            debugPrint('Jailbreak scheme detected: $scheme');
            return true;
          }
        } catch (e) {
          debugPrint('Error checking scheme $scheme: $e');
          continue;
        }
      }

      return false;
    } catch (e) {
      debugPrint('iOS jailbreak check error: $e');
      return false;
    }
  }

  /// 패키지 설치 여부 확인 (Android)
  static Future<bool> _isPackageInstalled(String packageName) async {
    try {
      // 실제로는 더 정교한 방법이 필요하지만,
      // 기본적인 체크를 위해 간단하게 구현
      final result = await Process.run('pm', ['list', 'packages', packageName]);
      return result.stdout.toString().contains(packageName);
    } catch (e) {
      // pm 명령어 실행 실패는 일반 기기에서 정상
      return false;
    }
  }

  /// BUILD 태그 체크 (Android)
  static Future<bool> _checkBuildTags() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      final tags = androidInfo.tags.toLowerCase();

      // 의심스러운 빌드 태그들
      const suspiciousTags = [
        'test-keys',
        'dev-keys',
        'unofficial',
        'userdebug',
      ];

      for (String tag in suspiciousTags) {
        if (tags.contains(tag)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> detectEmulator() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;

        // 물리적 기기 여부 체크
        if (!androidInfo.isPhysicalDevice) {
          return true;
        }

        // 에뮬레이터 특성 체크
        final model = androidInfo.model.toLowerCase();
        final brand = androidInfo.brand.toLowerCase();
        final device = androidInfo.device.toLowerCase();
        final product = androidInfo.product.toLowerCase();
        final hardware = androidInfo.hardware.toLowerCase();

        const emulatorIndicators = [
          // 일반적인 에뮬레이터
          'sdk', 'emulator', 'simulator', 'genymotion', 'bluestacks',
          // Android Studio 에뮬레이터
          'android sdk built for x86', 'google_sdk', 'droid4x', 'andy',
          // 기타 에뮬레이터들
          'vbox86', 'ttvm', 'nox', 'ldplayer', 'memu',
        ];

        final deviceStrings = [model, brand, device, product, hardware];

        for (String deviceString in deviceStrings) {
          for (String indicator in emulatorIndicators) {
            if (deviceString.contains(indicator)) {
              debugPrint(
                'Emulator detected: $deviceString contains $indicator',
              );
              return true;
            }
          }
        }

        return false;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return !iosInfo.isPhysicalDevice;
      }
      return false;
    } catch (e) {
      debugPrint('Emulator detection error: $e');
      return false;
    }
  }
}

class SecurityInitializer {
  SecurityInitializer._();

  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
    if (!SecurityConfig.hasValidApiKey) {
      throw Exception('GEMINI_API_KEY is not set in .env file');
    }
  }

  static Future<SecurityCheckResult> performRuntimeSecurityCheck() async {
    final result = SecurityCheckResult();
    try {
      result.isRootedOrJailbroken =
          await SecurityConfig.detectRootingOrJailbreak();
      result.isDebuggerAttached = SecurityConfig.detectDebugger();
      result.isAppIntegrityValid = await SecurityConfig.verifyAppIntegrity();
      result.isEmulator = await SecurityConfig.detectEmulator();
      result.isSecure = _calculateOverallSecurityStatus(result);
    } catch (e) {
      result.error = SecurityConfig.sanitizeErrorMessage(e.toString());
      result.isSecure = false;
    }
    return result;
  }

  static bool _calculateOverallSecurityStatus(SecurityCheckResult result) {
    if (EnvironmentConfig.isDevelopment) {
      return !result.isRootedOrJailbroken && result.isAppIntegrityValid;
    }
    return !result.isRootedOrJailbroken &&
        !result.isDebuggerAttached &&
        result.isAppIntegrityValid &&
        !result.isEmulator;
  }

  static Future<void> handleSecurityThreat(
    BuildContext context,
    SecurityCheckResult result,
  ) async {
    if (result.isSecure || !context.mounted) return;

    String message = '';
    if (result.isRootedOrJailbroken) {
      message = '보안상의 이유로 루팅 또는 탈옥된 기기에서는 앱을 사용할 수 없습니다.';
    } else if (!result.isAppIntegrityValid) {
      message = '앱이 위변조되었습니다. 공식 스토어에서 다시 다운로드해주세요.';
    } else if (result.isDebuggerAttached && !EnvironmentConfig.isDevelopment) {
      message = '디버거가 연결되어 있어 앱을 종료합니다.';
    } else if (result.isEmulator && !EnvironmentConfig.isDevelopment) {
      message = '에뮬레이터 환경에서는 앱을 실행할 수 없습니다.';
    }

    if (message.isNotEmpty) {
      showAppDialog(
        context,
        title: '보안 경고',
        message: message,
        isError: true,
        cancelButtonText: '앱 종료',
        onConfirm: () => SystemNavigator.pop(), // This will close the app
      );
    }
  }
}

class SecurityCheckResult {
  bool isRootedOrJailbroken = false;
  bool isDebuggerAttached = false;
  bool isAppIntegrityValid = true;
  bool isEmulator = false;
  bool isSecure = true;
  String? error;
}

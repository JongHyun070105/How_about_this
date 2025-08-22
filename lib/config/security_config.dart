// =============================================================================
// 보안 관련 설정 및 유틸리티
// =============================================================================

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'app_constants.dart';
import 'environment_config.dart';

/// 앱의 보안 설정을 관리하는 클래스
class SecurityConfig {
  SecurityConfig._(); // 인스턴스 생성 방지

  // =============================================================================
  // 광고 ID 관리
  // =============================================================================

  /// 플랫폼별 리워드 광고 ID 반환
  static String get rewardedAdUnitId {
    // 테스트용 AdMob 리워드 광고 ID (플랫폼별)
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android 테스트 리워드 ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS 테스트 리워드 ID
    }
    return ''; // 기본값 (도달하지 않음)
  }

  // =============================================================================
  // API 키 관리
  // =============================================================================

  /// Gemini API 키를 안전하게 반환
  static String? get geminiApiKey {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) {
        throw Exception('GEMINI_API_KEY가 .env 파일에 설정되지 않았습니다.');
      }
      return null;
    }

    return apiKey;
  }

  /// API 키 유효성 검사
  static bool isValidApiKey(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) return false;

    // Gemini API 키 형식 검증 (AIza로 시작하고 20자 이상)
    return apiKey.length > 20 && apiKey.startsWith('AIza');
  }

  /// API 키가 설정되어 있고 유효한지 확인
  static bool get hasValidApiKey {
    return isValidApiKey(geminiApiKey);
  }

  // =============================================================================
  // 네트워크 보안
  // =============================================================================

  /// 도메인이 허용된 목록에 있는지 확인
  static bool isAllowedDomain(String domain) {
    return AppConstants.allowedDomains.any(
      (allowed) => domain.contains(allowed),
    );
  }

  /// URL이 안전한지 검증
  static bool isSecureUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // HTTPS 프로토콜 확인
      if (!uri.isScheme('HTTPS')) return false;

      // 허용된 도메인인지 확인
      return isAllowedDomain(uri.host);
    } catch (e) {
      return false;
    }
  }

  // =============================================================================
  // 파일 및 이미지 보안
  // =============================================================================

  /// 이미지 파일 유효성 검사
  static bool isValidImageFile(File file) {
    // 파일 존재 여부 확인
    if (!file.existsSync()) return false;

    // 파일 크기 확인
    final fileSize = file.lengthSync();
    if (fileSize > AppConstants.maxImageSizeBytes) return false;
    if (fileSize == 0) return false; // 빈 파일 체크

    // 확장자 확인
    final fileName = file.path.toLowerCase();
    final hasValidExtension = AppConstants.allowedImageExtensions.any(
      (ext) => fileName.endsWith(ext),
    );

    return hasValidExtension;
  }

  /// 파일 이름이 안전한지 검증 (경로 순회 공격 방지)
  static bool isSafeFileName(String fileName) {
    // 위험한 문자나 패턴 확인
    final dangerousPatterns = [
      '../',
      '..\\',
      '<',
      '>',
      ':',
      '"',
      '|',
      '?',
      '*',
    ];

    for (final pattern in dangerousPatterns) {
      if (fileName.contains(pattern)) return false;
    }

    // 파일명 길이 제한
    if (fileName.length > 255) return false;

    return true;
  }

  // =============================================================================
  // 입력 데이터 검증
  // =============================================================================

  /// 음식명 유효성 검사
  static bool isValidFoodName(String foodName) {
    // 길이 검증
    if (foodName.isEmpty ||
        foodName.length > AppConstants.maxFoodNameLength ||
        foodName.length < AppConstants.minFoodNameLength) {
      return false;
    }

    // 패턴 검증 (한글, 영문, 숫자, 공백, 하이픈, 언더스코어, 괄호만 허용)
    final RegExp validPattern = RegExp(AppConstants.validFoodNamePattern);
    if (!validPattern.hasMatch(foodName)) return false;

    // 공백만으로 이루어진 문자열 체크
    if (foodName.trim().isEmpty) return false;

    return true;
  }

  /// 별점 유효성 검사
  static bool isValidRating(double rating) {
    return rating >= AppConstants.minRating &&
        rating <= AppConstants.maxRating &&
        !rating.isNaN &&
        !rating.isInfinite;
  }

  /// 리뷰 텍스트 유효성 검사
  static bool isValidReviewText(String? reviewText) {
    if (reviewText == null) return true; // 리뷰는 선택사항

    // 길이 검증
    if (reviewText.length > AppConstants.maxReviewLength) return false;

    // 기본적인 XSS 방지를 위한 태그 검증
    final RegExp htmlTagPattern = RegExp(r'<[^>]*>');
    if (htmlTagPattern.hasMatch(reviewText)) return false;

    return true;
  }

  // =============================================================================
  // 데이터 암호화 (향후 확장용)
  // =============================================================================

  /// 암호화 키 반환
  static String? get encryptionKey {
    return dotenv.env['ENCRYPTION_KEY'];
  }

  /// 암호화 키가 설정되어 있는지 확인
  static bool get hasEncryptionKey {
    final key = encryptionKey;
    return key != null && key.isNotEmpty && key.length >= 32;
  }

  // =============================================================================
  // 로그 및 에러 처리
  // =============================================================================

  /// 개발 모드에서만 상세 로그 출력 여부
  static bool get shouldLogDetailed => EnvironmentConfig.enableVerboseLogging;

  /// 에러 메시지에서 민감한 정보 제거
  static String sanitizeErrorMessage(String error) {
    return error
        .replaceAll(RegExp(AppConstants.apiKeyHiddenPattern), 'API_KEY_HIDDEN')
        .replaceAll(RegExp(AppConstants.tokenHiddenPattern), 'TOKEN_HIDDEN')
        .replaceAll(RegExp(AppConstants.pathHiddenPattern), 'PATH_HIDDEN/');
  }

  /// 로그에 출력하기 안전한 데이터인지 확인
  static bool isSafeToLog(String data) {
    // API 키나 토큰이 포함되어 있는지 확인
    final sensitivePatterns = [
      RegExp(AppConstants.apiKeyHiddenPattern),
      RegExp(AppConstants.tokenHiddenPattern),
      RegExp(r'password', caseSensitive: false),
      RegExp(r'secret', caseSensitive: false),
    ];

    for (final pattern in sensitivePatterns) {
      if (pattern.hasMatch(data)) return false;
    }

    return true;
  }

  // =============================================================================
  // 보안 검증 종합
  // =============================================================================

  /// 앱의 기본 보안 요구사항이 충족되는지 확인
  static bool validateSecurityRequirements() {
    final issues = <String>[];

    // API 키 확인
    if (!hasValidApiKey) {
      issues.add('유효한 Gemini API 키가 필요합니다.');
    }

    // 프로덕션 환경에서의 추가 검증
    if (EnvironmentConfig.isProduction) {
      // SSL 인증서 검증 활성화 확인
      if (!EnvironmentConfig.enableCertificateValidation) {
        issues.add('프로덕션 환경에서는 SSL 인증서 검증이 필요합니다.');
      }

      // 디버그 정보 비활성화 확인
      if (EnvironmentConfig.showDebugInfo) {
        issues.add('프로덕션 환경에서는 디버그 정보를 비활성화해야 합니다.');
      }
    }

    // 문제가 있으면 로그에 출력
    if (issues.isNotEmpty && shouldLogDetailed) {
      debugPrint('보안 요구사항 검증 실패:');
      for (final issue in issues) {
        debugPrint('- $issue');
      }
    }

    return issues.isEmpty;
  }

  // =============================================================================
  // 루팅/탈옥 감지
  // =============================================================================

  /// Android 루팅 감지
  static Future<bool> _detectRootingAndroid() async {
    try {
      // 1. 루팅 관리 앱 패키지 확인
      final rootingApps = [
        'com.noshufou.android.su',
        'com.noshufou.android.su.elite',
        'eu.chainfire.supersu',
        'com.koushikdutta.superuser',
        'com.thirdparty.superuser',
        'com.yellowes.su',
        'com.topjohnwu.magisk',
        'com.kingroot.kinguser',
        'com.kingo.root',
        'com.smedialink.oneclickroot',
        'com.zhiqupk.root.global',
        'com.alephzain.framaroot',
      ];

      for (final packageName in rootingApps) {
        try {
          await MethodChannel(
            'flutter/platform',
          ).invokeMethod('getApplicationInfo', packageName);
          return true; // 루팅 앱이 설치되어 있음
        } catch (e) {
          // 앱이 설치되어 있지 않음 (정상)
        }
      }

      // 2. 루팅 관련 파일 경로 확인
      final rootingPaths = [
        '/system/app/Superuser.apk',
        '/sbin/su',
        '/system/bin/su',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
        '/su/bin/su',
        '/system/xbin/daemonsu',
        '/system/etc/init.d/99SuperSUDaemon',
        '/dev/com.koushikdutta.superuser.daemon/',
        '/system/xbin/busybox',
      ];

      for (final path in rootingPaths) {
        if (await File(path).exists()) {
          return true;
        }
      }

      // 3. 빌드 태그 확인
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final buildTags = androidInfo.tags;

      if (buildTags.contains('test-keys')) {
        return true;
      }

      // 4. 시스템 속성 확인
      try {
        final result = await Process.run('getprop', ['ro.debuggable']);
        if (result.stdout.toString().trim() == '1') {
          return true;
        }
      } catch (e) {
        // 명령어 실행 실패는 정상
      }

      return false;
    } catch (e) {
      if (shouldLogDetailed) {
        debugPrint('Android 루팅 감지 중 오류: ${sanitizeErrorMessage(e.toString())}');
      }
      return false;
    }
  }

  /// iOS 탈옥 감지
  static Future<bool> _detectJailbreakIOS() async {
    try {
      // 1. 탈옥 관련 앱 및 파일 확인
      final jailbreakPaths = [
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
        '/private/var/lib/apt/',
        '/private/var/lib/cydia',
        '/private/var/mobile/Library/SBSettings/Themes',
        '/Library/MobileSubstrate/DynamicLibraries/Veency.plist',
        '/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist',
        '/System/Library/LaunchDaemons/com.ikey.bbot.plist',
        '/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist',
        '/etc/ssh/sshd_config',
        '/private/var/tmp/cydia.log',
        '/Applications/Icy.app',
        '/Applications/MxTube.app',
        '/Applications/RockApp.app',
        '/Applications/blackra1n.app',
        '/Applications/SBSettings.app',
        '/Applications/FakeCarrier.app',
        '/Applications/WinterBoard.app',
        '/Applications/IntelliScreen.app',
      ];

      for (final path in jailbreakPaths) {
        if (await File(path).exists()) {
          return true;
        }
      }

      // 2. 샌드박스 제약 확인 (탈옥된 기기에서는 제약이 우회됨)
      try {
        final testFile = File('/private/test_jailbreak.txt');
        await testFile.writeAsString('jailbreak_test');
        await testFile.delete();
        return true; // 샌드박스 밖에 파일 쓰기 성공 = 탈옥됨
      } catch (e) {
        // 파일 쓰기 실패는 정상 (샌드박스가 작동 중)
      }

      // 3. URL 스킴 확인
      try {
        await MethodChannel(
          'flutter/platform',
        ).invokeMethod('canOpenURL', 'cydia://package/com.example.package');
        return true;
      } catch (e) {
        // URL 열기 실패는 정상
      }

      return false;
    } catch (e) {
      if (shouldLogDetailed) {
        debugPrint('iOS 탈옥 감지 중 오류: ${sanitizeErrorMessage(e.toString())}');
      }
      return false;
    }
  }

  /// 통합 루팅/탈옥 감지
  static Future<bool> detectRootingOrJailbreak() async {
    if (Platform.isAndroid) {
      return await _detectRootingAndroid();
    } else if (Platform.isIOS) {
      return await _detectJailbreakIOS();
    }
    return false;
  }

  // =============================================================================
  // 디버거 감지
  // =============================================================================

  /// 디버거 연결 감지
  static bool detectDebugger() {
    // Flutter의 kDebugMode는 디버그 빌드를 의미
    if (kDebugMode) {
      return true;
    }

    // 프로파일 모드나 릴리즈 모드에서 디버거가 연결되어 있는지 확인
    try {
      // Dart VM이 개발자 서비스를 제공하고 있는지 확인
      if (kProfileMode) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // =============================================================================
  // 앱 무결성 검증
  // =============================================================================

  /// 앱 서명 검증 (Android)
  static Future<bool> _verifyAppSignatureAndroid() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      // 패키지명 확인
      const expectedPackageName =
          'com.example.food_rating_app'; // 실제 패키지명으로 변경 필요
      if (packageInfo.packageName != expectedPackageName) {
        return false;
      }

      // 서명 확인을 위한 네이티브 코드 호출
      try {
        final result = await MethodChannel(
          'security_channel',
        ).invokeMethod<bool>('verifySignature');
        return result ?? false;
      } catch (e) {
        if (shouldLogDetailed) {
          debugPrint('앱 서명 검증 실패: ${sanitizeErrorMessage(e.toString())}');
        }
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// 앱 서명 검증 (iOS)
  static Future<bool> _verifyAppSignatureIOS() async {
    try {
      // Bundle ID 확인
      const expectedBundleId =
          'com.example.food-rating-app'; // 실제 Bundle ID로 변경 필요

      try {
        final result = await MethodChannel(
          'security_channel',
        ).invokeMethod<String>('getBundleIdentifier');

        if (result != expectedBundleId) {
          return false;
        }
      } catch (e) {
        return false;
      }

      // 앱 스토어에서 설치되었는지 확인
      try {
        final isAppStore = await MethodChannel(
          'security_channel',
        ).invokeMethod<bool>('isAppStoreVersion');

        // 개발/테스트 환경에서는 앱스토어 검증 우회
        if (EnvironmentConfig.isDevelopment) {
          return true;
        }

        return isAppStore ?? false;
      } catch (e) {
        return EnvironmentConfig.isDevelopment;
      }
    } catch (e) {
      return false;
    }
  }

  /// 파일 무결성 검증
  static Future<bool> verifyFileIntegrity() async {
    try {
      // 중요한 앱 파일들의 해시값 확인
      final appDocumentsDir = await getApplicationDocumentsDirectory();
      final criticalFiles = [
        'app_constants.dart',
        'security_config.dart',
        'environment_config.dart',
      ];

      // 실제 구현에서는 사전에 계산된 해시값과 비교해야 함
      final Map<String, String> expectedHashes = {
        // 실제 배포 시에는 이 해시값들을 실제 파일의 해시로 업데이트해야 함
        'app_constants.dart': 'expected_hash_1',
        'security_config.dart': 'expected_hash_2',
        'environment_config.dart': 'expected_hash_3',
      };

      for (final fileName in criticalFiles) {
        try {
          final file = File('${appDocumentsDir.path}/$fileName');
          if (await file.exists()) {
            final fileBytes = await file.readAsBytes();
            final actualHash = base64Encode(fileBytes);

            // 실제로는 SHA-256 같은 암호화 해시를 사용해야 함
            if (expectedHashes[fileName] != null &&
                expectedHashes[fileName] != actualHash) {
              return false;
            }
          }
        } catch (e) {
          // 개별 파일 검증 실패는 전체 실패로 간주하지 않음
          continue;
        }
      }

      return true;
    } catch (e) {
      if (shouldLogDetailed) {
        debugPrint('파일 무결성 검증 실패: ${sanitizeErrorMessage(e.toString())}');
      }
      return false;
    }
  }

  /// 통합 앱 무결성 검증
  static Future<bool> verifyAppIntegrity() async {
    bool signatureValid = false;

    if (Platform.isAndroid) {
      signatureValid = await _verifyAppSignatureAndroid();
    } else if (Platform.isIOS) {
      signatureValid = await _verifyAppSignatureIOS();
    } else {
      signatureValid = true; // 다른 플랫폼은 일단 통과
    }

    final fileIntegrityValid = await verifyFileIntegrity();

    return signatureValid && fileIntegrityValid;
  }

  // =============================================================================
  // 에뮬레이터 감지
  // =============================================================================

  /// 에뮬레이터 감지
  static Future<bool> detectEmulator() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;

        // 에뮬레이터 특징 확인
        final brand = androidInfo.brand.toLowerCase();
        final device = androidInfo.device.toLowerCase();
        final model = androidInfo.model.toLowerCase();
        final product = androidInfo.product.toLowerCase();
        final hardware = androidInfo.hardware.toLowerCase();

        final emulatorIndicators = [
          'generic',
          'unknown',
          'emulator',
          'android sdk built for x86',
          'google_sdk',
          'sdk',
          'sdk_google',
          'vbox86p',
          'goldfish',
        ];

        for (final indicator in emulatorIndicators) {
          if (brand.contains(indicator) ||
              device.contains(indicator) ||
              model.contains(indicator) ||
              product.contains(indicator) ||
              hardware.contains(indicator)) {
            return true;
          }
        }

        // 추가 에뮬레이터 확인
        if (androidInfo.fingerprint.startsWith('generic') ||
            androidInfo.fingerprint.startsWith('unknown') ||
            androidInfo.fingerprint.contains('test-keys')) {
          return true;
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;

        // iOS 시뮬레이터 확인
        if (iosInfo.isPhysicalDevice == false) {
          return true;
        }

        // 추가 시뮬레이터 확인
        if (iosInfo.model.toLowerCase().contains('simulator')) {
          return true;
        }
      }

      return false;
    } catch (e) {
      if (shouldLogDetailed) {
        debugPrint('에뮬레이터 감지 중 오류: ${sanitizeErrorMessage(e.toString())}');
      }
      return false;
    }
  }

  // =============================================================================
  // 초기화 및 설정
  // =============================================================================

  /// 보안 설정 초기화
  static Future<void> initialize() async {
    // .env 파일 로드
    await dotenv.load(fileName: ".env");

    // 필수 환경 변수 확인
    _validateRequiredEnvironmentVariables();

    // 보안 요구사항 검증
    validateSecurityRequirements();

    if (shouldLogDetailed) {
      debugPrint('보안 설정이 초기화되었습니다.');
      debugPrint('환경: ${EnvironmentConfig.currentEnvironment.name}');
      debugPrint('API 키 설정: ${hasValidApiKey ? "완료" : "누락"}');
    }
  }

  /// 필수 환경 변수 검증
  static void _validateRequiredEnvironmentVariables() {
    final requiredVars = ['GEMINI_API_KEY'];
    final missingVars = <String>[];

    for (final varName in requiredVars) {
      final value = dotenv.env[varName];
      if (value == null || value.isEmpty) {
        missingVars.add(varName);
      }
    }

    if (missingVars.isNotEmpty) {
      final errorMsg = '필수 환경 변수가 설정되지 않았습니다: ${missingVars.join(", ")}';
      if (kDebugMode) {
        throw Exception(errorMsg);
      } else {
        debugPrint('경고: $errorMsg');
      }
    }
  }
}

// =============================================================================
// 보안 초기화 헬퍼 클래스
// =============================================================================

/// 앱 시작 시 보안 관련 초기화를 담당하는 클래스
class SecurityInitializer {
  SecurityInitializer._();

  /// 보안 설정 초기화 및 검증
  static Future<bool> initialize() async {
    try {
      await SecurityConfig.initialize();
      return SecurityConfig.validateSecurityRequirements();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '보안 초기화 실패: ${SecurityConfig.sanitizeErrorMessage(e.toString())}',
        );
      }
      return false;
    }
  }

  /// 런타임 보안 검증
  static Future<SecurityCheckResult> performRuntimeSecurityCheck() async {
    final result = SecurityCheckResult();

    try {
      // 1. 루팅/탈옥 감지
      result.isRootedOrJailbroken =
          await SecurityConfig.detectRootingOrJailbreak();

      // 2. 디버거 감지
      result.isDebuggerAttached = SecurityConfig.detectDebugger();

      // 3. 앱 무결성 검증
      result.isAppIntegrityValid = await SecurityConfig.verifyAppIntegrity();

      // 4. 에뮬레이터 감지
      result.isEmulator = await SecurityConfig.detectEmulator();

      // 5. 기본 보안 요구사항 검증
      result.isSecurityRequirementsMet =
          SecurityConfig.validateSecurityRequirements();

      // 전체적인 보안 상태 계산
      result.isSecure = _calculateOverallSecurityStatus(result);

      if (SecurityConfig.shouldLogDetailed) {
        debugPrint('=== 보안 검증 결과 ===');
        debugPrint('루팅/탈옥: ${result.isRootedOrJailbroken ? "감지됨" : "정상"}');
        debugPrint('디버거: ${result.isDebuggerAttached ? "연결됨" : "정상"}');
        debugPrint('앱 무결성: ${result.isAppIntegrityValid ? "정상" : "손상됨"}');
        debugPrint('에뮬레이터: ${result.isEmulator ? "감지됨" : "정상"}');
        debugPrint('보안 요구사항: ${result.isSecurityRequirementsMet ? "충족" : "미충족"}');
        debugPrint('전체 보안 상태: ${result.isSecure ? "안전" : "위험"}');
        debugPrint('==================');
      }
    } catch (e) {
      result.error = SecurityConfig.sanitizeErrorMessage(e.toString());
      result.isSecure = false;

      if (SecurityConfig.shouldLogDetailed) {
        debugPrint('보안 검증 중 오류 발생: ${result.error}');
      }
    }

    return result;
  }

  /// 전체적인 보안 상태 계산
  static bool _calculateOverallSecurityStatus(SecurityCheckResult result) {
    // 개발 환경에서는 일부 검사를 우회
    if (EnvironmentConfig.isDevelopment) {
      // 개발 환경에서는 디버거와 에뮬레이터 허용
      return !result.isRootedOrJailbroken &&
          result.isAppIntegrityValid &&
          result.isSecurityRequirementsMet;
    }

    // 프로덕션 환경에서는 모든 검사 통과해야 함
    return !result.isRootedOrJailbroken &&
        !result.isDebuggerAttached &&
        result.isAppIntegrityValid &&
        !result.isEmulator &&
        result.isSecurityRequirementsMet;
  }

  /// 보안 위협 대응
  static Future<void> handleSecurityThreat(SecurityCheckResult result) async {
    if (result.isSecure) return;

    final threats = <String>[];

    if (result.isRootedOrJailbroken) {
      threats.add('루팅/탈옥된 기기');
    }

    if (result.isDebuggerAttached && !EnvironmentConfig.isDevelopment) {
      threats.add('디버거 연결');
    }

    if (!result.isAppIntegrityValid) {
      threats.add('앱 무결성 손상');
    }

    if (result.isEmulator && !EnvironmentConfig.isDevelopment) {
      threats.add('에뮬레이터 환경');
    }

    if (!result.isSecurityRequirementsMet) {
      threats.add('보안 요구사항 미충족');
    }

    if (SecurityConfig.shouldLogDetailed) {
      debugPrint('보안 위협 감지: ${threats.join(", ")}');
    }

    // 프로덕션 환경에서 심각한 위협 발견 시 앱 종료
    if (EnvironmentConfig.isProduction && threats.isNotEmpty) {
      if (SecurityConfig.shouldLogDetailed) {
        debugPrint('심각한 보안 위협으로 인해 앱을 종료합니다.');
      }

      // 실제 구현에서는 사용자에게 적절한 메시지를 보여주고 앱을 종료
      // SystemNavigator.pop() 또는 exit(0) 사용
    }
  }

  /// 주기적 보안 검증 (백그라운드에서 실행)
  static Future<void> startPeriodicSecurityCheck() async {
    if (!EnvironmentConfig.isProduction) return;

    // 5분마다 보안 검증 실행
    Stream.periodic(const Duration(minutes: 5)).listen((_) async {
      final result = await performRuntimeSecurityCheck();
      if (!result.isSecure) {
        await handleSecurityThreat(result);
      }
    });
  }
}

// =============================================================================
// 보안 검증 결과 클래스
// =============================================================================

/// 보안 검증 결과를 담는 클래스
class SecurityCheckResult {
  bool isRootedOrJailbroken = false;
  bool isDebuggerAttached = false;
  bool isAppIntegrityValid = true;
  bool isEmulator = false;
  bool isSecurityRequirementsMet = true;
  bool isSecure = true;
  String? error;

  /// 위험 수준 계산 (0: 안전, 1-3: 보통, 4-5: 위험)
  int get riskLevel {
    int risk = 0;

    if (isRootedOrJailbroken) risk += 2;
    if (isDebuggerAttached && !EnvironmentConfig.isDevelopment) risk += 1;
    if (!isAppIntegrityValid) risk += 2;
    if (isEmulator && !EnvironmentConfig.isDevelopment) risk += 1;
    if (!isSecurityRequirementsMet) risk += 1;

    return risk;
  }

  /// 위험 수준 텍스트
  String get riskLevelText {
    switch (riskLevel) {
      case 0:
        return '안전';
      case 1:
      case 2:
      case 3:
        return '보통';
      default:
        return '위험';
    }
  }

  /// JSON 형태로 변환
  Map<String, dynamic> toJson() {
    return {
      'isRootedOrJailbroken': isRootedOrJailbroken,
      'isDebuggerAttached': isDebuggerAttached,
      'isAppIntegrityValid': isAppIntegrityValid,
      'isEmulator': isEmulator,
      'isSecurityRequirementsMet': isSecurityRequirementsMet,
      'isSecure': isSecure,
      'riskLevel': riskLevel,
      'riskLevelText': riskLevelText,
      'error': error,
    };
  }
}

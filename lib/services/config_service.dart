import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:review_ai/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:review_ai/core/utils/logger_service.dart';

/// 동적 설정 서비스 (AdMob ID, Clarity ID, Firebase 키 등)
class ConfigService {
  static const String _cacheKey = 'remote_config_cache';
  static const String _cacheTimeKey = 'remote_config_cache_time';
  static const Duration _cacheExpiry = Duration(hours: 24);

  static Map<String, dynamic>? _cachedConfig;
  static SharedPreferences? _prefs;

  // 기본 Clarity ID (서버에서 가져오기 전 폴백)
  static const String _defaultClarityId = 'sy9cat27ff';

  /// SharedPreferences 인스턴스 캐시
  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// AdMob 설정 가져오기
  static Future<Map<String, dynamic>> getAdMobConfig() async {
    try {
      // 캐시된 설정 확인
      if (_cachedConfig != null) {
        LoggerService.d('Using cached AdMob config');
        return _cachedConfig!;
      }

      // 로컬 캐시 확인
      final prefs = await _getPrefs();
      final cachedData = prefs.getString(_cacheKey);
      final cachedTime = prefs.getInt(_cacheTimeKey);

      if (cachedData != null && cachedTime != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTime;
        if (cacheAge < _cacheExpiry.inMilliseconds) {
          final decodedCache = jsonDecode(cachedData);
          // firebase 블록이 없다면 구버전 캐시이므로 무시하고 다시 가져옴
          if (decodedCache['firebase'] != null) {
            _cachedConfig = decodedCache;
            LoggerService.i('Loaded AdMob config from local cache');
            return _cachedConfig!;
          } else {
            LoggerService.w('Cache ignored: missing firebase config');
          }
        }
      }

      // 서버에서 새 설정 가져오기
      LoggerService.d('Fetching AdMob config from server');
      final response = await http
          .get(Uri.parse('${ApiConfig.proxyUrl}/api/config'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final config = jsonDecode(response.body);

        // 캐시 저장
        await prefs.setString(_cacheKey, response.body);
        await prefs.setInt(
          _cacheTimeKey,
          DateTime.now().millisecondsSinceEpoch,
        );

        _cachedConfig = config;
        LoggerService.d('AdMob config fetched and cached');
        return config;
      } else {
        throw Exception('Failed to fetch config: ${response.statusCode}');
      }
    } catch (e, stack) {
      LoggerService.e('ConfigService error: $e', e, stack);

      // 에러 발생 시 로컬 캐시 사용 (만료되었어도)
      try {
        final prefs = await _getPrefs();
        final cachedData = prefs.getString(_cacheKey);
        if (cachedData != null) {
          LoggerService.e('Using expired cache due to error');
          return jsonDecode(cachedData);
        }
      } catch (cacheError, cacheStack) {
        LoggerService.e(
          'ConfigService failback cache load error: $cacheError',
          cacheError,
          cacheStack,
        );
      }

      // 기본값 반환
      return {
        'adMob': {
          'ios': {'rewarded': '', 'banner': ''},
          'android': {'rewarded': '', 'banner': ''},
        },
      };
    }
  }

  /// AdMob Ad Unit ID 가져오기
  static Future<String> getAdUnitId({
    required String platform, // 'ios' 또는 'android'
    required String adType, // 'rewarded' 또는 'banner'
  }) async {
    try {
      final config = await getAdMobConfig();
      final adMobConfig = config['adMob'] as Map<String, dynamic>?;

      if (adMobConfig == null) {
        LoggerService.d('AdMob config not found');
        return '';
      }

      final platformKey = platform.toLowerCase();
      final platformConfig = adMobConfig[platformKey] as Map<String, dynamic>?;
      if (platformConfig == null) {
        LoggerService.d('Platform config not found for $platform');
        return '';
      }

      final adUnitId = platformConfig[adType] as String? ?? '';
      LoggerService.i(
        'AdMob $platform $adType ID: ${adUnitId.isEmpty ? "empty" : "loaded"}',
      );

      return adUnitId;
    } catch (e, stack) {
      LoggerService.e('Error getting AdMob ID: $e', e, stack);
      return '';
    }
  }

  /// 캐시 초기화 (앱 시작 시 백그라운드에서 실행)
  static Future<void> initialize() async {
    try {
      LoggerService.d('ConfigService initializing...');

      // 백그라운드에서 설정 가져오기
      unawaited(
        getAdMobConfig()
            .then((_) {
              LoggerService.i('ConfigService initialized');
            })
            .catchError((e, stack) {
              LoggerService.e(
                'ConfigService initialization failed: $e',
                e,
                stack,
              );
            }),
      );
    } catch (e, stack) {
      LoggerService.e('ConfigService initialization error: $e', e, stack);
    }
  }

  /// Clarity 프로젝트 ID 가져오기
  static Future<String> getClarityProjectId() async {
    try {
      final config = await getAdMobConfig();
      return (config['clarityProjectId'] as String?) ?? _defaultClarityId;
    } catch (e, stack) {
      LoggerService.e('Error getting Clarity ID: $e', e, stack);
      return _defaultClarityId;
    }
  }

  /// Firebase API Key 가져오기 (플랫폼별)
  static Future<String?> getFirebaseApiKey({required String platform}) async {
    try {
      final config = await getAdMobConfig();
      final firebaseConfig = config['firebase'] as Map<String, dynamic>?;
      if (firebaseConfig == null) return null;
      final key = platform.toLowerCase() == 'android'
          ? 'apiKeyAndroid'
          : 'apiKeyIos';
      return firebaseConfig[key] as String?;
    } catch (e, stack) {
      LoggerService.e('Error getting Firebase API key: $e', e, stack);
      return null;
    }
  }

  /// 캐시 클리어
  static Future<void> clearCache() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);
      _cachedConfig = null;
      LoggerService.d('ConfigService cache cleared');
    } catch (e, stack) {
      LoggerService.e('Error clearing config cache: $e', e, stack);
    }
  }
}

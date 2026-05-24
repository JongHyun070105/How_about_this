import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 앱의 데이터를 파일로 안전하게 저장하고 불러오는 서비스
class PersistentStorageService {
  // 캐시 사용 여부를 제어하는 플래그 (테스트 및 벤치마크 목적)
  static bool cacheEnabled = true;

  // 캐싱된 문서 디렉토리 경로
  static String? _cachedLocalPath;

  // 메모리 데이터 캐시 (파일명 -> JSON 데이터 맵)
  static final Map<String, Map<String, dynamic>> _memoryCache = {};

  Future<String> get _localPath async {
    if (cacheEnabled && _cachedLocalPath != null) {
      return _cachedLocalPath!;
    }
    final directory = await getApplicationDocumentsDirectory();
    if (cacheEnabled) {
      _cachedLocalPath = directory.path;
    }
    return directory.path;
  }

  Future<File> _getLocalFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  /// 파일에서 데이터를 읽어 Map 형태로 반환
  Future<Map<String, dynamic>> _readData(String fileName) async {
    if (cacheEnabled && _memoryCache.containsKey(fileName)) {
      return _memoryCache[fileName]!;
    }
    try {
      final file = await _getLocalFile(fileName);
      if (!await file.exists()) {
        if (cacheEnabled) {
          _memoryCache[fileName] = {};
        }
        return {}; // 파일이 없으면 빈 맵 반환
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) {
        if (cacheEnabled) {
          _memoryCache[fileName] = {};
        }
        return {};
      }
      final decoded = json.decode(contents) as Map<String, dynamic>;
      if (cacheEnabled) {
        _memoryCache[fileName] = decoded;
      }
      return decoded;
    } catch (e) {
      // 파일 읽기 실패 시 빈 맵 반환
      if (cacheEnabled) {
        _memoryCache[fileName] = {};
      }
      return {};
    }
  }

  /// 데이터를 Map 형태로 파일에 저장
  Future<void> _writeData(String fileName, Map<String, dynamic> data) async {
    if (cacheEnabled) {
      _memoryCache[fileName] = Map<String, dynamic>.from(data);
    }
    try {
      final file = await _getLocalFile(fileName);
      await file.writeAsString(json.encode(data));
    } catch (e) {
      // 파일 쓰기 실패. 에러 로그 등을 추가할 수 있음
    }
  }

  /// 특정 키에 해당하는 값을 파일에서 가져오기
  Future<T?> getValue<T>(String fileName, String key) async {
    final data = await _readData(fileName);
    if (data.containsKey(key)) {
      return data[key] as T?;
    }
    return null;
  }

  /// 특정 키와 값을 파일에 저장하기
  Future<void> setValue<T>(String fileName, String key, T value) async {
    final data = await _readData(fileName);
    data[key] = value;
    await _writeData(fileName, data);
  }

  /// 파일에서 특정 키를 삭제하기
  Future<void> removeValue(String fileName, String key) async {
    final data = await _readData(fileName);
    if (data.containsKey(key)) {
      data.remove(key);
      await _writeData(fileName, data);
    }
  }

  /// 파일 전체를 삭제하기
  Future<void> clearFile(String fileName) async {
    if (cacheEnabled) {
      _memoryCache.remove(fileName);
    }
    try {
      final file = await _getLocalFile(fileName);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // 파일 삭제 실패
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 앱의 데이터를 파일로 안전하게 저장하고 불러오는 서비스
class PersistentStorageService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getLocalFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  /// 파일에서 데이터를 읽어 Map 형태로 반환
  Future<Map<String, dynamic>> _readData(String fileName) async {
    try {
      final file = await _getLocalFile(fileName);
      if (!await file.exists()) {
        return {}; // 파일이 없으면 빈 맵 반환
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) {
        return {};
      }
      return json.decode(contents) as Map<String, dynamic>;
    } catch (e) {
      // 파일 읽기 실패 시 빈 맵 반환
      return {};
    }
  }

  /// 데이터를 Map 형태로 파일에 저장
  Future<void> _writeData(String fileName, Map<String, dynamic> data) async {
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

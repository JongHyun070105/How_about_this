import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:review_ai/core/utils/logger_service.dart';

/// 로컬 캐시(임시 폴더 및 네도워크 이미지 등)를 관리하는 서비스
class CacheService {
  static final CacheService _instance = CacheService._internal();

  factory CacheService() => _instance;

  CacheService._internal();

  /// 현재 앱에 누적된 전체 캐시 용량 계산 (바이트 단위)
  Future<int> calculateTotalCacheSize() async {
    int totalSize = 0;

    try {
      // 1. 임시 디렉토리 용량 (이미지 피커 등이 주로 사용하는 공간)
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        totalSize += await _calculateDirectorySize(tempDir);
      }

      // 2. CacheManager가 관리하는 캐시 디렉토리 확인 (필요에 따라)
      // 기본적으로 DefaultCacheManager는 임시 폴더 근처에 저장되므로 대부분 tempDir 에 포함되지만
      // 명시적으로 확인해 볼 수도 있습니다.
    } catch (e, stackTrace) {
      LoggerService.e('캐시 용량 계산 중 오류 발생', e, stackTrace);
    }

    return totalSize;
  }

  /// 전체 캐시 비우기
  Future<void> clearAllCache() async {
    try {
      // 1. flutter_cache_manager 캐시 비우기 (네트워크 이미지 등)
      await DefaultCacheManager().emptyCache();

      // 2. 임시 디렉토리 비우기 (카메라/갤러리 임시 이미지 등)
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final Stream<FileSystemEntity> children = tempDir.list(
          recursive: false,
        );
        await for (final FileSystemEntity child in children) {
          try {
            await child.delete(recursive: true);
          } catch (e) {
            // 안지워지는 캐시 파일은 무시
            LoggerService.w('파일 삭제 실패: ${child.path}', e);
          }
        }
      }

      LoggerService.i('모든 앱 캐시가 삭제되었습니다.');
    } catch (e, stackTrace) {
      LoggerService.e('캐시 삭제 중 오류 발생', e, stackTrace);
    }
  }

  /// 특정 폴더의 내부 용량 재귀적 합산
  Future<int> _calculateDirectorySize(Directory dir) async {
    int size = 0;
    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            try {
              size += await entity.length();
            } catch (_) {
              // 개별 파일 크기를 읽지 못한 경우 무시
            }
          }
        }
      }
    } catch (e) {
      LoggerService.d('디렉토리 용량 계산 중 오류 (무시됨): $e');
    }
    return size;
  }

  /// 바이트를 MB 단위 문자열로 변환하는 유틸리티
  String formatBytesToMB(int bytes) {
    if (bytes <= 0) return '0 MB';
    final double mb = bytes / (1024 * 1024);
    if (mb < 0.1) return '< 0.1 MB'; // 너무 작으면
    return '${mb.toStringAsFixed(1)} MB';
  }
}

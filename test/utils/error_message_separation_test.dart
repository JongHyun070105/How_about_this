import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:review_ai/config/security_config.dart';
import 'package:review_ai/core/exceptions.dart';
import 'package:review_ai/services/kakao_api_service.dart';
import 'package:review_ai/utils/error_handler.dart';

/// 에러 메시지의 사용자/개발자 분리가 올바르게 동작하는지 검증하는 테스트
void main() {
  // ===================================================================
  // 1. ErrorHandler.sanitizeMessage — 사용자에게 보이는 메시지 친화성 검증
  // ===================================================================
  group('ErrorHandler.sanitizeMessage (사용자 메시지)', () {
    test('SocketException → 사용자 친화적 메시지 반환', () {
      final error = const SocketException('Connection refused');
      final message = ErrorHandler.sanitizeMessage(error);

      expect(message, '인터넷 연결을 확인해주세요.');
      // 기술적 내용이 포함되지 않아야 함
      expect(message, isNot(contains('SocketException')));
      expect(message, isNot(contains('Connection refused')));
    });

    test('DioException connectionTimeout → 타임아웃 안내 메시지', () {
      final error = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );
      final message = ErrorHandler.sanitizeMessage(error);

      expect(message, contains('시간이 초과'));
      expect(message, isNot(contains('/test')));
      expect(message, isNot(contains('DioException')));
    });

    test('DioException sendTimeout → 타임아웃 안내 메시지', () {
      final error = DioException(
        type: DioExceptionType.sendTimeout,
        requestOptions: RequestOptions(path: '/api/send'),
      );
      final message = ErrorHandler.sanitizeMessage(error);

      expect(message, contains('시간이 초과'));
      expect(message, isNot(contains('/api/send')));
    });

    test('DioException receiveTimeout → 타임아웃 안내 메시지', () {
      final error = DioException(
        type: DioExceptionType.receiveTimeout,
        requestOptions: RequestOptions(path: '/api/receive'),
      );
      final message = ErrorHandler.sanitizeMessage(error);

      expect(message, contains('시간이 초과'));
    });

    test('DioException connectionError → 연결 안내 메시지', () {
      final error = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/connect'),
      );
      final message = ErrorHandler.sanitizeMessage(error);

      expect(message, contains('연결'));
      expect(message, isNot(contains('/connect')));
    });

    test('DioException badResponse 401 → 인증 실패 메시지', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/secret'),
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/secret'),
        ),
      );
      final message = ErrorHandler.sanitizeMessage(error);

      expect(message, contains('인증'));
      expect(message, isNot(contains('/secret')));
      expect(message, isNot(contains('401')));
    });

    test('DioException badResponse 403 → 권한 없음 메시지', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/admin'),
        response: Response(
          statusCode: 403,
          requestOptions: RequestOptions(path: '/admin'),
        ),
      );
      final message = ErrorHandler.sanitizeMessage(error);

      expect(message, contains('권한'));
      expect(message, isNot(contains('/admin')));
    });

    test('DioException badResponse 429 → 요청 과다 메시지', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/api'),
        response: Response(
          statusCode: 429,
          requestOptions: RequestOptions(path: '/api'),
        ),
      );
      final message = ErrorHandler.sanitizeMessage(error);

      expect(message, contains('요청이 너무 많습니다'));
    });

    test('DioException badResponse 500 → 서버 문제 메시지', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/api/internal'),
        response: Response(
          statusCode: 500,
          requestOptions: RequestOptions(path: '/api/internal'),
        ),
      );
      final message = ErrorHandler.sanitizeMessage(error);

      expect(message, contains('서버'));
      expect(message, isNot(contains('500')));
      expect(message, isNot(contains('/api/internal')));
    });

    test('DioException cancel → 취소 메시지', () {
      final error = DioException(
        type: DioExceptionType.cancel,
        requestOptions: RequestOptions(path: '/cancel'),
      );
      final message = ErrorHandler.sanitizeMessage(error);

      expect(message, contains('취소'));
    });

    test('KakaoApiException → 해당 예외 메시지 그대로 전달', () {
      final error = KakaoApiException('카카오 API 오류가 발생했습니다.');
      final message = ErrorHandler.sanitizeMessage(error);

      expect(message, '카카오 API 오류가 발생했습니다.');
    });

    test('알 수 없는 에러 → 일반 안내 메시지', () {
      final error = Exception('Unknown internal error xyz-123');
      final message = ErrorHandler.sanitizeMessage(error);

      expect(message, contains('알 수 없는 오류'));
      // 내부 에러 메시지가 노출되지 않아야 함
      expect(message, isNot(contains('xyz-123')));
      expect(message, isNot(contains('Unknown internal error')));
    });

    test('일반 String 에러 → 내부 정보 노출 없음', () {
      final error = 'Stack trace at line 42 in /home/user/app/main.dart';
      final message = ErrorHandler.sanitizeMessage(error);

      expect(message, contains('알 수 없는 오류'));
      expect(message, isNot(contains('Stack trace')));
      expect(message, isNot(contains('/home/user')));
    });
  });

  // ===================================================================
  // 2. SecurityConfig.sanitizeErrorMessage — 개발자 로그 민감 정보 마스킹
  // ===================================================================
  group('SecurityConfig.sanitizeErrorMessage (개발자 로그 마스킹)', () {
    test('API 키가 포함된 에러 메시지 → API_KEY_HIDDEN으로 마스킹', () {
      final error =
          'Error: Invalid API key AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz123456';
      final sanitized = SecurityConfig.sanitizeErrorMessage(error);

      expect(sanitized, contains('API_KEY_HIDDEN'));
      expect(sanitized, isNot(contains('AIzaSy')));
    });

    test('토큰이 포함된 에러 메시지 → TOKEN_HIDDEN으로 마스킹', () {
      // 패턴: token.*[A-Za-z0-9]{20,}
      final error =
          'Authorization failed: token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9payload';
      final sanitized = SecurityConfig.sanitizeErrorMessage(error);

      expect(sanitized, contains('TOKEN_HIDDEN'));
      expect(sanitized, isNot(contains('eyJhbGci')));
    });

    test('파일 경로가 포함된 에러 메시지 → PATH_HIDDEN으로 마스킹', () {
      // 패턴: path.*\/.*\/
      final error = 'File not found: path=/Users/developer/';
      final sanitized = SecurityConfig.sanitizeErrorMessage(error);

      expect(sanitized, contains('PATH_HIDDEN'));
      expect(sanitized, isNot(contains('/Users/developer')));
    });

    test('민감 정보가 없는 일반 에러 메시지 → 변경 없음', () {
      final error = '일반적인 에러 메시지입니다.';
      final sanitized = SecurityConfig.sanitizeErrorMessage(error);

      expect(sanitized, error);
    });

    test('여러 민감 정보가 동시에 포함된 경우 모두 마스킹', () {
      // API key 패턴 + token 패턴 동시 포함
      final error =
          'API key=AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz123456, '
          'token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9datasig';
      final sanitized = SecurityConfig.sanitizeErrorMessage(error);

      expect(sanitized, isNot(contains('AIzaSy')));
      expect(sanitized, isNot(contains('eyJhbGci')));
    });
  });

  // ===================================================================
  // 3. Exception 클래스 toString() — 개발자 전용 상세 정보 포함 검증
  // ===================================================================
  group('Exception toString() (개발자 상세 정보)', () {
    test('ApiException → 클래스명, 메시지, 상태 코드 포함', () {
      final exception = ApiException('서버 오류 발생', statusCode: 500);
      final str = exception.toString();

      expect(str, contains('ApiException'));
      expect(str, contains('서버 오류 발생'));
      expect(str, contains('500'));
    });

    test('ApiException statusCode null → N/A 표시', () {
      final exception = ApiException('알 수 없는 오류');
      final str = exception.toString();

      expect(str, contains('N/A'));
    });

    test('NetworkException → 네트워크 오류 접두사 포함', () {
      final exception = NetworkException('서버 연결 불가');
      final str = exception.toString();

      expect(str, contains('네트워크 오류'));
      expect(str, contains('서버 연결 불가'));
    });

    test('GeminiApiException → Gemini API 오류 접두사 + 상태 코드', () {
      final exception = GeminiApiException('응답 없음', statusCode: 503);
      final str = exception.toString();

      expect(str, contains('Gemini API 오류'));
      expect(str, contains('503'));
    });

    test('ParsingException → 파싱 오류 접두사 포함', () {
      final exception = ParsingException('JSON 형식 오류');
      final str = exception.toString();

      expect(str, contains('데이터 파싱 오류'));
      expect(str, contains('JSON 형식 오류'));
    });

    test('ImageValidationException → 메시지만 포함 (접두사 없음)', () {
      final exception = ImageValidationException('이미지 크기가 너무 큽니다.');
      final str = exception.toString();

      expect(str, contains('이미지 크기가 너무 큽니다'));
    });
  });

  // ===================================================================
  // 4. 사용자 메시지에 기술적 정보가 절대 노출되지 않는지 검증
  // ===================================================================
  group('사용자 메시지 기술적 정보 비노출 검증', () {
    final technicalTerms = [
      'Exception',
      'SocketException',
      'DioException',
      'stack trace',
      'null',
      'NullPointerException',
      'dart:',
      'package:',
      '.dart',
      'line ',
      'column ',
    ];

    test('SocketException 에러에서 기술 용어 비노출', () {
      final error = const SocketException('Failed host lookup');
      final message = ErrorHandler.sanitizeMessage(error);

      for (final term in technicalTerms) {
        expect(
          message.toLowerCase(),
          isNot(contains(term.toLowerCase())),
          reason: '사용자 메시지에 "$term"이 노출됨',
        );
      }
    });

    test('알 수 없는 에러에서 기술 용어 비노출', () {
      final error = FormatException('Unexpected character at line 1, column 5');
      final message = ErrorHandler.sanitizeMessage(error);

      for (final term in technicalTerms) {
        expect(
          message.toLowerCase(),
          isNot(contains(term.toLowerCase())),
          reason: '사용자 메시지에 "$term"이 노출됨',
        );
      }
    });

    test('DioException 500 에러에서 URL 경로 비노출', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(
          path: '/api/v1/gemini/generateContent',
          baseUrl: 'https://proxy.workers.dev',
        ),
        response: Response(
          statusCode: 500,
          data: {'error': 'Internal Server Error'},
          requestOptions: RequestOptions(
            path: '/api/v1/gemini/generateContent',
          ),
        ),
      );
      final message = ErrorHandler.sanitizeMessage(error);

      expect(message, isNot(contains('generateContent')));
      expect(message, isNot(contains('proxy.workers.dev')));
      expect(message, isNot(contains('/api/')));
      expect(message, isNot(contains('500')));
      expect(message, contains('서버'));
    });
  });
}

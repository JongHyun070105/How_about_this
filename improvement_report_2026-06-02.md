# ReviewAI Flutter 반복 개선 전 분석 및 검증 기록

- 작성 시각: 2026-06-02 21:38:09 KST
- 대상 브랜치: `develop`
- 대상 저장소: `reviewai_flutter` (`JongHyun070105/How_about_this`)
- 기준 HEAD: `028074a8b4ac183b580919f3cfb002ce6e0a140b`

## 1. 프로젝트 분석

### Graphify 기준 구조

작업 시작 전 `graphify-out/GRAPH_REPORT.md`를 먼저 확인했다. 기존 그래프는 `00dd7893` 기준이라 현재 HEAD와 1커밋 차이가 있어 `graphify update .`로 갱신했다.

변경 후에도 다시 `graphify update .`를 실행했다.

- 파일: 1,299개
- 변경 후 그래프: 5,732 nodes / 5,710 edges / 1,158 communities
- 리포트: `graphify-out/GRAPH_REPORT.md`
- 비고: `graph.html`은 노드 수가 5,000개 제한을 넘어 생략됐지만 `graph.json`과 `GRAPH_REPORT.md`는 정상 갱신됐다.

앱 레이어에서 이번 반복 개선 후보로 확인한 영역:

- `lib/services/config_service.dart`
- `test/services/config_service_test.dart`

### 개선 후보 선정 근거

이전 정리 파일(`improvement_report_2026-06-01.md`)의 다음 반복 후보 중 1번은 다음 문제였다.

> `ConfigService` 테스트에서 의도된 400 fallback 경로가 error 로그로 출력되는 부분 정리

이번 기준 테스트에서도 같은 현상을 재확인했다.

## 2. Baseline 검증

명령:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test test/services/config_service_test.dart --reporter expanded
```

결과:

- `flutter pub get`: 성공
- `dart format --output=none --set-exit-if-changed .`: `Formatted 155 files (0 changed)`
- `flutter analyze`: `No issues found!`
- `flutter test`: `+156: All tests passed!`
- focused `config_service_test`: `+4: All tests passed!`
- baseline focused 로그 노이즈:
  - `ConfigService error`: 4회
  - `Failed to fetch config`: 8회

해석:

- 기능 테스트는 통과하지만, 서버 설정 조회 실패가 앱 기본값 fallback으로 정상 복구되는 케이스임에도 error 로그와 스택트레이스가 출력됐다.
- 반복 개선 루프에서 실제 장애와 의도된 fallback을 구분하기 어렵게 만든다.
- 프로덕션에서는 `LoggerService.e`가 Crashlytics 기록으로 이어질 수 있어 fallback 가능한 상태 실패를 error로 분류하는 것은 과하다.

## 3. RED 테스트

추가한 회귀 테스트:

- 파일: `test/services/config_service_test.dart`
- 테스트명: `서버 설정 조회 실패 fallback은 error 로그로 분류하지 않음`
- 검증 내용:
  - `ConfigService.getAdMobConfig()` fallback 실행 중 출력 로그를 `runZoned`로 수집한다.
  - 로그에 `ConfigService error`가 없어야 한다.
  - 로그에 `Failed to fetch config`가 없어야 한다.

RED 결과:

```bash
flutter test test/services/config_service_test.dart --reporter expanded
```

- exit code: 1
- 결과: `Some tests failed.`
- `ConfigService error`: 6회
- `Failed to fetch config`: 10회

즉, 기존 코드가 실제로 새 요구사항을 만족하지 못함을 확인했다.

## 4. 적용한 개선

### 변경 파일

- `lib/services/config_service.dart`
- `test/services/config_service_test.dart`

### 변경 내용

1. `ConfigService.getAdMobConfig()`에서 HTTP 200이 아닌 서버 상태 응답을 즉시 예외로 던지지 않도록 변경했다.
2. 서버가 `/api/config`를 거부하거나 아직 제공하지 않는 경우를 앱 기본값/만료 캐시로 복구 가능한 fallback 경로로 분류했다.
3. 해당 fallback은 `LoggerService.e`가 아니라 `LoggerService.w` + `LoggerService.i`로 기록한다.
4. 만료 캐시 또는 기본값 반환 로직을 `_fallbackConfig()` / `_defaultConfig()`로 분리했다.
5. 기존 `failback` 오타를 `fallback`으로 정리했다.
6. fallback 로그 회귀 테스트를 추가했다.

## 5. 개선 효과 검증

### Focused 검증

명령:

```bash
dart format lib/services/config_service.dart test/services/config_service_test.dart
flutter test test/services/config_service_test.dart --reporter expanded
```

결과:

- `dart format`: `Formatted 2 files (0 changed)`
- focused `config_service_test`: `+5: All tests passed!`
- `ConfigService error`: 0회
- `Failed to fetch config`: 0회
- `ConfigService fallback: server returned`: 4회

Before/After:

| 항목 | Before | After |
|---|---:|---:|
| focused 테스트 수 | 4 | 5 |
| focused 테스트 결과 | pass | pass |
| `ConfigService error` 로그 | 4회 | 0회 |
| `Failed to fetch config` 로그 | 8회 | 0회 |
| fallback 상태 로그 | 0회 | 4회 |

### 전체 검증

명령:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test --coverage
```

결과:

- `dart format --output=none --set-exit-if-changed .`: `Formatted 155 files (0 changed)`
- `flutter analyze`: `No issues found! (ran in 7.2s)`
- `flutter test`: `+157: All tests passed!`
- `flutter test --coverage`: `+157: All tests passed!`
- `coverage/lcov.info`: 생성 확인, 2,042 lines
- 전체 테스트 로그의 `ConfigService error`: 0회
- 전체 테스트 로그의 `Failed to fetch config`: 0회

## 6. 보안/리스크 검토

- 변경 Dart 파일 대상 secret-like pattern scan 결과: 0건
- 새 하드코딩 API key/token/password/private key 없음
- shell/eval/exec/deserialization/SQL 관련 변경 없음
- 기능 의미 유지:
  - 성공 응답은 기존처럼 캐시 저장 후 반환
  - 서버 상태 실패는 기본값/만료 캐시 fallback 반환
  - 네트워크/파싱 예외는 기존처럼 error로 남기되 fallback 반환 시도
- 리스크:
  - 서버가 HTTP 500을 반환해도 현재는 fallback 가능한 상태 실패로 warning 처리된다. 설정 조회는 앱 기본값으로 복구 가능하므로 이번 개선 범위에서는 의도한 정책이다.

## 7. 결론

실제 개선 확인 완료.

- 테스트 성공 상태 유지: format / analyze / test / coverage 모두 통과
- 회귀 테스트 1개 추가: 전체 테스트 156개 → 157개
- 의도된 ConfigService fallback에서 error 로그 제거: 4회 → 0회
- `Failed to fetch config` 스택 로그 제거: 8회 → 0회
- 반복 개선 전 테스트 로그 판독성과 장애 신호 신뢰도 개선

## 8. 다음 반복 개선 후보

1. `ApiProxyService` 테스트에서 의도된 500 에러 케이스가 error 로그로 출력되는 부분 정리
2. Graphify 대상에서 `ios/Pods` 제외 여부 검토로 그래프 노이즈 축소
3. `ConfigService` 테스트가 실제 원격 Workers 응답에 의존하는 구조를 mockable HTTP client 구조로 분리

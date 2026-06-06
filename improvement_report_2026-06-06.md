# ReviewAI Flutter 반복 개선 전 분석 및 검증 기록

- 작성 시각: 2026-06-06 21:50 KST
- 대상 브랜치: `develop`
- 대상 저장소: `reviewai_flutter` (`JongHyun070105/How_about_this`, GitHub moved notice: `JongHyun070105/how-about-this`)
- 기준 HEAD: `7f68ff449b472d6746e948037b2db40067ba5d95`

## 1. 프로젝트 분석

### Graphify 기준 구조

작업 시작 전 프로젝트 규칙에 따라 `graphify-out/GRAPH_REPORT.md`를 먼저 확인했다.

- `graphify-out/wiki/index.md`: 없음
- 시작 graphify freshness: built from commit `7f68ff44`
- 현재 HEAD: `7f68ff449b472d6746e948037b2db40067ba5d95`
- graphify corpus:
  - `1303 files`
  - `5818 nodes / 5792 edges / 1151 communities`
  - extraction: `97% EXTRACTED / 3% INFERRED`

Dart parser 쪽은 `graphify explain GeminiResponseParser`로 확인했다.

- 중심 노드: `GeminiResponseParser`
- 파일: `lib/utils/gemini_response_parser.dart`
- 테스트: `test/utils/gemini_response_parser_test.dart`

### 개선 후보 선정 근거

이번 반복 개선 대상은 Gemini/LLM 추천 JSON 응답의 `trailing comma` 허용 처리다.

기존 파서는 다음 변형을 이미 처리했다.

- 마크다운 fenced JSON
- JSON 앞뒤 설명 문장 포함 응답
- `recommendations` / `items` / `foods` / `results` wrapper 객체

하지만 LLM이 흔히 내는 아래 같은 비표준 JSON은 실패했다.

```json
[
  {"name": "참치,김밥", "imageUrl": "",},
]
```

선정 이유:

- `GeminiResponseParser`는 추천 응답 파싱의 중앙 유틸리티다.
- trailing comma는 LLM 출력에서 흔한 실패 원인이다.
- 기존 테스트 파일이 있어 RED/GREEN으로 개선을 증명할 수 있다.
- UI/네트워크/권한 변경 없이 파싱 안정성만 개선한다.

## 2. Baseline 검증

명령:

```bash
flutter analyze
flutter test
```

결과:

- `flutter analyze`: `No issues found! (ran in 4.1s)`
- `flutter test`: `+163: All tests passed!`

해석:

- 변경 전 전체 suite는 통과 상태였다.
- 단, 객체/배열 trailing comma가 포함된 Gemini 응답은 테스트되지 않았다.

## 3. RED 테스트

추가한 회귀 테스트:

- 파일: `test/utils/gemini_response_parser_test.dart`
- 테스트명: `객체와 배열의 trailing comma가 있어도 추천 응답을 파싱한다`

RED 명령:

```bash
flutter test test/utils/gemini_response_parser_test.dart --reporter expanded
```

RED 결과:

- exit code: `1`
- 결과: `+20 -1: Some tests failed.`
- 실패 증거:
  - `FormatException: Unexpected character (at line 2, character 36)`
  - `JSON 파싱 실패: FormatException: Unexpected character`

즉, 기존 코드가 trailing comma 포함 추천 JSON을 실제로 처리하지 못함을 확인했다.

## 4. 적용한 개선

### 변경 파일

- `lib/utils/gemini_response_parser.dart`
- `test/utils/gemini_response_parser_test.dart`

### 변경 내용

1. `_removeTrailingCommas(String value)` helper를 추가했다.
2. `cleanMarkdownJson(jsonString)` 이후, `jsonDecode()` 전에 trailing comma를 정규화한다.
3. 문자열 내부의 쉼표는 보존한다.
   - 테스트 입력의 `"참치,김밥"`이 그대로 유지됨을 검증했다.
4. `]` 또는 `}` 앞에 있는 쉼표만 제거한다.

핵심 효과:

- Before: `[{"name":"참치,김밥","imageUrl":"",},]` → `FormatException`
- After: `[{"name":"참치,김밥","imageUrl":""}]`로 정규화 후 `FoodRecommendation` 생성

## 5. 개선 효과 검증

### Focused 검증

명령:

```bash
dart format lib/utils/gemini_response_parser.dart test/utils/gemini_response_parser_test.dart
flutter test test/utils/gemini_response_parser_test.dart --reporter expanded
```

결과:

- `dart format`: `Formatted 2 files (0 changed)`
- focused `gemini_response_parser_test`: `+21: All tests passed!`

Before/After:

| 항목 | Before | After |
|---|---:|---:|
| 전체 테스트 수 | 163 | 164 |
| focused parser 테스트 결과 | `+20 -1` 실패 | `+21` 통과 |
| trailing comma JSON 처리 | 실패 | 성공 |
| 문자열 내부 쉼표 보존 | 미검증 | `참치,김밥` 보존 검증 |
| 기존 배열/마크다운/설명문/wrapper 케이스 | 통과 | 통과 유지 |

### 전체 검증

명령:

```bash
flutter analyze
flutter test
graphify update .
```

결과:

- `flutter analyze`: `No issues found! (ran in 3.0s)`
- `flutter test`: `+164: All tests passed!`
- `graphify update .`:
  - `AST extraction: 1303/1303 files (100%)`
  - `Rebuilt: 5819 nodes / 5793 edges / 1157 communities`

비고:

- `graph.html`은 노드 수가 5,000개 제한을 넘어 생략됐다.
- `graph.json`과 `GRAPH_REPORT.md`는 정상 갱신됐다.

## 6. 보안/리스크 검토

- 새 API key/token/password/private key 없음
- 네트워크 호출/권한/스토리지 접근 변경 없음
- 입력 JSON 문자열 정규화만 추가
- 기존 정상 케이스 유지
- 리스크:
  - 표준 JSON parser 자체를 교체하지 않고 trailing comma만 좁게 허용했다.
  - 문자열 내부 쉼표를 제거하지 않도록 상태 기반 scanner를 사용했다.
  - JSON 구조 자체가 깨졌거나 배열/wrapper 후보가 없으면 기존 예외 흐름으로 실패한다.

## 7. 결론

실제 개선 확인 완료.

- 반복 개선 전 graphify 기반 프로젝트 분석 완료
- baseline `flutter analyze` / `flutter test` 통과 상태 기록
- RED 테스트로 기존 trailing comma 실패 재현
- 최소 구현 후 focused 테스트 GREEN 확인
- 전체 `flutter analyze` / `flutter test` 통과 확인
- graphify update 완료

## 8. 다음 반복 개선 후보

1. `ApiProxyService` 테스트에서 의도된 500 에러 케이스가 error 로그로 출력되는 부분 정리
2. Graphify 대상에서 `ios/Pods` 제외 여부 검토로 그래프 노이즈 축소
3. Gemini wrapper 후보 키 정책을 API contract 문서나 prompt schema에 명시

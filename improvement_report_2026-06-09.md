# ReviewAI Flutter 반복 개선 전 분석 및 검증 기록

- 작성 시각: 2026-06-09 15:27 KST
- 대상 브랜치: `develop`
- 대상 저장소: `reviewai_flutter`
- 작업 시작 HEAD: `d7ee84b96aaef6e2824115a7b1867e5c42b918cf`

## 1. 프로젝트 분석

### Graphify 기준 구조

작업 시작 전 `graphify-out/GRAPH_REPORT.md`를 먼저 확인했다.

- graph report 최신본 기준: `2026-06-09`
- corpus: `1308 files`
- summary: `5875 nodes / 5862 edges / 1173 communities`
- graph freshness 기준 commit: `d7ee84b9`

### 개선 후보 선정 근거

이번 반복 개선 대상은 `GeminiResponseParser.cleanMarkdownJson()`의 다중 JSON 후보 선택 안정성이다.

Graphify와 source inspection 기준으로 중앙 경로는 다음과 같았다.

- `lib/utils/gemini_response_parser.dart`
- `lib/services/api_proxy_service.dart`
- `lib/services/recommendation_service.dart`
- `test/utils/gemini_response_parser_test.dart`

기존 구현은 다음 케이스를 이미 처리한다.

- plain JSON array
- fenced JSON code block
- 설명 문장이 앞뒤에 붙은 단일 JSON payload
- wrapper 객체(`recommendations`, `items`, `foods`, `results`, `reviews`)

하지만 LLM 응답이 아래처럼 여러 JSON 조각을 함께 내는 경우는 첫 후보만 잡아 실패할 수 있었다.

- 앞쪽의 예시/설명용 JSON 객체
- 뒤쪽의 실제 추천 JSON 배열

선정 이유:

- `cleanMarkdownJson()`는 `parseRecommendations()`와 `ApiProxyService.generateReviews()` 양쪽에 영향을 준다.
- 여러 JSON 조각이 섞인 응답은 실제 LLM 출력에서 충분히 나올 수 있다.
- parser 테스트로 RED/GREEN을 명확히 증명할 수 있다.
- 네트워크/API 계약은 건드리지 않고 로컬 파싱만 개선할 수 있다.

## 2. Baseline 검증

명령:

```bash
flutter analyze
flutter test
```

결과:

- `flutter analyze`: `No issues found! (ran in 4.4s)`
- `flutter test`: `+172: All tests passed!`

해석:

- 변경 전 전체 suite는 통과 상태였다.
- 다만 다중 JSON 후보를 고르는 케이스는 아직 검증되지 않았다.

## 3. RED 테스트

추가한 회귀 테스트:

- 파일: `test/utils/gemini_response_parser_test.dart`
- 테스트명: `설명용 JSON 객체보다 실제 JSON 배열을 우선 파싱한다`

RED 명령:

```bash
flutter test test/utils/gemini_response_parser_test.dart --plain-name "설명용 JSON 객체보다 실제 JSON 배열을 우선 파싱한다"
```

RED 결과:

- exit code: `1`
- 실패 메시지: `Exception: 추천 데이터를 분석하는 중 문제가 발생했습니다. 다시 시도해 주세요.`
- 원인 요약:
  - `cleanMarkdownJson()`가 앞쪽의 예시 객체 `{"example": "ignore me"}`를 먼저 선택함
  - 실제 배열 `[{"name": "비빔밥", ...}]`까지 도달하지 못함
  - `FormatException: 추천 JSON 배열을 찾을 수 없습니다.` 발생

즉, 기존 코드가 여러 JSON 후보 중 실제 payload를 우선 선택하지 못함을 확인했다.

## 4. 적용한 개선

### 변경 파일

- `lib/utils/gemini_response_parser.dart`
- `test/utils/gemini_response_parser_test.dart`

### 변경 내용

1. `_extractJsonPayload()`가 첫 JSON 후보만 즉시 반환하지 않도록 바꿨다.
2. top-level JSON 후보를 순회하면서 다음 우선순위로 선택한다.
   - JSON 배열(`List`)
   - wrapper 객체(`recommendations`, `items`, `foods`, `results`, `reviews`)
3. 우선 후보가 없으면 첫 번째로 파싱 가능한 payload를 fallback으로 반환한다.
4. 회귀 테스트를 추가해 예시용 JSON 객체가 앞에 있어도 실제 배열을 파싱하는지 검증했다.

핵심 효과:

- Before: 설명용 객체가 먼저 나오면 실제 배열을 놓침
- After: 실제 배열 또는 허용 wrapper 객체를 우선 선택

## 5. 개선 효과 검증

### Focused 검증

명령:

```bash
flutter test test/utils/gemini_response_parser_test.dart --plain-name "설명용 JSON 객체보다 실제 JSON 배열을 우선 파싱한다"
```

결과:

- `+1: All tests passed!`

### 최종 전체 검증

명령:

```bash
flutter analyze
flutter test
graphify update .
```

결과:

- `flutter analyze`: `No issues found! (ran in 4.3s)`
- `flutter test`: `+173: All tests passed!`
- `graphify update .`:
  - `AST extraction: 1308/1308 files (100%)`
  - `Rebuilt: 5875 nodes / 5862 edges / 1173 communities`
  - `graphify-out/GRAPH_REPORT.md` 갱신 완료

Before/After:

| 항목 | Before | After |
|---|---:|---:|
| 전체 테스트 수 | 172 | 173 |
| focused parser 테스트 결과 | 실패 | 통과 |
| 다중 JSON 후보 처리 | 실패 | 성공 |
| 전체 analyze | 통과 | 통과 유지 |
| 전체 test | 통과 | 통과 유지 |

## 6. 보안/리스크 검토

- 새 API key/token/password/private key 없음
- 네트워크/권한/스토리지 범위 변경 없음
- 기존 plain array / wrapper object 경로 유지
- 허용 wrapper key를 좁게 제한해 과도한 느슨함을 피함
- fallback은 첫 valid payload로 제한해 완전한 무작위 선택을 피함

## 7. 결론

실제 개선 확인 완료.

- graphify 기반 프로젝트 분석 완료
- baseline `flutter analyze` / `flutter test` 통과 상태 기록
- RED 테스트로 다중 JSON 후보 실패 재현
- 최소 구현 후 focused 테스트 GREEN 확인
- 전체 `flutter analyze` / `flutter test` 통과 확인
- `graphify update .` 완료

## 8. 다음 반복 개선 후보

1. `GeminiResponseParser.extractText()`가 multi-part / multi-candidate 응답을 더 잘 고르도록 개선
2. `ApiProxyService`의 리뷰/추천 파싱 오류 메시지를 더 세분화해 진단 품질 개선
3. `GeminiResponseParser`와 `ApiProxyService`의 wrapper key 정책 공통화

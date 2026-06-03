# ReviewAI Flutter 반복 개선 전 분석 및 검증 기록

- 작성 시각: 2026-06-03 21:00:26 KST
- 대상 브랜치: `develop`
- 대상 저장소: `reviewai_flutter` (`JongHyun070105/How_about_this`)
- 기준 HEAD: `a695922`

## 1. 프로젝트 분석

### Graphify 기준 구조

작업 시작 전 `graphify-out/GRAPH_REPORT.md`를 먼저 확인했다. 기존 graphify wiki 경로(`graphify-out/wiki/index.md`)는 없어서 `GRAPH_REPORT.md`와 graphify query를 기준으로 구조를 파악했다.

앱 레이어에서 반복 개선 후보로 확인한 주요 영역:

- `lib/services/recommendation_service.dart`
- `lib/services/food_stats_service.dart`
- `lib/services/prompt_builder.dart`
- `lib/utils/gemini_response_parser.dart`
- `test/utils/gemini_response_parser_test.dart`

변경 후 `graphify update .`를 실행했다.

- AST extraction: 1,300 / 1,300 files
- 변경 후 그래프: 5,752 nodes / 5,729 edges / 1,162 communities
- 리포트: `graphify-out/GRAPH_REPORT.md`
- 비고: `graph.html`은 노드 수가 5,000개 제한을 넘어 생략됐지만 `graph.json`과 `GRAPH_REPORT.md`는 정상 갱신됐다.

### 개선 후보 선정 근거

이번 반복 개선 대상은 `GeminiResponseParser.cleanMarkdownJson()`의 Gemini 응답 코드블록 처리다.

기존 구현은 다음 케이스에 취약했다.

- ` ```json `처럼 소문자 `json`만 사실상 정상 처리
- ` ```JSON `처럼 대문자 언어 태그가 붙으면 `JSON` 문자열이 JSON 본문 앞에 남음
- ` ``` json `처럼 fence와 언어 태그 사이 공백이 있으면 `json` 문자열이 JSON 본문 앞에 남음

Gemini/LLM 응답은 마크다운 코드블록 언어 태그의 대소문자와 공백이 흔히 달라질 수 있으므로, 이 실패는 실제 추천 파싱 실패로 이어질 수 있다.

## 2. Baseline 검증

명령:

```bash
flutter analyze
flutter test
```

결과:

- `flutter analyze`: `No issues found!`
- `flutter test`: `+157: All tests passed!`

해석:

- 현재 전체 테스트는 통과 상태였다.
- 단, 기존 테스트는 대문자/공백 포함 마크다운 fence 변형을 검증하지 않아 파서 취약점이 드러나지 않았다.

## 3. RED 테스트

추가한 회귀 테스트:

- 파일: `test/utils/gemini_response_parser_test.dart`
- 테스트명:
  - `대문자 JSON 언어 태그 코드 블록을 제거한다`
  - `공백이 포함된 json 언어 태그 코드 블록을 제거한다`
  - `대문자 JSON 코드 블록으로 감싼 응답을 파싱한다`

RED 명령:

```bash
flutter test test/utils/gemini_response_parser_test.dart
```

RED 결과:

- exit code: 1
- 실패 테스트: 2개
- 실패 내용:
  - expected: `[{"name": "초밥"}]`
  - actual: `JSON\n[{"name": "초밥"}]`
  - expected: `[{"name": "쌀국수"}]`
  - actual: `json\n[{"name": "쌀국수"}]`

즉, 기존 코드가 실제로 새 요구사항을 만족하지 못함을 확인했다.

## 4. 적용한 개선

### 변경 파일

- `lib/utils/gemini_response_parser.dart`
- `test/utils/gemini_response_parser_test.dart`

### 변경 내용

1. opening fence 제거 정규식을 `_openingMarkdownFenceRegex`로 분리했다.
2. closing fence 제거 정규식을 `_closingMarkdownFenceRegex`로 분리했다.
3. opening fence는 다음 변형을 처리하도록 했다.
   - 대소문자 무관 언어 태그
   - fence 뒤 공백
   - 언어 태그 뒤 개행
   - `\r\n` / `\n` 개행
4. closing fence는 JSON 본문 끝의 fence만 제거하도록 했다.
5. 기존 lower-case `json` 코드블록 처리 테스트를 유지하면서, 대문자/공백 포함 케이스를 회귀 테스트로 추가했다.

핵심 변경:

```dart
static final RegExp _openingMarkdownFenceRegex = RegExp(
  r'^```\s*[A-Za-z0-9_-]*\s*\r?\n?',
  caseSensitive: false,
);
static final RegExp _closingMarkdownFenceRegex = RegExp(r'\r?\n?```\s*$');
```

## 5. 개선 효과 검증

### Focused 검증

명령:

```bash
dart format lib/utils/gemini_response_parser.dart test/utils/gemini_response_parser_test.dart
flutter test test/utils/gemini_response_parser_test.dart
```

결과:

- `dart format`: `Formatted 2 files (1 changed)`
- focused `gemini_response_parser_test`: `+17: All tests passed!`

Before/After:

| 항목 | Before | After |
|---|---:|---:|
| 전체 테스트 수 | 157 | 160 |
| focused parser 테스트 결과 | 2개 실패 | 17개 통과 |
| 대문자 `JSON` fence 처리 | 실패 | 성공 |
| 공백 포함 ` json` fence 처리 | 실패 | 성공 |
| `parseRecommendations()` 대문자 fence 응답 | 미검증 | 성공 검증 |

### 전체 검증

명령:

```bash
flutter analyze
flutter test
graphify update .
```

결과:

- `flutter analyze`: `No issues found! (ran in 3.9s)`
- `flutter test`: `+160: All tests passed!`
- `graphify update .`: `5752 nodes, 5729 edges, 1162 communities`로 갱신 완료

## 6. 보안/리스크 검토

- 새 API key/token/password/private key 없음
- 네트워크 호출/권한/스토리지 접근 변경 없음
- JSON 파싱 전 문자열 전처리 범위만 변경
- 기존 정상 케이스 유지:
  - plain JSON 문자열
  - ` ```json ` 코드블록
  - 언어 태그 없는 ` ``` ` 코드블록
- 리스크:
  - fence 안의 언어 태그 허용 범위는 `[A-Za-z0-9_-]`로 제한했다. 일반적인 `json`, `JSON`, `jsonc` 등은 처리 가능하다.
  - 문자열이 ` ``` `로 시작할 때만 fence 제거를 수행하므로 JSON 본문 내부 backtick에는 영향이 없다.

## 7. 결론

실제 개선 확인 완료.

- 반복 개선 전 프로젝트 분석 완료
- baseline `flutter analyze` / `flutter test` 통과 상태 기록
- RED 테스트로 기존 파서 실패 재현
- 구현 후 focused 테스트 GREEN 확인
- 전체 `flutter analyze` / `flutter test` 통과 확인
- Gemini 응답 코드블록 변형 대응력 개선

## 8. 다음 반복 개선 후보

1. `ApiProxyService` 테스트에서 의도된 500 에러 케이스가 error 로그로 출력되는 부분 정리
2. Graphify 대상에서 `ios/Pods` 제외 여부 검토로 그래프 노이즈 축소
3. Gemini 추천/리뷰 파서의 JSON 앞뒤 설명 문장 포함 응답 처리 강화

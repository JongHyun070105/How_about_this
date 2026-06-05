# ReviewAI Flutter 반복 개선 전 분석 및 검증 기록

- 작성 시각: 2026-06-05 23:01 KST
- 대상 브랜치: `develop`
- 대상 저장소: `reviewai_flutter` (`JongHyun070105/How_about_this`)
- 기준 HEAD: `3e9ee99993bca7fbb05ca3dd47c5a3798666724e`

## 1. 프로젝트 분석

### Graphify 기준 구조

작업 시작 전 `graphify-out/GRAPH_REPORT.md`를 먼저 확인했다. `graphify-out/wiki/index.md`는 없어서 `GRAPH_REPORT.md`와 graphify query를 기준으로 분석했다.

- 시작 graphify freshness: built from commit `3e9ee999`
- graphify query 결과 중심 노드:
  - `lib/utils/gemini_response_parser.dart`
  - `test/utils/gemini_response_parser_test.dart`
  - `GeminiResponseParser`
- 변경 후 graphify update:
  - AST extraction: `1302 / 1302 files (100%)`
  - rebuilt: `5795 nodes / 5770 edges / 1172 communities`
- 비고: `graph.html`은 노드 수가 5,000개 제한을 넘어 생략됐지만 `graph.json`과 `GRAPH_REPORT.md`는 정상 갱신됐다.

### 개선 후보 선정 근거

이번 반복 개선 대상은 `GeminiResponseParser.parseRecommendations()`의 JSON wrapper 응답 처리다.

직전 반복에서 JSON 앞뒤 설명 문장 포함 응답은 처리 가능해졌지만, LLM/API가 다음처럼 배열을 객체 키로 감싸서 반환할 경우 기존 코드는 `jsonDecode()` 결과를 곧바로 `List<dynamic>`에 대입해 실패했다.

```json
{"recommendations": [{"name": "쌀국수", "imageUrl": ""}]}
```

선정 이유:

- `GeminiResponseParser`는 추천 API 응답 파싱의 중앙 유틸리티다.
- wrapper JSON은 LLM 응답에서 흔한 변형이다.
- 기존 테스트 파일이 있어 RED/GREEN으로 실제 개선을 증명할 수 있다.
- UI, 네트워크, 저장소 권한 변경 없이 파싱 안정성만 개선한다.

## 2. Baseline 검증

명령:

```bash
flutter analyze
flutter test
```

결과:

- `flutter analyze`: `No issues found! (ran in 4.5s)`
- `flutter test`: `+162: All tests passed!`

해석:

- 변경 전 전체 suite는 통과 상태였다.
- 단, `recommendations` 키로 감싼 JSON 객체 응답은 테스트되지 않았다.

## 3. RED 테스트

추가한 회귀 테스트:

- 파일: `test/utils/gemini_response_parser_test.dart`
- 테스트명: `recommendations 키로 감싼 JSON 객체 응답을 파싱한다`

RED 명령:

```bash
flutter test test/utils/gemini_response_parser_test.dart --reporter expanded
```

RED 결과:

- exit code: `1`
- 결과: `+19 -1: Some tests failed.`
- 실패 증거:
  - `type '_Map<String, dynamic>' is not a subtype of type 'List<dynamic>'`
  - `JSON 파싱 실패: type '_Map<String, dynamic>' is not a subtype of type 'List<dynamic>'`

즉, 기존 코드가 wrapper JSON 응답을 실제로 처리하지 못함을 확인했다.

## 4. 적용한 개선

### 변경 파일

- `lib/utils/gemini_response_parser.dart`
- `test/utils/gemini_response_parser_test.dart`

### 변경 내용

1. `jsonDecode(cleanedJson)` 결과를 바로 `List<dynamic>`로 간주하지 않도록 변경했다.
2. `_extractRecommendationItems()` helper를 추가했다.
3. 기존 배열 응답은 그대로 처리한다.
4. 객체 wrapper 응답은 다음 키 중 배열 값을 찾아 추천 리스트로 사용한다.
   - `recommendations`
   - `items`
   - `foods`
   - `results`
5. 배열을 찾지 못하면 `FormatException('추천 JSON 배열을 찾을 수 없습니다.')`를 던져 기존 예외 처리 흐름으로 실패시킨다.

핵심 효과:

- Before: `{"recommendations": [...]}` → `_Map<String, dynamic>` type error
- After: `{"recommendations": [...]}` → 내부 배열 추출 후 `FoodRecommendation` 리스트 생성

## 5. File-mutation verifier 경고 대응

사용자 메시지의 경고:

```text
/Users/macintosh/IdeaProjects/reviewai_flutter/lib/utils/gemini_response_parser.dart — [patch] Found 2 matches for old_string. Provide more context to make it unique, or use replace_all=True.
```

대응:

- 이번 작업에서는 고유한 주변 문맥이 포함된 patch로 `lib/utils/gemini_response_parser.dart`를 실제 수정했다.
- 수정 직후 다음으로 확인했다.
  - `git status --short --branch`: `M lib/utils/gemini_response_parser.dart`
  - `git diff --stat -- lib/utils/gemini_response_parser.dart`: `1 file changed, 18 insertions(+), 1 deletion(-)`
  - `read_file`로 `_extractRecommendationItems()`와 `jsonDecode()` 후 helper 호출이 파일에 실제 존재함을 확인했다.

따라서 해당 verifier 경고는 이번 턴에서 실제 파일 변경과 read-back 검증으로 해소했다.

## 6. 개선 효과 검증

### Focused 검증

명령:

```bash
dart format lib/utils/gemini_response_parser.dart test/utils/gemini_response_parser_test.dart
flutter test test/utils/gemini_response_parser_test.dart --reporter expanded
```

결과:

- `dart format`: `Formatted 2 files (0 changed)`
- focused `gemini_response_parser_test`: `+20: All tests passed!`

Before/After:

| 항목 | Before | After |
|---|---:|---:|
| 전체 테스트 수 | 162 | 163 |
| focused parser 테스트 결과 | `+19 -1` 실패 | `+20` 통과 |
| wrapper JSON `recommendations` 처리 | 실패 | 성공 |
| 기존 배열/마크다운/설명 문장 케이스 | 통과 | 통과 유지 |

### 전체 검증

명령:

```bash
flutter analyze
flutter test
graphify update .
```

결과:

- `flutter analyze`: `No issues found! (ran in 4.0s)`
- `flutter test`: `+163: All tests passed!`
- `graphify update .`: `5795 nodes / 5770 edges / 1172 communities`로 갱신 완료

## 7. 보안/리스크 검토

- 새 API key/token/password/private key 없음
- 네트워크 호출/권한/스토리지 접근 변경 없음
- JSON 파싱 후 자료형 정규화만 변경
- 기존 정상 케이스 유지:
  - plain JSON 배열
  - 마크다운 fenced JSON
  - 대문자/공백 언어 태그 fenced JSON
  - JSON 앞뒤 설명 문장 포함 응답
- 리스크:
  - wrapper 객체에서 여러 후보 키가 동시에 있으면 `recommendations`, `items`, `foods`, `results` 순서로 첫 배열을 선택한다.
  - wrapper 내부 배열이 아닌 값이면 기존처럼 예외 처리 흐름으로 실패한다.

## 8. 결론

실제 개선 확인 완료.

- 반복 개선 전 graphify 기반 프로젝트 분석 완료
- baseline `flutter analyze` / `flutter test` 통과 상태 기록
- RED 테스트로 기존 wrapper JSON 실패 재현
- 최소 구현 후 focused 테스트 GREEN 확인
- 전체 `flutter analyze` / `flutter test` 통과 확인
- file-mutation verifier 경고 대상 파일의 실제 변경과 read-back 확인 완료

## 9. 다음 반복 개선 후보

1. `ApiProxyService` 테스트에서 의도된 500 에러 케이스가 error 로그로 출력되는 부분 정리
2. Graphify 대상에서 `ios/Pods` 제외 여부 검토로 그래프 노이즈 축소
3. wrapper JSON의 후보 키 정책을 API contract 문서나 prompt schema에 명시

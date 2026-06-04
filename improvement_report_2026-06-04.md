# ReviewAI Flutter 반복 개선 전 분석 및 검증 기록

- 작성 시각: 2026-06-04 22:45 KST
- 대상 브랜치: `develop`
- 대상 저장소: `reviewai_flutter` (`JongHyun070105/How_about_this`)
- 기준 HEAD: `38ca9ff8dcdb9695dc941fd88a256ed8cb5c4797`

## 1. 프로젝트 분석

### Graphify 기준 구조

작업 시작 전 `graphify-out/GRAPH_REPORT.md`를 먼저 확인했다. `graphify-out/wiki/index.md`는 없어서 `GRAPH_REPORT.md`와 graphify query를 기준으로 앱 구조와 개선 후보를 확인했다.

초기 graphify 리포트는 이전 커밋 기준이어서 작업 전 `graphify update .`를 실행해 현재 HEAD 기준으로 갱신했다.

- 작업 전 최신화: `5773 nodes / 5749 edges / 1159 communities`
- 변경 후 최신화: `5774 nodes / 5750 edges / 1163 communities`
- AST extraction: `1301 / 1301 files (100%)`
- 비고: `graph.html`은 노드 수가 5,000개 제한을 넘어 생략됐지만 `graph.json`과 `GRAPH_REPORT.md`는 정상 갱신됐다.

### 개선 후보 선정 근거

이번 반복 개선 대상은 `GeminiResponseParser.cleanMarkdownJson()` / `parseRecommendations()`의 LLM 응답 전처리다.

기존 파서는 이전 반복에서 마크다운 fence 변형(`JSON`, ` json`)은 처리하도록 개선됐지만, 실제 LLM이 JSON 앞뒤에 설명 문장을 덧붙이는 경우에는 전체 문자열을 그대로 `jsonDecode()`에 넘겨 실패할 수 있었다.

선정 이유:

- `lib/utils/gemini_response_parser.dart`는 추천 API 응답 파싱의 중앙 유틸리티다.
- 기존 테스트가 이미 있어 RED/GREEN으로 작은 개선 효과를 증명하기 좋다.
- 네트워크, 스토리지, UI 변경 없이 파싱 안정성만 높일 수 있다.

## 2. Baseline 검증

명령:

```bash
flutter analyze
flutter test
```

결과:

- `flutter analyze`: `No issues found! (ran in 4.6s)`
- `flutter test`: `+160: All tests passed!`

해석:

- 변경 전 전체 suite는 정상 통과 상태였다.
- 단, 설명 문장이 JSON 앞뒤에 붙은 Gemini/LLM 응답 케이스는 테스트되지 않았다.

## 3. RED 테스트

추가한 회귀 테스트:

- 파일: `test/utils/gemini_response_parser_test.dart`
- 테스트명:
  - `설명 문장이 앞뒤에 있어도 JSON 배열만 추출한다`
  - `설명 문장으로 감싼 추천 응답을 파싱한다`

RED 명령:

```bash
flutter test test/utils/gemini_response_parser_test.dart --reporter expanded
```

RED 결과:

- exit code: `1`
- 결과: `+17 -2: Some tests failed.`
- 실패 증거:
  - expected: `[{"name": "칼국수"}]`
  - actual: `추천 메뉴는 아래와 같습니다.\n[{"name": "칼국수"}]\n맛있게 드세요!`
  - `FormatException: Unexpected character (at character 1)`

즉, 기존 코드가 설명 문장 포함 응답을 실제로 처리하지 못함을 확인했다.

## 4. 적용한 개선

### 변경 파일

- `lib/utils/gemini_response_parser.dart`
- `test/utils/gemini_response_parser_test.dart`

### 변경 내용

1. `cleanMarkdownJson()`이 마크다운 fence 제거 후 JSON payload만 추출하도록 확장했다.
2. `_extractJsonPayload()`를 추가해 문자열에서 첫 번째 유효 JSON 배열/객체 후보를 찾는다.
3. `_balancedJsonSubstring()`를 추가해 `[]`, `{}` 균형을 스캔한다.
4. JSON 문자열 내부의 따옴표와 escape 문자를 고려해 본문 안의 bracket 때문에 조기 종료되지 않게 했다.
5. 기존 plain JSON, fenced JSON, 대문자/공백 언어 태그 테스트를 유지하면서 설명 문장 포함 케이스를 추가했다.

핵심 효과:

- 입력: `추천 메뉴는 아래와 같습니다.\n[{"name":"칼국수"}]\n맛있게 드세요!`
- 출력: `[{"name":"칼국수"}]`
- 이후 `parseRecommendations()`가 정상적으로 `FoodRecommendation(name: 칼국수)`를 생성한다.

## 5. 개선 효과 검증

### Focused 검증

명령:

```bash
dart format lib/utils/gemini_response_parser.dart test/utils/gemini_response_parser_test.dart
flutter test test/utils/gemini_response_parser_test.dart --reporter expanded
```

결과:

- `dart format`: `Formatted 2 files (0 changed)`
- focused `gemini_response_parser_test`: `+19: All tests passed!`

Before/After:

| 항목 | Before | After |
|---|---:|---:|
| 전체 테스트 수 | 160 | 162 |
| focused parser 테스트 결과 | `+17 -2` 실패 | `+19` 통과 |
| 설명 문장 포함 JSON 배열 추출 | 실패 | 성공 |
| 설명 문장 포함 추천 응답 파싱 | 실패 | 성공 |

### 전체 검증

명령:

```bash
flutter analyze
flutter test
graphify update .
```

결과:

- `flutter analyze`: `No issues found! (ran in 3.2s)`
- `flutter test`: `+162: All tests passed!`
- `graphify update .`: `5774 nodes / 5750 edges / 1163 communities`로 갱신 완료

## 6. 보안/리스크 검토

- 새 API key/token/password/private key 없음
- 네트워크 호출/권한/스토리지 접근 변경 없음
- JSON 파싱 전 문자열 전처리 범위만 변경
- 기존 정상 케이스 유지:
  - plain JSON 문자열
  - ` ```json ` 코드블록
  - 언어 태그 없는 ` ``` ` 코드블록
  - 대문자 `JSON` / 공백 포함 ` json` 코드블록
- 리스크:
  - 앞쪽의 첫 유효 JSON 배열/객체를 payload로 선택한다. 추천 응답은 JSON 배열을 요구하므로, 응답 설명에 다른 bracket 구조가 먼저 등장하면 첫 유효 JSON 후보를 선택할 수 있다.
  - 균형 스캔은 JSON 문자열 내부 escape와 quote를 고려하지만, 최종 유효성은 기존처럼 `jsonDecode()`가 검증한다.

## 7. 결론

실제 개선 확인 완료.

- 반복 개선 전 graphify 기반 프로젝트 분석 완료
- baseline `flutter analyze` / `flutter test` 통과 상태 기록
- RED 테스트로 기존 파서 실패 재현
- 최소 구현 후 focused 테스트 GREEN 확인
- 전체 `flutter analyze` / `flutter test` 통과 확인
- Gemini/LLM 응답이 JSON 앞뒤 설명 문장을 포함해도 추천 파싱이 가능해졌다.

## 8. 다음 반복 개선 후보

1. `ApiProxyService` 테스트에서 의도된 500 에러 케이스가 error 로그로 출력되는 부분 정리
2. Graphify 대상에서 `ios/Pods` 제외 여부 검토로 그래프 노이즈 축소
3. `parseRecommendations()`가 JSON 객체 wrapper(`{"items": [...]}` 등)를 받는 경우의 정책 정의 및 테스트 추가

# ReviewAI Flutter 반복 개선 전 분석 및 검증 기록

- 작성 시각: 2026-06-08 22:31 KST
- 대상 브랜치: `develop`
- 대상 저장소: `reviewai_flutter` (`JongHyun070105/How_about_this`, GitHub moved notice: `JongHyun070105/how-about-this`)
- 기준 HEAD: `88b963d23da9e94bee0535939bb0818cc6695c06`

## 1. 프로젝트 분석

### Graphify 기준 구조

작업 시작 전 `graphify-out/GRAPH_REPORT.md`를 먼저 확인했다.

- `graphify-out/wiki/index.md`: 없음
- baseline graph report: built from commit `38bf934c`
- 작업 후 `graphify update .`로 graph를 갱신했고, 최신 report는 commit `88b963d2` 기준으로 재생성됐다.
- graphify corpus: `1307 files`
- graphify summary: `5854 nodes / 5842 edges / 1169 communities`

### 개선 후보 선정 근거

이번 반복 개선 대상은 `ApiProxyService.generateReviews()`의 Gemini JSON 응답 파싱 안정성이다.

Graphify / source inspection 기준으로 중앙 경로는 다음과 같았다.

- `lib/services/api_proxy_service.dart`
- `lib/utils/gemini_response_parser.dart`
- 테스트: `test/services/api_proxy_service_test.dart`

기존 구현은 다음 케이스를 이미 처리한다.

- plain JSON array
- ` ```json ` fenced 응답
- wrapper가 없는 표준 리뷰 배열

하지만 LLM이 종종 내는 아래 변형은 실패했다.

- `{"reviews": ["R1", "R2", "R3"]}` 같은 wrapper 객체

선정 이유:

- 리뷰 생성은 사용자 체감이 큰 기능이라 파싱 실패가 바로 품질 저하로 이어진다.
- wrapper 객체는 LLM 출력에서 흔한 변형이다.
- 기존 서비스 테스트가 있어 RED/GREEN으로 실제 개선을 증명할 수 있다.
- 네트워크/API 계약은 건드리지 않고 로컬 파싱만 개선할 수 있다.

## 2. Baseline 검증

명령:

```bash
flutter analyze
flutter test
```

결과:

- `flutter analyze`: `No issues found! (ran in 4.5s)`
- `flutter test`: `+171: All tests passed!`

해석:

- 변경 전 전체 suite는 통과 상태였다.
- 다만 리뷰 응답이 wrapper object로 오는 케이스는 아직 검증되지 않았다.

## 3. RED 테스트

추가한 회귀 테스트:

- 파일: `test/services/api_proxy_service_test.dart`
- 테스트명: `객체 래핑 응답도 정상 파싱`

RED 명령:

```bash
flutter test test/services/api_proxy_service_test.dart
```

RED 결과:

- exit code: `1`
- 결과: `+7 -1: Some tests failed.`
- 실패 증거:
  - `ApiException: 데이터 파싱 오류: 리뷰 생성 중 오류가 발생했습니다. (Status Code: N/A)`

즉, 기존 코드가 wrapper object 리뷰 응답을 실제로 처리하지 못함을 확인했다.

## 4. 적용한 개선

### 변경 파일

- `lib/services/api_proxy_service.dart`
- `test/services/api_proxy_service_test.dart`

### 변경 내용

1. `ApiProxyService`에 `_extractReviewItems(dynamic decodedJson)` helper를 추가했다.
2. `generateReviews()`가 `json.decode()` 결과가 `List`이든 wrapper `Map`이든 처리하도록 바꿨다.
3. wrapper key 후보를 다음으로 허용했다.
   - `reviews`
   - `items`
   - `results`
   - `recommendations`
4. 테스트에 wrapper object 회귀 케이스를 추가했다.

핵심 효과:

- Before: `{"reviews": ["R1", "R2", "R3"]}` → 파싱 실패
- After: wrapper object에서 배열을 추출해 `List<String>` 반환

## 5. 개선 효과 검증

### Focused 검증

명령:

```bash
flutter test test/services/api_proxy_service_test.dart
```

결과:

- `+9: All tests passed!`

### 최종 전체 검증

명령:

```bash
flutter analyze
flutter test
graphify update .
```

결과:

- `flutter analyze`: `No issues found! (ran in 2.8s)`
- `flutter test`: `+172: All tests passed!`
- `graphify update .`:
  - `AST extraction: 1307/1307 files (100%)`
  - `Rebuilt: 5854 nodes / 5842 edges / 1169 communities`
  - `graphify-out/GRAPH_REPORT.md` 갱신 완료

Before/After:

| 항목 | Before | After |
|---|---:|---:|
| 전체 테스트 수 | 171 | 172 |
| focused 서비스 테스트 결과 | `+7 -1` 실패 | `+9` 통과 |
| 리뷰 응답 wrapper object 처리 | 실패 | 성공 |
| 전체 analyze | 통과 | 통과 유지 |
| 전체 test | 통과 | 통과 유지 |

## 6. 보안/리스크 검토

- 새 API key/token/password/private key 없음
- 네트워크/권한/스토리지 범위 변경 없음
- 리뷰 응답 파싱만 로컬에서 확장
- 기존 plain array 경로 유지
- 리스크:
  - wrapper key가 없는 비정상 JSON은 기존 예외 흐름으로 실패한다.
  - parser 자체를 무조건 느슨하게 만들지 않고, 허용 key를 좁게 제한했다.

## 7. 결론

실제 개선 확인 완료.

- 반복 개선 전 graphify 기반 프로젝트 분석 완료
- baseline `flutter analyze` / `flutter test` 통과 상태 기록
- RED 테스트로 기존 wrapper object 실패 재현
- 최소 구현 후 focused 테스트 GREEN 확인
- 전체 `flutter analyze` / `flutter test` 통과 확인
- `graphify update .` 완료

## 8. 다음 반복 개선 후보

1. `ApiProxyService.generateReviews()`와 `GeminiResponseParser.parseRecommendations()`의 wrapper key 정책 공통화
2. `GeminiResponseParser.cleanMarkdownJson()`가 multiple JSON candidate를 더 잘 고르도록 강화
3. `ApiProxyService`의 리뷰/검증 파싱 오류 메시지를 더 세분화해 사용자 진단 품질 개선

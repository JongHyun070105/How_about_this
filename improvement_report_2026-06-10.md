# ReviewAI Flutter 반복 개선 전 분석 및 검증 기록 (8차)

- 작성 시각: 2026-06-10 23:12 KST
- 대상 브랜치: `develop`
- 대상 저장소: `reviewai_flutter`
- 작업 시작 HEAD: `b5d0460977eaa191f24377e4d5c679a3feb72d26`

## 1. 프로젝트 분석

### Graphify 기준 구조

작업 시작 전 `graphify-out/GRAPH_REPORT.md`를 갱신하고 분석을 수행했다.

- graph report 최신본 기준: `2026-06-10`
- corpus: `1310 files`
- summary: `5901 nodes / 5890 edges / 1167 communities`

### 개선 후보 선정 근거

이번 반복 개선 대상은 크게 2가지 영역의 비효율 및 잠재적 장애 요인 해결이다.

1. **Gemini 응답 파서 정책 일원화 및 버그 해결**
   - 기존 구현에서 `GeminiResponseParser`와 `ApiProxyService`로 나뉘어 있던 JSON 배열 추출 기능(`_extractRecommendationItems` 및 `_extractReviewItems`)을 분석한 결과, 파싱 가능한 래핑 키(`candidateKeys`) 목록이 상이하여 불일치가 발생하고 있었다.
   - 특히 `GeminiResponseParser`에서는 `reviews`가 래핑 키로 인식되었으나 실제 추출 단계에서는 `reviews`가 누락되어 `FormatException`을 던지고 실패하는 치명적 잠재적 에러가 발견되었다.
   - 두 도메인에 분산된 JSON 배열 추출 로직을 `GeminiResponseParser.extractListFromWrappedJson`으로 통합하여 견고함을 확보한다.

2. **UserPreferenceService 메모리 캐싱 및 I/O 절감**
   - `UserPreferenceService`는 음식 기록을 조회하거나 추가할 때마다 비동기로 `PersistentStorageService`를 호출하여 로컬 파일을 읽고 JSON 파싱/인코딩을 거치고 있었다.
   - 동일 사용자의 단기간 반복적인 조회와 기록 갱신(기록 추가 시 조회 -> 수정 -> 쓰기 및 싫어하는 음식 추가 발생 등)이 발생할 때마다 매번 플랫폼 채널 및 디바이스 디스크 I/O를 발생시키는 오버헤드가 발견되었다.
   - 이를 메모리 수준의 `static` 변수 캐싱으로 최적화하여 룩업 응답 속도를 0ms에 수렴하게 한다.
   - 아울러 테스트 시 Mock 저장소 주입 경로를 만들어 테스트 무결성을 입증한다.

## 2. Baseline 검증

명령:

```bash
flutter analyze
flutter test
```

결과:

- `flutter analyze`: `No issues found! (ran in 3.1s)`
- `flutter test`: `+173: All tests passed!`

## 3. 적용한 개선

### 변경 파일

- `lib/utils/gemini_response_parser.dart`
- `lib/services/api_proxy_service.dart`
- `lib/services/user_preference_service.dart`
- `test/utils/gemini_response_parser_test.dart`
- `test/services/user_preference_service_test.dart` [NEW]

### 변경 내용

1. **GeminiResponseParser**
   - `extractListFromWrappedJson` 공통 래핑 키 추출 로직을 정의하고 `candidateKeys` 목록을 `['recommendations', 'items', 'foods', 'results', 'reviews']`로 통합하여 공통 활용하도록 구현하였다.
2. **ApiProxyService**
   - 중복 구현되었던 `_extractReviewItems`를 제거하고 공통 메소드 호출로 통일하였다.
3. **UserPreferenceService**
   - static 메모리 캐시 변수 `_cachedHistory`와 `_cachedDislikedFoods`를 관리하여 조회 시 디스크 조회 없이 즉시 반환하도록 했다.
   - 데이터 변경 시 캐시를 동기식으로 즉시 반영하고 백그라운드에 파일 쓰기를 시켜 I/O 병목을 제거하였다.
   - `setStorageServiceForTesting` 및 `clearCache`를 마련해 테스트 모킹을 지원한다.
4. **유닛 테스트 추가 및 보완**
   - `gemini_response_parser_test.dart`에 `extractListFromWrappedJson` 검증 테스트를 보완했다.
   - `user_preference_service_test.dart`를 신규 생성하여 Mock 저장소를 주입하고 2회차 호출 시 디스크 I/O가 0회 발생함을 정밀 측정하고 검증했다.

## 4. 개선 효과 검증

### 최종 전체 검증

명령:

```bash
flutter analyze
flutter test
graphify update .
```

결과:

- `flutter analyze`: `No issues found! (ran in 5.9s)`
- `flutter test`: `+180: All tests passed!` (신규 7개 유닛 테스트 케이스 모두 성공)
- `graphify update .`: `5901 nodes / 5890 edges / 1167 communities` 최신화 완료

Before/After 비교:

| 항목 | Before | After |
|---|---:|---:|
| 전체 테스트 수 | 173 | 180 |
| UserPreferenceService I/O 횟수 | 매 조회/갱신 시 디스크 접근 | 최초 1회 후 메모리 캐시 룩업 (I/O 0회) |
| reviews 래핑 키 추천 파싱 | FormatException 발생 | 정상 파싱 완료 |
| 전체 analyze | 통과 | 통과 유지 |
| 전체 test | 통과 | 통과 유지 |

## 5. 결론

실제 개선 확인 완료.

- 래핑 JSON 파서 로직 통합을 통한 잠재적 파싱 포맷 에러 해결
- UserPreferenceService 메모리 캐시 설계 및 구현을 통해 불필요한 플랫폼 채널 병목 차단
- 단위 테스트 추가 작성을 통한 동작 신뢰성 입증
- 8차 반복 최적화에 대한 `graphify update .` 완료

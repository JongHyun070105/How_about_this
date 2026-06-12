# ReviewAI Flutter 반복 개선 전 분석 및 검증 기록 (10차)

- 작성 시각: 2026-06-12 20:46 KST
- 대상 브랜치: `develop`
- 대상 저장소: `reviewai_flutter`
- 작업 시작 HEAD: `5e77ae1241f3df7b9e73fb39c037920170420a7b`

## 1. 프로젝트 분석

### Graphify 기준 구조

작업 시작 전 `graphify-out/GRAPH_REPORT.md`를 갱신하고 분석을 수행했다.

- graph report 최신본 기준: `2026-06-12`
- corpus: `1314 files`
- summary: `5940 nodes / 5940 edges / 1177 communities`

### 개선 후보 선정 근거

이번 반복 개선 대상은 사용량 한도 관리를 맡는 `UsageTrackingService` 내부의 데이터 로드 지연 해결 및 테스트 확장성 확보이다.

- **사용량 데이터 조회 시의 파일 I/O 병목 제거**
  - 기존에는 남은 리뷰 수, 추천 가능 수 등 단순 사용량 한도 체크와 누적량 조회 함수가 호출될 때마다 매번 디렉토리 내 `usage_data.json` 파일을 비동기식으로 읽어와서 파싱을 수행하고 있었다.
  - 하루에도 여러 번 발생하는 룩업 연산 시마다 발생하는 비동기 플랫폼 채널 I/O를 메모리 레벨 캐시(`_cachedReviewCount`, `_cachedTotalRecCount`, `_cachedLastResetDate`, `_cachedLastAccessTimestamp`)로 대폭 단축하여, 2회차 조회부터는 디스크 접근 횟수 0회(0ms 지연)로 가속화했다.
  - 카운트 갱신 시에는 메모리 캐시를 동기 수준으로 즉각 업데이트하여 상태 일관성을 부여하고 파일 쓰기는 비동기로 수행하도록 최적화했다.
- **저장소 의존성 주입(Dependency Injection) 적용**
  - 생성자 선택적 매개변수를 통해 `PersistentStorageService`를 외부에서 주입받을 수 있도록 변경함으로써, 모킹 저장소를 활용한 안정적인 일상 사용량 제어 단위 테스트 작성이 가능해졌다.

## 2. Baseline 검증

명령:

```bash
flutter analyze
flutter test
```

결과:

- `flutter analyze`: `No issues found! (ran in 3.1s)`
- `flutter test`: `+183: All tests passed!`

## 3. 적용한 개선

### 변경 파일

- `lib/services/usage_tracking_service.dart`
- `test/services/usage_tracking_service_test.dart` [NEW]

### 변경 내용

1. **UsageTrackingService**
   - 멤버 캐시 필드를 선언하고, `_ensureCached()` 메서드를 구현해 최초 1회에 한해서만 디바이스 디스크에서 값을 동기화하도록 했다.
   - `incrementReviewCount`, `incrementTotalRecommendationCount` 호출 시 값을 캐시 수치에 즉각 선대응한 후, `_storageService.setValue`로 파일에 비동기 플러시하게 설계하여 지연을 최소화했다.
   - 테스트를 위한 저장소 주입 경로(`PersistentStorageService? storageService`) 및 메모리 캐시 무효화 메서드(`clearCache()`)를 신설했다.
2. **단위 테스트 추가 작성**
   - `usage_tracking_service_test.dart`를 개설하여 `MockPersistentStorageService` 및 `MockRemoteConfigService` 기반의 3가지 핵심 사용 시나리오를 단위 테스트했다.
   - 2회차 연속 조회 시 파일 I/O가 0회인지 검증하고, 카운트 갱신 시 읽기 동작 없이 쓰기만 1회 발생하는지 정밀하게 분석했다.
   - 또한, 전일(yesterday) 날짜로 세팅된 사용 기록이 오늘(today) 날짜 조회와 부딪힐 때 자동으로 0으로 카운터가 리셋되는 비즈니스 정합성을 통과시켰다.

## 4. 개선 효과 검증

### 최종 전체 검증

명령:

```bash
flutter analyze
flutter test
graphify update .
```

결과:

- `flutter analyze`: `No issues found! (ran in 3.1s)`
- `flutter test`: `+186: All tests passed!` (신규 3개 유닛 테스트 케이스 모두 성공)
- `graphify update .`: `5940 nodes / 5940 edges / 1177 communities` 최신화 완료

Before/After 비교:

| 항목 | Before | After |
|---|---:|---:|
| 전체 테스트 수 | 183 | 186 |
| 사용량 조회 디스크 I/O | 매 조회 시 비동기 디스크 룩업 | 최초 1회만 디스크 룩업 후 메모리 즉각 조회 (I/O 0회) |
| 사용량 갱신 시 추가 디스크 읽기 | 갱신할 때마다 기존 데이터 로드 I/O 발생 | 로드 동작 0회 (메모리에서 바로 연산 후 쓰기 수행) |
| 전체 analyze | 통과 | 통과 유지 |
| 전체 test | 통과 | 통과 유지 |

## 5. 결론

실제 개선 확인 완료.

- 일상적인 리뷰 생성 및 추천 횟수 제한 제어 시 불필요한 SharedPreferences 디스크 오버헤드를 원천 차단
- 저장소 모킹 주입을 통한 한도 제어 비즈니스 테스트 신뢰성 확보
- 10차 반복 최적화에 대한 `graphify update .` 완료

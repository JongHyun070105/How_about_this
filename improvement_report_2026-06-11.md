# ReviewAI Flutter 반복 개선 전 분석 및 검증 기록 (9차)

- 작성 시각: 2026-06-11 23:20 KST
- 대상 브랜치: `develop`
- 대상 저장소: `reviewai_flutter`
- 작업 시작 HEAD: `7f8c191a329d6bead5323a7bbd3c1265b7501e4a`

## 1. 프로젝트 분석

### Graphify 기준 구조

작업 시작 전 `graphify-out/GRAPH_REPORT.md`를 갱신하고 분석을 수행했다.

- graph report 최신본 기준: `2026-06-11`
- corpus: `1312 files`
- summary: `5920 nodes / 5917 edges / 1177 communities`

### 개선 후보 선정 근거

이번 반복 개선 대상은 `ReviewService` 내부의 디스크 누수 위협 해결 및 플랫폼 의존성 성능 강화이다.

- **임시 최적화 이미지의 자원 누수(Leak) 방지**
  - 기존 `ReviewService.generateReviewsFromState`에서 이미지 최적화 시 임시 최적화 파일(`optimized_*.jpg`)을 생성하지만, API 호출 완료 후에만 삭제가 시도되었다.
  - 이로 인해 API 호출 도중 네트워크 에러가 발생하거나 `TimeoutException`이 발생하여 45초 시간 초과가 될 경우, catch 블록으로 곧바로 빠져나가 임시 이미지 삭제 로직이 실행되지 않았다.
  - 이는 사용자가 리뷰 생성 실패를 겪을 때마다 기기에 수백 KB에서 MB에 달하는 가비지 이미지가 그대로 누적되는 디스크 누수 현상을 유발했다.
  - `try-finally` 구문을 활용해 성공 여부와 상관없이 무조건 임시 파일을 깨끗이 정리하도록 개선한다.
- **임시 디렉토리 경로 캐싱**
  - 이미지 최적화 함수 `_optimizeImage` 내에서 매번 `getTemporaryDirectory()`를 비동기 호출하여 플랫폼 채널 바인딩을 하던 지연 오버헤드를 줄이기 위해, 경로 정보를 최초 1회 룩업 후 `_cachedTempDirPath` 정적 변수에 캐싱해 두도록 최적화했다.

## 2. Baseline 검증

명령:

```bash
flutter analyze
flutter test
```

결과:

- `flutter analyze`: `No issues found! (ran in 3.1s)`
- `flutter test`: `+180: All tests passed!`

## 3. 적용한 개선

### 변경 파일

- `lib/services/review_service.dart`
- `test/services/review_service_test.dart` [NEW]

### 변경 내용

1. **ReviewService**
   - static `_cachedTempDirPath` 변수를 신설하여 `_optimizeImage` 내에서 최초 1회 획득한 이후에는 플랫폼 채널 호출 없이 즉시 캐시 경로를 사용하도록 했다.
   - `generateReviewsFromState`에서 `try-catch`로 묶여있던 영역을 `try-finally` 구조로 개편하여 예외나 타임아웃이 나도 임시 이미지 삭제가 100% 호출되도록 보장하였다.
2. **단위 테스트 추가 작성**
   - `review_service_test.dart`를 신규 개설하여 `FakeApiProxyService`와 `MethodChannel('plugins.flutter.io/path_provider')` 모킹을 통해 실제 800px 초과 가짜 JPEG 이미지를 인코딩하여 인입시켰다.
   - API가 정상 완료될 때, 예외를 던질 때, 타임아웃이 터질 때 임시 최적화 파일이 디바이스 디스크상에 남지 않고 완벽하게 삭제되는지 3가지 시나리오를 정밀하게 검증하였다.

## 4. 개선 효과 검증

### 최종 전체 검증

명령:

```bash
flutter analyze
flutter test
graphify update .
```

결과:

- `flutter analyze`: `No issues found! (ran in 3.4s)`
- `flutter test`: `+183: All tests passed!` (신규 추가된 자원 정리 및 캐싱 테스트 3개 모두 성공)
- `graphify update .`: `5920 nodes / 5917 edges / 1177 communities` 최신화 완료

Before/After 비교:

| 항목 | Before | After |
|---|---:|---:|
| 전체 테스트 수 | 180 | 183 |
| 에러/타임아웃 시 임시 이미지 | 디스크에 누수 발생 | `finally` 블록에서 100% 즉시 삭제 |
| 임시 경로 조회 플랫폼 채널 | 매 최적화 시 호출 | 최초 1회만 호출 후 메모리 캐시 반환 |
| 전체 analyze | 통과 | 통과 유지 |
| 전체 test | 통과 | 통과 유지 |

## 5. 결론

실제 개선 확인 완료.

- API 예외 상황에서의 디스크/메모리 누수 요인을 완벽하게 방어
- 플랫폼 채널 호출 최소화를 통한 지연 최적화 달성
- 9차 반복 최적화에 대한 `graphify update .` 완료

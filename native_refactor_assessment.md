# Native Refactor Assessment - reviewai_flutter

## Verdict
**No broad Rust/C refactor is justified right now.**

The app is mostly:
- Flutter UI / Riverpod state
- network / API orchestration
- caching / JSON parsing
- small list filtering and sorting

There is **no direct app-side `dart:ffi`, `MethodChannel`, or `EventChannel` usage in `lib/`**. The only `ffi` reference I found is transitive in `pubspec.lock`, not a native boundary in the app code.

## Best candidate to consider later

| Candidate | What it does | Why it is the only plausible hotspot | Recommendation |
|---|---|---|---|
| `lib/services/review_service.dart::_optimizeImage` | decode -> resize -> encode user-uploaded images | This is the only obvious CPU-heavy local path; it touches bitmap decode/resize/encoding | **Implemented as a background isolate in Dart**. Keep Rust/C off the critical path unless profiling later proves isolate is still insufficient |

## Other modules I checked

| Module | What it does | Native refactor value |
|---|---|---|
| `lib/services/recommendation_service.dart` | cache, fetch prompt, parse Gemini response, weighted selection | Low. Dominated by network and small list ops |
| `lib/utils/gemini_response_parser.dart` | JSON cleanup + parsing | Low. Parsing cost is tiny compared to API latency |
| `lib/utils/kakao_api_filter_util.dart` | filter/sort restaurant lists | Low. Could be optimized in Dart with Sets / precomputed strings |
| `lib/services/food_stats_service.dart` | counts/sorts history entries | Low. Linear scans only |

## Why I would not move this to Rust/C now

1. **The hot path is not native-bound.**
   Most time is spent on network/API calls and user interaction, not CPU.

2. **FFI overhead will eat part of the gain.**
   Shipping bytes across Dart ↔ native adds complexity and copies.

3. **Maintenance cost is high.**
   Two codebases, build scripts, platform packaging, debugging, and CI complexity.

4. **The likely win is smaller than a Dart-side fix.**
   For the current code, a background isolate or simpler Dart optimization will usually beat a native rewrite in cost/benefit.

## Best next step if performance is a problem

1. Profile the image optimization path in `ReviewService`.
2. The path now runs on a background isolate, so measure whether that removes UI jank.
3. If it is still a bottleneck and happens often enough, then consider a narrow native image pipeline.
4. Keep the rest of the app in Dart.

## Small Dart optimizations worth doing before native

- Convert repeated `List.contains(...)` checks to `Set` membership in `pickSmartFood`.
- Avoid re-decoding / re-encoding images unless the input is actually too large.
- Reduce repeated JSON encode/decode of cached objects where possible.
- Profile release/profile mode before changing architecture.

## Bottom line

If the goal is **“make the app feel faster”**, the best path is:
- **profile first**
- **fix Dart hot spots first**
- **use native code only for a proven image-processing bottleneck**

For now, a Rust/C refactor would be **premature**.
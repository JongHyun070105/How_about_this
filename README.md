# 이거어때?

## 개요

이거어때?는 이미지, 음식명, 별점을 입력받아 Gemini API(gemini-2.5-flash-lite)를 통해 음식 리뷰를 3개 생성하고, 사용자가 선택하여 복사할 수 있는 Flutter 애플리케이션입니다. 이 앱은 사용자에게 편리하고 다양한 리뷰 옵션을 제공하여 음식 리뷰 작성 과정을 간소화합니다.

## 주요 기능

- **이미지 업로드**: 음식 사진을 쉽게 업로드할 수 있습니다.
- **음식 정보 입력**: 음식사진과 별점을 입력하여 리뷰 생성의 기반을 마련합니다.
- **Gemini API 연동**: Gemini API를 활용하여 입력된 정보를 바탕으로 3가지의 독창적인 음식 리뷰를 생성합니다.
- **리뷰 선택 및 복사**: 생성된 리뷰 중 마음에 드는 것을 선택하여 간편하게 복사할 수 있습니다.
- **리뷰 기록**: 생성된 리뷰들을 기록하여 다시 볼 수 있습니다.

## 중점 사항

- **API 키 보안**: Gemini API 키를 안전하게 관리하고 보호합니다.
- **사용자 경험(UX)**: 직관적이고 사용하기 쉬운 인터페이스를 제공하여 최상의 사용자 경험을 보장합니다.
- **기술 스택**:
  - **프레임워크**: Flutter
  - **언어**: Dart
  - **AI 모델**: Google Gemini API (gemini-2.5-flash-lite)
  - **상태 관리**: Riverpod

## 시작하기

이 프로젝트를 로컬 환경에서 실행하고 개발하기 위한 가이드입니다.

### 1. 환경 설정

- Flutter SDK 설치 ([공식 문서](https://flutter.dev/docs/get-started/install))
- Android Studio 또는 VS Code (Flutter/Dart 플러그인 설치)
- `.env` 파일 설정 (프로젝트 루트에 `.env` 파일을 생성하고 `GEMINI_API_KEY` 및 `APP_ENVIRONMENT` 설정)

### 2. 의존성 설치

프로젝트 루트에서 다음 명령어를 실행하여 필요한 패키지를 설치합니다.

```bash
flutter pub get
```

### 3. iOS Pod 설치 (iOS 개발 시)

iOS 개발 환경에서는 추가적으로 CocoaPods 의존성을 설치해야 합니다.

```bash
cd ios
pod install
```

### 4. 앱 실행

시뮬레이터 또는 실제 기기에서 앱을 실행합니다.

```bash
flutter run
```

## 스토어 링크

앱이 각 스토어에 출시되면 여기에 링크가 추가될 예정입니다.

- **Google Play Store**: [링크 추가 예정]
- **Apple App Store**: [링크 추가 예정]

## 라이선스

MIT License

## 문의

궁금한 점이 있으시면 다음 이메일로 문의해주세요: [brian26492@gmail.com]

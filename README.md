# ReviewAI Flutter

## 개요
ReviewAI Flutter는 이미지, 음식명, 별점을 입력받아 Gemini API(gemini-2.5-flash)를 통해 음식 리뷰를 3개 생성하고, 사용자가 선택하여 복사할 수 있는 Flutter 애플리케이션입니다. 이 앱은 사용자에게 편리하고 다양한 리뷰 옵션을 제공하여 음식 리뷰 작성 과정을 간소화합니다.

## 주요 기능
- **이미지 업로드**: 음식 사진을 쉽게 업로드할 수 있습니다.
- **음식 정보 입력**: 음식명과 별점을 입력하여 리뷰 생성의 기반을 마련합니다.
- **Gemini API 연동**: Gemini API를 활용하여 입력된 정보를 바탕으로 3가지의 독창적인 음식 리뷰를 생성합니다.
- **리뷰 선택 및 복사**: 생성된 리뷰 중 마음에 드는 것을 선택하여 간편하게 복사할 수 있습니다.
- **리뷰 기록**: 생성된 리뷰들을 기록하여 다시 볼 수 있습니다.

## 기술 스택
- **프레임워크**: Flutter
- **언어**: Dart
- **AI 모델**: Google Gemini API (gemini-2.5-flash)
- **상태 관리**: Riverpod
- **UI/UX**: Figma 디자인 기반 (Material Design 원칙 준수)

## 시작하기

### 1. 개발 환경 설정
Flutter SDK가 설치되어 있는지 확인하고, 필요한 경우 [Flutter 공식 문서](https://flutter.dev/docs/get-started/install)를 참조하여 설치합니다.

### 2. 프로젝트 클론
```bash
git clone https://github.com/JongHyun070105/ReviewAI_Flutter.git
cd ReviewAI_Flutter
```

### 3. 종속성 설치
```bash
flutter pub get
```

### 4. Gemini API 키 설정
프로젝트 루트 디렉토리에 `.env` 파일을 생성하고, 다음과 같이 Gemini API 키를 추가합니다.
**주의**: `.env` 파일은 `.gitignore`에 추가되어 버전 관리에서 제외되도록 설정해야 합니다.

```
GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

### 5. 앱 실행
```bash
flutter run
```

## 프로젝트 구조
```
reviewai_flutter/
├── lib/
│   ├── config/             # 환경 설정 및 보안 관련 파일
│   ├── providers/          # 상태 관리 프로바이더 (Riverpod)
│   ├── screens/            # 각 화면 UI
│   ├── services/           # API 통신 및 비즈니스 로직
│   └── widgets/            # 재사용 가능한 UI 위젯
├── assets/
│   ├── fonts/              # 폰트 파일
│   └── images/             # 이미지 파일
└── ...
```

## 기여
기여를 환영합니다! 버그 리포트, 기능 제안 또는 풀 리퀘스트를 통해 프로젝트에 참여할 수 있습니다.

## 라이선스
이 프로젝트는 [MIT License](LICENSE)를 따릅니다. (라이선스 파일이 있다면 해당 파일에 대한 링크를 추가합니다.)

## 문의
궁금한 점이 있다면 [이메일](mailto:your-email@example.com)로 문의해주세요.
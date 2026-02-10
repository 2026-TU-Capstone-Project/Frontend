# 🧢 2026 TU Capstone Project - Virtual Fitting App (Try-On)

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Android Studio](https://img.shields.io/badge/Android%20Studio-3DDC84.svg?style=for-the-badge&logo=android-studio&logoColor=white)

## 🛠 Tech Stack

| Category | Technology | Description |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.x | Cross-platform UI Toolkit |
| **Language** | Dart 3.x | Main Programming Language |
| **State Management** | Riverpod | 상태 관리 (MVVM 패턴 적용) |
| **Network** | Dio + Retrofit | REST API 통신 및 데이터 매핑 |
| **Local Storage** | FlutterSecureStorage | 액세스 토큰 및 민감 데이터 저장 |

<br>

## 🚀 Getting Started (Android Guide)

이 프로젝트를 **Android 환경**에서 실행하기 위한 상세 가이드입니다.
Flutter 환경 설정이 처음이라면 **1. 사전 준비 사항**부터 차근차근 진행해 주세요.

### 1. Prerequisites (사전 준비 사항)
앱을 실행하기 위해 다음 도구들이 설치되어 있어야 합니다.

1.  **Flutter SDK 설치**: [공식 가이드](https://docs.flutter.dev/get-started/install/windows/mobile)를 참고하여 설치 및 환경 변수(PATH)를 설정합니다.
2.  **Android Studio 설치**: 안드로이드 에뮬레이터 구동을 위해 필요합니다.
    * 설치 시 `Android SDK`, `Android SDK Platform-Tools`, `Android Virtual Device` 항목을 체크해주세요.
3.  **Flutter Plugin 설치**: Android Studio > Settings > Plugins 에서 `Flutter`와 `Dart` 플러그인을 설치하고 IDE를 재시작합니다.

설치가 완료되면 터미널(CMD/PowerShell)에서 다음 명령어로 상태를 확인합니다.
```bash
flutter doctor
# 모든 항목에 체크(v)가 되어 있어야 정상입니다.
# [!] 표시가 있다면 해당 에러 메시지의 가이드를 따라 해결해주세요.

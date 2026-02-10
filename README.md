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
```
## 2. Installation (프로젝트 설치)

### Step 1. 프로젝트 복제 (Clone)

```Bash
git clone [https://github.com/2026-TU-Capstone-Project/Frontend.git](https://github.com/2026-TU-Capstone-Project/Frontend.git)
cd Frontend
```

### Step 2. 라이브러리 설치 (Dependencies) 프로젝트에 필요한 패키지들을 다운로드합니다.

```Bash
flutter pub get
```

### Step 3. 코드 생성 (Code Generation) ⭐ 중요 이 프로젝트는 Retrofit과 JsonSerializable을 사용합니다. 모델 변경 사항을 반영하고 .g.dart 파일을 생성하기 위해 반드시 아래 명령어를 실행해야 합니다.

```Bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run APP (앱 실행)
```
Option A. 에뮬레이터(Emulator) 실행

Android Studio > Device Manager 실행.

Create Device > 원하는 기기(예: Pixel 7) 선택 > 시스템 이미지 다운로드(API 33 이상 권장) > 생성.

재생 버튼(▶)을 눌러 에뮬레이터를 켭니다.
```
```
Option B. 실물 기기(Physical Device) 연결

안드로이드 폰 설정 > 휴대전화 정보 > 빌드 번호 7번 터치 (개발자 모드 활성화).

설정 > 개발자 옵션 > USB 디버깅 켜기.

PC와 USB 케이블로 연결합니다.

Command (터미널에서 실행) 기기가 연결된 상태에서 아래 명령어를 입력하세요.
```
```Bash
# Debug Mode
flutter run

# Release Mode
flutter run --release
```

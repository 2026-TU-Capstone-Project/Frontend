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

2. Installation (프로젝트 설치)
Step 1. 프로젝트 복제 (Clone)

Bash
git clone [https://github.com/2026-TU-Capstone-Project/Frontend.git](https://github.com/2026-TU-Capstone-Project/Frontend.git)
cd Frontend
Step 2. 라이브러리 설치 (Dependencies) 프로젝트에 필요한 패키지들을 다운로드합니다.

Bash
flutter pub get
Step 3. 코드 생성 (Code Generation) ⭐ 중요 이 프로젝트는 Retrofit과 JsonSerializable을 사용합니다. 모델 변경 사항을 반영하고 .g.dart 파일을 생성하기 위해 반드시 아래 명령어를 실행해야 합니다.

Bash
flutter pub run build_runner build --delete-conflicting-outputs
3. Run APP (앱 실행)
Option A. 에뮬레이터(Emulator) 실행

Android Studio > Device Manager 실행.

Create Device > 원하는 기기(예: Pixel 7) 선택 > 시스템 이미지 다운로드(API 33 이상 권장) > 생성.

재생 버튼(▶)을 눌러 에뮬레이터를 켭니다.

Option B. 실물 기기(Physical Device) 연결

안드로이드 폰 설정 > 휴대전화 정보 > 빌드 번호 7번 터치 (개발자 모드 활성화).

설정 > 개발자 옵션 > USB 디버깅 켜기.

PC와 USB 케이블로 연결합니다.

Command (터미널에서 실행) 기기가 연결된 상태에서 아래 명령어를 입력하세요.

Bash
# Debug Mode (개발용 - Hot Reload 지원)
flutter run

# Release Mode (최적화 버전 - 속도 확인용)
flutter run --release
4. Project Structure
프로젝트의 폴더 구조입니다. (Last Update: 02/10)

Bash
lib/
├── 📂 common/                  # [공통] 앱 전반 재사용 코드
│   ├── 📂 const/
│   │   ├── colors.dart         # 앱 메인 색상 정의
│   │   └── data.dart           # 상수 데이터 (API URL, 토큰 등)
│   ├── 📂 layout/
│   │   └── default_layout.dart # 모든 화면 기본 레이아웃 (Scaffold)
│   └── 📂 view/
│       └── root_tab.dart       # 하단 탭바(BottomNavigation) 관리
│
├── 📂 feed/                    # [기능] 패션 피드
│   ├── 📂 component/
│   │   └── feed_card.dart      # 피드 리스트 아이템 UI
│   ├── 📂 model/
│   │   └── feed_model.dart     # 피드 데이터 모델
│   └── 📂 view/
│       ├── fashion_feed_screen.dart  # 피드 메인 리스트 화면
│       └── feed_detail_screen.dart   # 피드 상세 화면
│
├── 📂 fitting/                 # [기능] 가상 피팅룸
│   ├── 📂 clothes/             # (하위기능) 옷 데이터 관리
│   │   ├── 📂 model/
│   │   │   ├── clothes_model.dart    # 옷 정보 모델
│   │   │   └── clothes_model.g.dart  # [Auto Generated] 모델 생성 코드
│   │   └── 📂 repository/
│   │       ├── clothes_repository.dart    # 옷 데이터 API 통신
│   │       └── clothes_repository.g.dart  # [Auto Generated] API 통신 코드
│   ├── 📂 component/
│   │   ├── add_clothing_sheet.dart        # 옷 추가 바텀시트
│   │   ├── ai_stylist_input.dart          # AI 스타일링 입력창
│   │   ├── fitting_main_stage.dart        # 아바타 합성 뷰 영역
│   │   ├── fitting_onboarding_sheet.dart  # 피팅룸 사용 가이드
│   │   ├── fitting_room_header.dart       # 피팅룸 상단 헤더
│   │   └── wardrobe_section.dart          # 하단 옷 선택 리스트
│   ├── 📂 model/
│   │   ├── fitting_model.dart       # 피팅 로직 모델
│   │   └── fitting_model.g.dart     # [Auto Generated]
│   ├── 📂 repository/
│   │   ├── fitting_repository.dart   # 피팅 기능 API 통신
│   │   └── fitting_repository.g.dart # [Auto Generated]
│   ├── 📂 theme/
│   │   └── fitting_room_theme.dart   # 피팅룸 전용 테마/스타일
│   └── 📂 view/
│       └── fitting_room_screen.dart  # 피팅룸 메인 화면
│
├── 📂 home/                    # [기능] 홈 화면
│   ├── 📂 component/
│   │   ├── category_selector.dart    # 상단 카테고리 선택 버튼
│   │   ├── single_feed_card.dart     # 홈 전용 피드 카드
│   │   └── weather_card.dart         # 날씨 정보 위젯
│   └── 📂 view/
│       └── home_screen.dart          # 홈 메인 화면
│
├── 📂 personal_closet/         # [기능] 나만의 옷장
│   ├── 📂 component/
│   │   ├── category_filter_bar.dart  # 옷 종류 필터 (상의/하의 등)
│   │   └── wardrobe_card.dart        # 옷 아이템 카드 UI
│   └── 📂 view/
│       └── wardrobe_screen.dart      # 옷장 메인 화면
│
├── 📂 user/                    # [기능] 회원 관리
│   ├── 📂 component/
│   │   └── social_login_button.dart  # 소셜 로그인 버튼
│   └── 📂 view/
│       ├── login_screen.dart   # 로그인 화면
│       └── splash_screen.dart  # 앱 시작 로딩 화면
│
└── 📄 main.dart                # 앱 진입점
❓ Troubleshooting
Q. Target not found 또는 No connected devices 에러가 발생해요.

에뮬레이터가 켜져 있는지, 또는 실물 기기가 USB로 잘 연결되어 있는지 확인해주세요.

터미널에 flutter devices를 입력하여 연결된 기기 목록을 확인할 수 있습니다.

Q. .g.dart 파일이 없어서 빨간 줄(Error)이 많이 떠요.

터미널에서 flutter pub run build_runner build --delete-conflicting-outputs 명령어를 실행하여 코드를 생성해주세요.

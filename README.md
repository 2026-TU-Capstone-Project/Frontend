#  2026 TU Capstone Project - FE

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Android Studio](https://img.shields.io/badge/Android%20Studio-3DDC84.svg?style=for-the-badge&logo=android-studio&logoColor=white)

## 🛠 Tech Stack

| Category | Technology | Description |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.x | Cross-platform UI Toolkit |
| **Language** | Dart 3.x | |
| **State Management** | [Provider / Riverpod / GetX] | 상태 관리 패턴 (수정 필요) |
| **Network** | Dio | HTTP Client |
| **Local Storage** | [FlutterSecureStorage / Hive] | 토큰 및 로컬 데이터 저장 |

<br>


## 🚀 Getting Started

이 프로젝트를 로컬 환경에서 실행하기 위한 가이드입니다.

### 1. Installation
프로젝트를 Clone 하고 의존성 패키지를 설치합니다.

```bash
# 1. Clone Repository
git clone [https://github.com/2026-TU-Capstone-Project/Frontend.git](https://github.com/2026-TU-Capstone-Project/Frontend.git)

# 2. Navigate to directory
cd Frontend

# 3. Install Dependencies
flutter pub get
```

### 2. Run APP 

```bash
# Debug Mode
flutter run

# Release Mode
flutter run --release
```


### 3.Project Structure
폴더구조 입니다 지속적으로 업데이트 합니다 : last update (01/25)
```bash
lib/
├── 📂 common/                  # 공통 기능
│   ├── 📂 const/
│   │   ├── colors.dart         # 색상 상수
│   │   └── data.dart           # 데이터 상수
│   ├── 📂 layout/
│   │   └── default_layout.dart # 기본 레이아웃
│   └── 📂 view/
│       └── root_tab.dart       # 하단 탭
│
├── 📂 fitting/                 # [Feature] 가상 피팅룸
│   ├── 📂 component/           # 피팅룸 전용 컴포넌트
│   │   ├── add_clothing_sheet.dart
│   │   ├── ai_stylist_input.dart
│   │   ├── fitting_main_stage.dart
│   │   ├── fitting_onboarding_sheet.dart
│   │   ├── fitting_room_header.dart
│   │   └── wardrobe_section.dart
│   ├── 📂 theme/
│   │   └── fitting_room_theme.dart
│   └── 📂 view/
│       └── fitting_room_screen.dart
│
├── 📂 home/                    # [Feature] 홈 피드
│   ├── 📂 component/
│   │   ├── category_selector.dart
│   │   ├── single_feedCard.dart
│   │   └── weather_card.dart
│   └── 📂 view/
│       └── home_screen.dart
│
├── 📂 user/                    # [Feature] 회원 관리
│   ├── 📂 component/
│   │   └── social_login_button.dart
│   └── 📂 view/
│       ├── login_screen.dart
│       └── splash_screen.dart
│
└── 📄 main.dart                # Entry Point
```



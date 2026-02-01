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
폴더구조 입니다 지속적으로 업데이트 합니다 : last update (01/29)
```bash
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
│   │   │   └── clothes_model.g.dart  # 모델 생성 코드 (JsonSerializable)
│   │   └── 📂 repository/
│   │       ├── clothes_repository.dart   # 옷 데이터 API 통신
│   │       └── clothes_repository.g.dart # API 생성 코드 (Retrofit)
│   ├── 📂 component/
│   │   ├── add_clothing_sheet.dart       # 옷 추가 바텀시트
│   │   ├── ai_stylist_input.dart         # AI 스타일링 입력창
│   │   ├── fitting_main_stage.dart       # 아바타 합성 뷰 영역
│   │   ├── fitting_onboarding_sheet.dart # 피팅룸 사용 가이드
│   │   ├── fitting_room_header.dart      # 피팅룸 상단 헤더
│   │   └── wardrobe_section.dart         # 하단 옷 선택 리스트
│   ├── 📂 model/
│   │   ├── fitting_model.dart      # 피팅 로직 모델
│   │   └── fitting_model.g.dart
│   ├── 📂 repository/
│   │   ├── fitting_repository.dart   # 피팅 기능 API 통신
│   │   └── fitting_repository.g.dart
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
```



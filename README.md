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
폴더구조 입니다 지속적으로 업데이트 합니다 : last update (02/09)
```bash
lib/
├── 📂 common/                  # [공통] 앱 전반 재사용 코드
│   ├── 📂 const/
│   │   ├── 📂 Component/       # 공통 UI 컴포넌트 상수/위젯
│   │   │   └── custom_text_form_field.dart # 커스텀 텍스트 입력 필드
│   │   ├── colors.dart         # 앱 메인 색상 정의
│   │   └── data.dart           # 상수 데이터 (API URL, 토큰 등)
│   ├── 📂 layout/
│   │   └── default_layout.dart # 모든 화면 기본 레이아웃 (Scaffold)
│   ├── 📂 model/               #  공통 데이터 모델
│   │   ├── api_response.dart   #  API 공통 응답 래퍼 (status, message, data)
│   │   └── api_response.g.dart
│   └── 📂 view/
│       └── root_tab.dart       # 하단 탭바(BottomNavigation) 관리
│
├── 📂 feed/                    # [기능] 패션 피드
│   ├── 📂 component/
│   │   └── feed_card.dart
│   ├── 📂 model/
│   │   └── feed_model.dart
│   └── 📂 view/
│       ├── fashion_feed_screen.dart
│       └── feed_detail_screen.dart
│
├── 📂 fitting/                 # [기능] 가상 피팅룸
│   ├── 📂 clothes/             # (하위기능) 옷 데이터 관리
│   │   ├── 📂 model/
│   │   │   ├── clothes_model.dart
│   │   │   ├── clothes_model.g.dart
│   │   │   ├── recommend_model.dart    #  AI 추천 결과 모델
│   │   │   └── recommend_model.g.dart
│   │   └── 📂 repository/
│   │       ├── clothes_client.dart     # Retrofit API 정의 인터페이스
│   │       ├── clothes_client.g.dart
│   │       ├── clothes_repository.dart # 옷 데이터 비즈니스 로직
│   │       └── clothes_repository.g.dart
│   ├── 📂 component/
│   │   ├── add_clothing_sheet.dart
│   │   ├── ai_stylist_input.dart
│   │   ├── fitting_main_stage.dart
│   │   ├── fitting_onboarding_sheet.dart
│   │   ├── fitting_room_header.dart
│   │   └── wardrobe_section.dart
│   ├── 📂 model/
│   │   ├── fitting_model.dart
│   │   └── fitting_model.g.dart
│   ├── 📂 repository/
│   │   ├── fitting_repository.dart
│   │   └── fitting_repository.g.dart
│   ├── 📂 theme/
│   │   └── fitting_room_theme.dart
│   └── 📂 view/
│       └── fitting_room_screen.dart
│
├── 📂 home/                    # [기능] 홈 화면
│   ├── 📂 component/
│   │   ├── category_selector.dart
│   │   ├── single_feed_card.dart
│   │   └── weather_card.dart
│   └── 📂 view/
│       └── home_screen.dart
│
├── 📂 personal_closet/         # [기능] 나만의 옷장
│   ├── 📂 component/
│   │   ├── category_filter_bar.dart
│   │   └── wardrobe_card.dart
│   └── 📂 view/
│       └── wardrobe_screen.dart
│
├── 📂 user/                    # [기능] 회원 관리
│   ├── 📂 component/
│   │   └── social_login_button.dart
│   ├── 📂 model/
│   │   ├── auth_model.dart     #  로그인/회원가입 요청/응답 모델
│   │   └── auth_model.g.dart
│   ├── 📂 repository/          # 인증 관련 통신 계층
│   │   ├── auth_client.dart    #  Auth API 정의 (Retrofit)
│   │   ├── auth_client.g.dart
│   │   └── auth_repository.dart #  인증 저장소 (토큰 관리 등)
│   └── 📂 view/
│       ├── login_screen.dart
│       ├── signup_screen.dart  #  회원가입 화면
│       └── splash_screen.dart
│
└── 📄 main.dart                # 앱 진입점
```



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
## 4. Project Structure
프로젝트의 현재 폴더 구조입니다. (Last Update: 04/05)
```bash
lib/
├── 📂 chat/                           # [기능] AI 채팅·검색
│   ├── 📂 model/
│   │   ├── chat_model.dart            # 채팅 메시지 모델 (Weather & History 연동)
│   │   └── chat_model.g.dart          # [Generated]
│   ├── 📂 provider/
│   │   └── chat_provider.dart         # 채팅 상태 관리 (날씨 조회 및 Context 유지)
│   ├── 📂 repository/
│   │   ├── chat_repository.dart       # 채팅 API
│   │   └── chat_repository.g.dart     # [Generated]
│   └── 📂 view/
│       ├── ai_chat_screen.dart        # AI 채팅 화면
│       └── ai_search_screen.dart      # AI 검색 화면
│
├── 📂 common/                         # [공통] 앱 전반 재사용 코드
│   ├── 📂 camera/
│   │   └── photo_guide_screen.dart    # 촬영 가이드 (전신·상반신)
│   ├── 📂 component/
│   │   └── style_analysis_widget.dart # 스타일 분석 위젯
│   ├── 📂 const/
│   │   ├── 📂 Component/
│   │   │   └── custom_text_form_field.dart
│   │   ├── colors.dart                # 앱 메인 색상 정의
│   │   └── data.dart                  # 상수 데이터 (API URL 등)
│   ├── 📂 layout/
│   │   └── default_layout.dart        # 기본 레이아웃
│   ├── 📂 model/
│   │   ├── api_response.dart          # API 공통 응답 모델
│   │   └── api_response.g.dart        # [Generated]
│   ├── 📂 network/
│   │   └── auth_dio.dart              # Bearer 토큰 + 401 갱신 Dio
│   ├── 📂 provider/
│   │   └── dio_provider.dart          # Dio 인스턴스 프로바이더
│   ├── 📂 view/
│   │   └── root_tab.dart              # 하단 탭바
│   ├── 📂 widget/
│   │   └── app_dialog.dart            # 공통 다이얼로그 유틸
│   └── app_router.dart                # 전역 Navigator 키
│
├── 📂 feed/                           # [기능] 패션 피드
│   ├── 📂 component/
│   │   └── feed_detail_sheet.dart     # 피드 상세 바텀시트
│   ├── 📂 model/
│   │   ├── feed_model.dart            # 피드 데이터 모델
│   │   └── feed_model.g.dart          # [Generated]
│   ├── 📂 provider/
│   │   └── feed_provider.dart         # 피드 상태 관리
│   ├── 📂 repository/
│   │   ├── feed_repository.dart       # 피드 API
│   │   └── feed_repository.g.dart     # [Generated]
│   └── 📂 view/
│       ├── fashion_feed_screen.dart   # 피드 메인 리스트
│       ├── feed_detail_screen.dart    # 피드 상세
│       ├── feed_write_screen.dart     # 피드 작성
│       └── my_feed_list_screen.dart   # 내 피드 목록
│
├── 📂 fitting/                        # [기능] 가상 피팅룸
│   ├── 📂 clothes/                    # 옷 데이터·추천
│   │   ├── 📂 model/
│   │   │   ├── clothes_model.dart
│   │   │   ├── recommend_model.dart
│   │   │   └── weather_recommend_model.dart
│   │   ├── 📂 provider/
│   │   │   ├── clothes_provider.dart
│   │   │   └── recommend_provider.dart
│   │   └── 📂 repository/
│   │       ├── clothes_repository.dart
│   │       └── recommend_repository.dart
│   ├── 📂 clothes_set/                # 코디 폴더 (착장 저장)
│   ├── 📂 component/
│   │   ├── fit_type_selector.dart      # 핏감 카드 셀렉터
│   │   ├── fitting_main_stage.dart     # 전신·상하의 선택 뷰
│   │   └── fitting_room_header.dart    # 피팅룸 상단 헤더
│   ├── 📂 model/
│   │   ├── fit_type.dart              # 핏감 enum (SLIM, REGULAR, OVERSIZED)
│   │   └── fitting_model.dart         # 피팅 결과 모델
│   ├── 📂 provider/
│   │   └── fitting_provider.dart      # 피팅 상태 관리
│   ├── 📂 repository/
│   │   ├── fitting_repository.dart    # 피팅 API (SSE, fit_type 포함)
│   │   └── weather_recommendation_repository.dart
│   ├── 📂 util/
│   │   ├── clothes_category_util.dart
│   │   └── weather_util.dart          # OpenWeatherMap 날씨 파싱
│   └── 📂 view/
│       ├── fitting_room_screen.dart   # 피팅룸 메인 화면
│       └── weather_recommendation_screen.dart
│
├── 📂 home/                           # [기능] 홈 화면
│   ├── 📂 component/
│   │   └── weather_card.dart          # 날씨 카드 위젯
│   └── 📂 view/
│       ├── home_screen.dart           # 홈 메인 화면
│       └── weather_style_screen.dart  # 날씨별 스타일 화면
│
├── 📂 personal_closet/                # [기능] 나만의 옷장
│   └── 📂 view/
│       ├── clothes_set_list_screen.dart
│       └── wardrobe_screen.dart        # 옷장 메인
│
├── 📂 user/                           # [기능] 회원·인증·프로필
│   ├── 📂 model/
│   │   └── auth_model.dart
│   └── 📂 view/
│       ├── login_screen.dart
│       └── user_profile_screen.dart
│
└── main.dart                          # 앱 진입점 (MaterialApp)
```

## ✨ Latest Core Feature Updates

*   **Virtual Fitting API Synchronization**:
    *   가상 피팅 메인 모델 이미지 로딩 로직을 로컬 캐시에서 서버 프로필 기반 우선 호출(Single Source of Truth) 방식으로 완벽히 통합했습니다.
    *   신규 API 명세에 맞춰 가상 피팅 요청 시 `fit_type` (SLIM_FIT, REGULAR_FIT, OVERSIZED_FIT) 파라미터를 지원합니다.
*   **Weather-based Style Recommendation**:
    *   `OpenWeatherMap` GPS 기반 날씨 호출 로직을 개선하여, 백엔드가 요구하는 강수량(`rain`), 적설량(`snow`), 풍속(`windSpeed`), 습도(`humidity`) 파라미터를 모두 성공적으로 파싱하고 API(`/api/v1/virtual-fitting/recommendation/weather-style`)를 GET에서 POST 방식으로 규격화했습니다.
*   **AI Stylist Chatbot (Gemini)**:
    *   AI 챗봇 통신 시 프론트엔드에서 현재 날씨 데이터를 래핑하여 백그라운드 전송하도록 개선했습니다.
    *   챗봇 대화 간의 문맥 유지를 위해 이전 대화 내역(`history`)을 `assistant` 와 `user` Role로 치환하여 발송하는 등 기능적 완성도를 극대화했습니다.


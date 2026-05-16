# FE - BE API 스펙 불일치 및 구조적 문제점 정리

본 문서는 `api.json` 스펙과 현재 Frontend(Flutter) 코드 간의 크로스 체크 결과를 정리한 내용입니다. 향후 유지보수 및 리팩토링의 기준 자료로 활용됩니다.

## 1) 스펙에 있는데 FE에 미구현된 호출
| Endpoint | 상태 | 영향 |
|---|---|---|
| `POST /api/v1/virtual-fitting/style-photo` | 완전 미구현 | "스타일 사진 기반 피팅" 기능 자체가 빠져 있음. FittingRepository에 메서드가 없음. |
| `GET /api/favorites/feeds/me` | 완전 미구현 | 즐겨찾기 피드 목록 화면 없음. (좋아요 `/feeds/{id}/like`와 별개 기능) |
| `POST /api/favorites/feeds/{feedId}` | 완전 미구현 | 즐겨찾기 토글 호출 없음. FE는 toggleLike만 사용 중. |
| `GET /api/v1/users/search` | Repository만 있고 호출처 없음 | UserRepository.search가 정의돼 있지만 어떤 화면에서도 호출하지 않음 → 유저 검색 UI 미구현. |
| `GET /api/v1/follows/{userId}/followings` | Repository만 있고 호출처 없음 | 다른 유저 프로필에서 그 유저의 팔로잉 보기 미구현. 프로필 화면은 카운트만 표시. |
| `GET /api/v1/follows/{userId}/followers` | Repository만 있고 호출처 없음 | 다른 유저의 팔로워 목록 보기 미구현. |

## 2) FE에서 호출하지만 스펙에 없는 endpoint (404/500 위험)
| FE 호출 | 위치 | 문제 |
|---|---|---|
| `POST /api/v1/clothes/analysis` | clothes_repository.dart:44 | api.json에 존재하지 않음. 사용처 없으면 데드 코드. |1
| `GET /api/v1/virtual-fitting/recommendation/style` | recommend_repository.dart:16 | api.json에 없음. weather-style 만 존재. |
| `POST /api/v1/auth/token/exchange` | auth_client.dart:29 | api.json에 없음. Native SDK 로그인이 표준이므로 이 redirect 경로는 더 이상 필요 없을 수도. |

## 3) 스펙과 시그니처 불일치 (보이지 않게 망가지는 호출)
*   **3-1. 가상 피팅 요청 — 단일 fit_type만 보냄**
    *   스펙: `top_fit_type`, `bottom_fit_type` 두 개.
    *   FE: `fitting_repository.dart`에서 `@Query("fit_type")` 하나만 전송. → 서버는 둘 다 default로 처리하여 사용자 선택 무시됨.
*   **3-2. 날씨 기반 추천 — HTTP 메서드 불일치**
    *   스펙: `GET /api/v1/virtual-fitting/recommendation/weather-style`
    *   FE: `recommend_repository.dart`에서 `@POST`로 호출. → 405 Method Not Allowed 발생 가능.
*   **3-3. 피드 생성 — 스펙에 없는 visibility 필드**
    *   스펙: `fittingTaskId`, `feedTitle`, `feedContent`
    *   FE: `feed_repository.dart`에서 `visibility: 'PUBLIC'` 항상 포함. → "팔로워 공개" 기능 오작동 및 400 에러 위험.
*   **3-4. 마이프로필 생성/수정 — username/nickname 누락**
    *   스펙: `username`, `nickname`, `height`, `weight`, `gender` 모두 query.
    *   FE: `submitOnboardingProfile` 호출 시 `username/nickname` 누락.
*   **3-5. PATCH /users/me — query vs form 혼동**
    *   스펙: 모든 필드가 query parameter.
    *   FE: multipart 본문에 보냄. (서버 구현에 따라 동작할 수도 있으나 스펙 불일치)

## 4) 구조적 / 성능 비효율
*   **4-1. userFeedsProvider — 결정적 누락**: 전체 피드 첫 페이지에서 닉네임으로 필터링 중. 2페이지 이후의 피드는 영구 누락됨. BE에 특정 유저 피드 조회 API 요청 필요.
*   **4-2. 팔로우 요청 30초 폴링**: 앱 백그라운드 여부와 상관없이 무조건 30초마다 호출.
*   **4-3. 팔로워/팔로잉 목록 무한스크롤 미사용**: 스펙은 cursor 페이지네이션을 지원하나 FE는 1회(20명) 호출에 그침.
*   **4-4. SSE를 raw HttpClient로 직접 구현**: Dio 인터셉터 우회로 인해 토큰 만료 시 401 에러 후 폴링으로 넘어감.
*   **4-5. 옷 등록 SSE 실패 → 무조건 성공 처리**: 타임아웃/끊김 시 성공으로 간주하여 사용자 혼란 유발.
*   **4-6. 피팅 결과 폴링 5분 / 백오프 없음**: 고정 2초 간격 150회 폴링.
*   **4-7. getMe 에러 모두 swallow → null**: 토큰 만료와 진짜 에러 구분 불가.
*   **4-8. RecommendRepository baseUrl 하드코딩 + 중복**: `https://$ip` 하드코딩 및 weather-style 중복 정의.
*   **4-9. AuthRepository._withUnwrap 인터셉터 중복 등록 위험**: 생성자에서 dio에 인터셉터 추가.
*   **4-10. _weatherCache 모듈 전역**: Riverpod 외부 상태로 관리되어 테스트 및 리셋 어려움.
*   **4-11. follow refresh 정책 불일치**: 화면 깜빡임 유발 (`AsyncLoading` 남용).
*   **4-12. 무페이지네이션 엔드포인트들**: 리스트가 길어질 경우 대비 BE에 cursor/page 도입 요청 필요.

## 5) 데드 코드 / 정리 필요
*   `clothes_repository.dart`의 `uploadAnalysisCloth`
*   `recommend_repository.dart`의 `getRecommendations`
*   `auth_client.dart`의 `exchangeTempKey`

## 우선순위 제안 (영향도 × 작업량)
1.  **즉시 (버그)**: 3-1, 3-2, 3-3, 4-5
2.  **단기 (누락 기능)**: 1-1, 1-4, 1-5, 1-6, 4-3
3.  **중기 (구조)**: 4-1, 4-4, 4-7
4.  **정리 (데드코드)**: 5번 항목, 리포지토리 통합
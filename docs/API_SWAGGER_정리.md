# Capstone Project API – Swagger 정리

- **Base**: 상대 경로 `/` 또는 `http://localhost:80`, `http://localhost:8080`
- **인증**: `/api/v1/auth/*` 제외한 모든 API → `Authorization: Bearer {accessToken}` 필수

---

## 1. Auth (인증)

| 메서드 | 경로 | 설명 | 인증 | 요청 Body | 비고 |
|--------|------|------|------|-----------|------|
| POST | `/api/v1/auth/login` | 일반 로그인 | X | `LoginDto`: `email`, `password` | 200: `accessToken`, `refreshToken`, message, email |
| POST | `/api/v1/auth/signup` | 회원가입 | X | `SignupDto`: `email`, `password` 필수 / `username`, `nickname` 선택 | 200: 문자열 |
| POST | `/api/v1/auth/logout` | 로그아웃 | X | `RefreshTokenRequestDto`: `refreshToken` | Redis refreshToken 삭제 |
| POST | `/api/v1/auth/token/refresh` | 토큰 갱신 | X | `RefreshTokenRequestDto`: `refreshToken` | 200: 새 accessToken, refreshToken / 401: 만료·무효 |
| POST | `/api/v1/auth/google` | Google 로그인 (Native SDK) | X | `GoogleLoginRequestDto`: `idToken` | 서버 검증 후 accessToken·refreshToken 발급 |
| POST | `/api/v1/auth/kakao` | Kakao 로그인 (Native SDK) | X | `KakaoLoginRequestDto`: `accessToken` | 서버 검증 후 accessToken·refreshToken 발급 |

**공통 DTO**
- `LoginDto`: `email`, `password`
- `SignupDto`: `username?`, `email`, `password`, `nickname?`
- `RefreshTokenRequestDto`: `refreshToken`
- `GoogleLoginRequestDto`: `idToken`
- `KakaoLoginRequestDto`: `accessToken`

---

## 2. Virtual Fitting (가상 피팅)

| 메서드 | 경로 | 설명 | 인증 | 요청 | 비고 |
|--------|------|------|------|------|------|
| POST | `/api/v1/virtual-fitting` | 가상 피팅 요청 | O | `multipart/form-data`: `user_image`, `top_image` 필수, `bottom_image` 선택 | 비동기 → 200에 `taskId` 반환, 이후 status 폴링 |
| GET | `/api/v1/virtual-fitting/{taskId}/status` | 피팅 작업 상태 조회 | O | path: `taskId` | `status`: WAITING, PROCESSING, COMPLETED, FAILED / 완료 시 `resultImgUrl` |
| DELETE | `/api/v1/virtual-fitting/{taskId}` | 피팅 결과 삭제(닫기) | O | path: `taskId` | 본인 소유만 |
| PATCH | `/api/v1/virtual-fitting/{taskId}` | 피팅 결과 옷장 저장 | O | path: `taskId` | 저장하기 버튼 |
| GET | `/api/v1/virtual-fitting/recommendation/style` | 스타일 추천 | O | query: `query` (자연어) | 유사도 0.7 이상, 최대 10개 |
| GET | `/api/v1/virtual-fitting/my-closet` | 내가 저장한 코디 목록 | O | - | 저장한 가상 피팅 결과 목록 |

**응답 스키마**
- 피팅 요청: `ApiResponseVirtualFittingTaskIdResponse` → `data.taskId`
- 상태: `VirtualFittingStatusResponse` → `taskId`, `status`, `resultImgUrl`
- 스타일 추천: `StyleRecommendationResponse` → `recommendations[]` (taskId, score, resultImgUrl, styleAnalysis, topId, bottomId)
- 내 코디: `ApiResponseListSavedFittingResponseDto` → `data[]` (SavedFittingResponseDto)

---

## 3. Clothes (옷)

| 메서드 | 경로 | 설명 | 인증 | 요청 | 비고 |
|--------|------|------|------|------|------|
| GET | `/api/v1/clothes` | 내 옷장 목록 | O | query: `category?` (전체/Top/Bottom/Shoes) | 최신순 |
| POST | `/api/v1/clothes` | 옷 등록 | O | query: `category` (Top/Bottom/Shoes), body: `multipart` `file` | 비동기 202 → 백그라운드 분석·저장 |
| GET | `/api/v1/clothes/{id}` | 옷 상세 | O | path: `id` | ClothesResponseDto |
| DELETE | `/api/v1/clothes/{id}` | 옷 삭제 | O | path: `id` | 본인 소유만 |

**ClothesResponseDto**  
id, category, name, imgUrl, color, season, material, thickness, neckLine, sleeveType, pattern, closure, style, fit, length, texture, detail, occasion, brand, price, buyUrl, createdAt

---

## 4. Clothes Set API (코디 폴더)

| 메서드 | 경로 | 설명 | 인증 | 요청 | 비고 |
|--------|------|------|------|------|------|
| GET | `/api/v1/clothes-sets` | 내 폴더 목록 | O | - | 폴더 + 대표 이미지 |
| POST | `/api/v1/clothes-sets/save` | 코디 저장 | O | `SaveRequest`: `setName`, `clothesIds[]`, `fittingTaskId` | 새 폴더 생성 후 저장 |
| PATCH | `/api/v1/clothes-sets/{id}` | 폴더 이름 수정 | O | path: `id`, body: `UpdateRequest` (`newName`) | |
| DELETE | `/api/v1/clothes-sets/{id}` | 폴더 전체 삭제 | O | path: `id` | 폴더+내용 삭제 |
| DELETE | `/api/v1/clothes-sets/fitting/{fittingTaskId}` | 착장 개별 삭제 | O | path: `fittingTaskId` | 폴더 내 특정 피팅 결과만 삭제 |

**응답**
- 폴더 목록: `ClothesSetResponseDto[]` → id, setName, representativeImageUrl, fittingTasks[], clothes[]

---

## 5. 공통 응답 래퍼

대부분 응답이 아래 형태입니다.

```json
{
  "success": true,
  "message": "조회 성공",
  "data": { ... }
}
```

- 실패 시 `success: false`, `data`는 null일 수 있음.
- 단순 메시지/문자열 응답은 `data`가 string이거나 body가 문자열인 경우 있음 (예: signup 200).

---

## 6. 플러터 연동 체크리스트

- [ ] Auth: login, signup, logout, token/refresh, (선택) google, kakao
- [ ] 인증 필요 API: Dio 인터셉터 등으로 `Authorization: Bearer {accessToken}` 자동 부착
- [ ] access 만료 시: 401 수신 시 refresh 호출 후 재시도
- [ ] Virtual Fitting: multipart 업로드, taskId로 status 폴링, 결과 이미지 표시
- [ ] Clothes: 목록/상세/등록/삭제, category 쿼리
- [ ] Clothes Set: 폴더 목록, 저장, 이름 수정, 폴더/착장 삭제

---

## 7. 미구현 API 조회 (Swagger 대비)

### ✅ 구현됨

| 구분 | 메서드 | 경로 | 비고 |
|------|--------|------|------|
| Auth | POST | `/api/v1/auth/login` | |
| Auth | POST | `/api/v1/auth/signup` | |
| Auth | POST | `/api/v1/auth/logout` | |
| Auth | POST | `/api/v1/auth/token/refresh` | |
| Auth | POST | `/api/v1/auth/token/exchange` | 소셜 OAuth2 임시키 |
| Auth | POST | `/api/v1/auth/google` | |
| Auth | POST | `/api/v1/auth/kakao` | |
| Virtual Fitting | POST | `/api/v1/virtual-fitting` | `FittingRepository.requestFitting` |
| Virtual Fitting | GET | `/api/v1/virtual-fitting/{taskId}/status` | `FittingRepository.checkStatus` |
| Virtual Fitting | DELETE | `/api/v1/virtual-fitting/{taskId}` | `FittingRepository.deleteFittingResult` (닫기) |
| Virtual Fitting | PATCH | `/api/v1/virtual-fitting/{taskId}` | `FittingRepository.saveFittingToWardrobe` (저장하기) |
| Virtual Fitting | GET | `/api/v1/virtual-fitting/recommendation/style` | `RecommendRepository.getRecommendations` |
| Virtual Fitting | GET | `/api/v1/virtual-fitting/my-closet` | `FittingRepository.getMyCloset` (저장한 코디 목록) |
| Clothes | GET | `/api/v1/clothes` | `ClothesRepository.getClothesList` (category 쿼리 없음) |
| Clothes | GET | `/api/v1/clothes/{id}` | `ClothesRepository.getClothDetail` |
| Clothes | POST | `/api/v1/clothes` | `ClothesRepository.uploadSingleCloth` |
| Clothes | DELETE | `/api/v1/clothes/{id}` | `ClothesRepository.deleteCloth` |
| Clothes Set | GET | `/api/v1/clothes-sets` | `ClothesSetRepository.getClothesSets` (코디 폴더 목록) |
| Clothes Set | POST | `/api/v1/clothes-sets/save` | `ClothesSetRepository.saveClothesSet` (폴더에 저장) |
| Clothes Set | PATCH | `/api/v1/clothes-sets/{id}` | `ClothesSetRepository.updateClothesSet` (폴더 이름 수정) |
| Clothes Set | DELETE | `/api/v1/clothes-sets/{id}` | `ClothesSetRepository.deleteClothesSet` (폴더 삭제) |
| Clothes Set | DELETE | `/api/v1/clothes-sets/fitting/{fittingTaskId}` | `ClothesSetRepository.deleteFittingFromSet` (착장 개별 삭제) |

### ❌ 미구현

| 구분 | 메서드 | 경로 | 설명 |
|------|--------|------|------|
| **Clothes** | (선택) | GET `/api/v1/clothes` | 쿼리 파라미터 `category` (Top/Bottom/Shoes) 미지원 |

### ⚠️ 인증/인프라

| 항목 | 상태 | 설명 |
|------|------|------|
| Bearer 자동 부착 | 화면별 수동 | 각 화면에서 `dio.options.headers['Authorization'] = 'Bearer ...'` 설정. 전역 Dio 인터셉터 없음. |
| 401 시 토큰 갱신 후 재시도 | 미구현 | 스플래시에서만 refresh. API 호출 중 401 시 자동 refresh 후 재요청 로직 없음. |

### 참고: Swagger에 없는 클라이언트 API

- `POST /api/v1/clothes/analysis` (`ClothesRepository.uploadAnalysisCloth`) — 상·하의·신발 **파일** 업로드용. AI 스타일리스트 추천 결과 상세에서는 사용하지 않음(추천 결과는 이미 서버에서 생성·분석된 상태).

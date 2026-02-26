# Capstone Project API – OpenAPI 스펙 기준 정리

- **OpenAPI**: 3.1.0
- **Base**: `/`, `http://localhost:80`, `http://localhost:8080`
- **인증**: Auth 제외 API → `Authorization: Bearer {accessToken}`

---

## 전체 API 목록 (태그별)

### Auth (인증)
| 메서드 | 경로 | 설명 |
|--------|------|------|
| POST | `/api/v1/auth/login` | 일반 로그인 (email, password → accessToken, refreshToken) |
| POST | `/api/v1/auth/signup` | 회원가입 (email, password, gender 등) |
| POST | `/api/v1/auth/logout` | 로그아웃 (refreshToken) |
| POST | `/api/v1/auth/token/refresh` | 토큰 갱신 (refreshToken → 새 access/refresh) |
| POST | `/api/v1/auth/google` | Google 로그인 (idToken) |
| POST | `/api/v1/auth/kakao` | Kakao 로그인 (accessToken) |

### Virtual Fitting (가상 피팅)
| 메서드 | 경로 | 설명 |
|--------|------|------|
| POST | `/api/v1/virtual-fitting` | 가상 피팅 요청 (user_image, top_image 필수, bottom_image 선택). **비동기 → 202 Accepted** + body `{ success, message, data: { taskId } }`. 이후 status 폴링 또는 stream(SSE) 사용. |
| GET | `/api/v1/virtual-fitting/{taskId}/status` | 피팅 작업 상태 조회 (폴링). 응답 `data`: `{ taskId, status, resultImgUrl }`. status: WAITING, PROCESSING, COMPLETED, FAILED. |
| GET | `/api/v1/virtual-fitting/{taskId}/stream` | 피팅 작업 상태 스트림 (SSE). task당 1연결, 타임아웃 1분. COMPLETED/FAILED면 1회 전송 후 종료. |
| DELETE | `/api/v1/virtual-fitting/{taskId}` | 피팅 결과 삭제(닫기). 본인 소유만. 응답 `data`: string. |
| PATCH | `/api/v1/virtual-fitting/{taskId}` | 피팅 결과 내 옷장 저장. 응답 `data`: string. |
| GET | `/api/v1/virtual-fitting/recommendation/style` | 스타일 추천. query(자연어) 필수. 응답 `data.recommendations[]`: taskId, score, resultImgUrl, styleAnalysis, topId, bottomId. 유사도 0.7 이상, 최대 10개. |
| GET | `/api/v1/virtual-fitting/my-closet` | 내가 저장한 코디 목록. 응답 `data[]`: id, userId, topId, bottomId, resultImgUrl, status, styleAnalysis, resultGender, bodyImgUrl, saved, topClothes, bottomClothes. |

### Clothes (옷)
| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/api/v1/clothes` | 내 옷장 목록 (query: category = 전체/Top/Bottom/Shoes) |
| POST | `/api/v1/clothes` | 옷 등록 (query: category, body: multipart file) → 비동기 202 |
| GET | `/api/v1/clothes/{id}` | 옷 상세 조회 |
| DELETE | `/api/v1/clothes/{id}` | 옷 삭제 |

### Clothes Set API (코디 폴더)
| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/api/v1/clothes-sets` | 내 폴더 목록 조회 |
| POST | `/api/v1/clothes-sets/save` | 코디 저장 (setName, clothesIds, fittingTaskId) |
| PATCH | `/api/v1/clothes-sets/{id}` | 폴더 이름 수정 (newName) |
| DELETE | `/api/v1/clothes-sets/{id}` | 폴더 전체 삭제 |
| DELETE | `/api/v1/clothes-sets/fitting/{fittingTaskId}` | 착장 개별 삭제 |

### User (마이페이지)
| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/api/v1/users/me` | 마이페이지 조회 (닉네임, 프로필 이미지, 키, 몸무게, 성별) |
| PATCH | `/api/v1/users/me` | 마이페이지 수정 (query: nickname, height, weight / multipart: file) |

### Feed (피드)
| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/api/v1/feeds` | 피드 전체 목록 (feedId, 제목, 스타일 이미지) |
| GET | `/api/v1/feeds/me` | 내 피드 목록 |
| GET | `/api/v1/feeds/preview/{fittingTaskId}` | 피드 게시 전 미리보기 (저장된 피팅 ID 기준) |
| GET | `/api/v1/feeds/{feedId}` | 피드 상세 (작성자, 스타일/상의/하의 이미지·이름·ID, 제목·내용) |
| POST | `/api/v1/feeds` | 피드 작성 (fittingTaskId, feedTitle, feedContent) |
| PATCH | `/api/v1/feeds/{feedId}` | 피드 수정 (제목·내용) |
| DELETE | `/api/v1/feeds/{feedId}` | 피드 삭제 (소프트 삭제) |

---

## 기존 문서 대비 추가된 API 목록

아래는 이전 Swagger 정리(`API_SWAGGER_정리.md`)에는 없었고, **이번 OpenAPI 스펙에 새로 포함된 API**입니다.

| 태그 | 메서드 | 경로 | 설명 |
|------|--------|------|------|
| **Virtual Fitting** | GET | `/api/v1/virtual-fitting/{taskId}/stream` | 가상 피팅 상태 SSE 스트림 (실시간, task당 1연결, 타임아웃 1분) |
| **User** | GET | `/api/v1/users/me` | 마이페이지 조회 |
| **User** | PATCH | `/api/v1/users/me` | 마이페이지 수정 (닉네임, 키, 몸무게, 프로필 이미지) |
| **Feed** | GET | `/api/v1/feeds` | 피드 전체 목록 |
| **Feed** | GET | `/api/v1/feeds/me` | 내 피드 목록 |
| **Feed** | GET | `/api/v1/feeds/preview/{fittingTaskId}` | 피드 게시 전 미리보기 |
| **Feed** | GET | `/api/v1/feeds/{feedId}` | 피드 상세 |
| **Feed** | POST | `/api/v1/feeds` | 피드 작성 |
| **Feed** | PATCH | `/api/v1/feeds/{feedId}` | 피드 수정 |
| **Feed** | DELETE | `/api/v1/feeds/{feedId}` | 피드 삭제 |

**요약**
- **Virtual Fitting**: 1개 추가 → `GET /api/v1/virtual-fitting/{taskId}/stream` (SSE)
- **User**: 2개 추가 → 마이페이지 조회/수정
- **Feed**: 7개 추가 → 피드 목록(전체/내), 미리보기, 상세, 작성, 수정, 삭제

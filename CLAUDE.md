# Bit-Pet 프로젝트 가이드

반려 파충류 사육자를 위한 개체 관리 + 커뮤니티 크로스플랫폼 앱.
모노레포: `bitpet_server` (Java 백엔드) + `bitpet_app` (Flutter 프론트엔드)

---

## 레포지토리 & 문서

- **GitHub**: https://github.com/subin9804/bit-pet
- **기획서 v5**: https://www.notion.so/36cdadff16ba81c1b77dc015a57875a2
- **ERD v3**: (Notion — ERD v3)
- **API 정의서 v2**: (Notion — API 정의서 v2)
- **Notion 진행상황 홈**: https://www.notion.so/Bit-pet-358dadff16ba805aaa90f9f4764c26bf
- **Swagger (로컬)**: http://localhost:8080/swagger-ui.html

---

## 기술 스택

### 백엔드 (bitpet_server)
| 항목 | 내용 |
|------|------|
| 언어 | Java 21 |
| 프레임워크 | Spring Boot 3.5.x |
| 빌드 | Gradle Kotlin DSL |
| ORM | JPA / Hibernate 6 |
| DB | PostgreSQL 16 (Docker) |
| 캐시 | Redis 7 (Docker) |
| 마이그레이션 | Flyway (validate 모드) |
| 인증 | JWT (Access 30m / Refresh 14d, Redis) + OAuth2 |
| 이미지 | AWS S3 서울 (로컬 개발: LocalStack) |
| 패키지 루트 | `io.bitpet` |

### 프론트엔드 (bitpet_app)
| 항목 | 내용 |
|------|------|
| 언어 | Dart / Flutter |
| 상태관리 | flutter_riverpod |
| 라우팅 | go_router |
| HTTP | dio |
| 로컬 DB | drift (sqflite 래퍼) |
| 인증 저장 | flutter_secure_storage |
| 베이스 URL | `http://localhost:8080/api/v1` (로컬) |

---

## 로컬 실행

```bash
# 백엔드
cd bitpet_server
docker compose up -d        # PostgreSQL + Redis + LocalStack
./gradlew bootRun --args='--spring.profiles.active=local'

# Flutter
cd bitpet_app
flutter pub get
flutter run
```

---

## 패키지 구조

### 백엔드 (`io.bitpet`)
```
auth/         인증·OAuth2 (JWT, 회원가입·로그인·탈퇴)
pet/          개체 CRUD, 가계도
              ※ mating은 record/mating 으로 이전 (v5)
record/
  domain/     WeightDtl, FeedingDtl, CleaningDtl (레거시 공유 도메인)
  memo/       MemoDtl, MemoTagCd, MemoVetExtDtl + CRUD API
  mating/     MatingDtl + CRUD API (구 mating_rls → mating_dtl)
  laying/     LayingDtl, LayingHatchDtl + CRUD API
  calendar/   월별 기록 집계 (JdbcTemplate UNION)
  timeline/   통합 타임라인 (JdbcTemplate, 카테고리 필터)
  controller/ RecordController (weight/feeding/cleaning)
              HealthLogController (410 Gone — /api/v1/pets/{petId}/memos 로 이전)
routine/      루틴 도메인 (user 소유, routine_pet_rls, routine_log_dtl)
notification/ 알림 로그 + NotificationType enum
scheduler/    RoutineScheduler (@Scheduled 루틴 알람)
community/    게시글·댓글·좋아요
photo/        폴리모픽 사진 (photo_dtl: PET/MEMO/MATING/LAYING)
              PhotoController (/api/v1/photos/**)
              PetPhotoController (구 /api/v1/pets/{petId}/photos/** 하위 호환)
storage/      S3Service (presignPut/presignGet/delete)
sync/         오프라인 동기화 API (resources: pet/weight/feeding/cleaning/memo/mating/laying/laying_hatch)
common/       공통 (exception, entity, config, api 응답 포맷)
```

### 프론트엔드 (`lib/`)
```
core/
  api/          DioProvider, ApiResponse, AuthInterceptor
  auth/         TokenStorage
  db/           AppDatabase (Drift) + tables/
  router/       AppRouter (go_router)
  theme/        AppColors, AppTextStyles, AppTheme
  widgets/      공통 위젯 (EmptyState, SkeletonLoader, Toast, ConfirmModal)

features/
  auth/         로그인·회원가입
  pet/          개체 CRUD, 개체 상세
  record/       기록 화면 (weight/feeding/cleaning/memo/mating/laying)
  routine/      루틴 관리 (SCR-08A, SCR-08, SCR-12)
  notification/ 알림 목록
  community/    커뮤니티 피드·게시글 상세
  home/         대시보드 (FAB → FabRecordSheet)
  my/           마이페이지
```

---

## Flyway 마이그레이션 현황

| 버전 | 내용 |
|------|------|
| V1 | user_mst, user_oauth_rls |
| V2 | pet 임시 테이블 |
| V3 | pet_mst, species_cd, post_category_cd |
| V4 | weight/feeding/cleaning/health_memo_dtl |
| V5 | routine_mst 초기 (alarm_mst 포함 — V13에서 제거됨) |
| V6 | pet_photo_dtl |
| V7 | pet_relation_rls, mating_rls |
| V8 | post_mst, post_comment_dtl, post_photo_dtl, post_like_rls |
| V9 | notification_log_dtl, device_token_rls, notification_template_cd |
| V10 | 오프라인 sync 컬럼 + fn_bump_sync_version 트리거 |
| V11 | admin_role_rls, serial_pool_stat_mst |
| V12 | morph_cd |
| V13 | 루틴 재설계 — alarm_mst 제거, routine_mst user 소유 전환, routine_pet_rls·routine_log_dtl 신설, feeding_dtl에 routine_id/feed_response 추가, notification_log_dtl에 pet_count 추가 |
| V14 | notification_log_dtl에 notification_type·reference_id 추가 |
| V15 | health_memo_dtl → memo_dtl 리네임, content/logged_at/sync 컬럼 추가, 데이터 마이그레이션 |
| V16 | memo_tag_cd 신설 + 시드 데이터 (VET/SHED/BEHAVIOR/ETC) |
| V17 | memo_tag_rls, memo_vet_ext_dtl 신설 |
| V18 | mating_rls → mating_dtl 리네임, external_partner/duration/is_successful/season_label/tried_at 등 컬럼 추가 |
| V19 | laying_dtl, laying_hatch_dtl 신설 |
| V20 | photo_dtl 폴리모픽 신설, pet_photo_dtl 데이터 이전(ID 보존), pet_photo_dtl 삭제 |
| V21 | weight_dtl/feeding_dtl/cleaning_dtl 캘린더용 부분 인덱스 추가 |

> **다음 마이그레이션은 V22부터 작성.**

---

## 핵심 설계 결정사항

### 루틴 도메인 (v3.1)
- 루틴은 **user 소유** (기존 pet 소유에서 변경)
- `routine_pet_rls`: 루틴-개체 다대다 연결
- `routine_log_dtl`: 개체별 수행 기록, status = COMPLETED / REFUSED
- REFUSED + 메모 없음 → INSERT 안 함
- FEEDING 완료 → `feeding_dtl` + `routine_log_dtl` 양쪽 INSERT
- WEIGHT 완료 → `weight_dtl` + `routine_log_dtl` 양쪽 INSERT
- CLEANING/CUSTOM → `routine_log_dtl`만 (extra_data JSONB에 타입별 메타)

### Memo 도메인 (v5)
- `health_memo_dtl` → `memo_dtl` (V15 마이그레이션)
- 태그: `memo_tag_cd` + `memo_tag_rls` (다대다)
- VET 태그 시 `memo_vet_ext_dtl` 필수 (clinicName, cost, nextVisitAt)
- 공개 엔드포인트: `GET /api/v1/memo-tags` (인증 불필요)

### Mating 도메인 (v5)
- `mating_rls` → `mating_dtl` (V18 마이그레이션)
- male_pet_id / female_pet_id 모두 nullable (외부 개체 지원)
- `season_label`: SPRING/SUMMER/FALL/WINTER (tried_at 기준 자동 계산 가능)
- 구 `POST /api/v1/pets/matings` → 410 Gone
- 신규: `POST /api/v1/pets/{petId}/matings`

### Laying 도메인 (v5)
- 암컷 pet만 산란 가능 (FEMALE 검증)
- `laying_hatch_dtl.status`: PENDING / HATCHED / FAILED / SLUG
- `POST /api/v1/layings/{layingId}/hatches/{hatchId}/register-pet` → 새 개체 + 계보 자동 생성

### Photo 도메인 (v5)
- `photo_dtl` 폴리모픽: entity_type IN (PET/MEMO/MATING/LAYING) + entity_id
- 신규 통합 API: `/api/v1/photos/**`
- 구 `/api/v1/pets/{petId}/photos/**` → PetPhotoController 하위 호환 유지
- `pet_photo_dtl` 삭제됨 (V20)

### 오프라인 Sync (v5)
- Pull 지원 리소스: `pet, weight, feeding, cleaning, memo, mating, laying, laying_hatch, post, comment, like`
- Push 지원 리소스: `pet, weight, feeding, cleaning, memo` (mating/laying/laying_hatch push는 REST API 전용 — 도메인 검증 복잡성)
- `health_memo` 리소스명 → `memo` 로 변경 (클라이언트 업데이트 필요)

### JSONB (Hibernate 6)
hypersistence-utils 없이 Hibernate 6 내장 방식 사용:
```java
@JdbcTypeCode(SqlTypes.JSON)
private Map<String, Object> extraData;
```

### 알림 타입 (v3.2)
`alarm_mst` 대신 `notification_log_dtl.notification_type` 컬럼으로 분기:
- `ROUTINE_ALARM` — 루틴 스케줄 알람
- `COMMUNITY_COMMENT` — 댓글 알림 (referenceId = commentId)
- `COMMUNITY_LIKE` — 좋아요 알림 (referenceId = postId)
- `AI_CONSULTING` — AI 컨설팅 완료 (2차 예정)
- `SYSTEM` — 공지·점검

### 개체 일련번호
VARCHAR(8) 고정, 32자 풀(0/O/I/1 제외), 6자리 시작, 풀 80% 시 7자리 확장.

### 인증
JWT Access 30분 + Refresh 14일 (Redis 저장, Rotation).
OAuth 토큰 AES-256-GCM 암호화 (`BITPET_TOKEN_ENC_KEY` 환경변수).
비밀번호 최소 10자 + 2종류 이상 조합.

### Soft Delete
`@SQLRestriction("deleted_at IS NULL")` 전 도메인 적용.

### API 응답 형식
```json
{ "success": true, "data": { ... } }
{ "success": false, "error": { "code": "...", "message": "..." } }
```
Base URL: `/api/v1`

---

## Deprecated 엔드포인트

| 구 URL | 상태 | 대체 |
|--------|------|------|
| `GET/POST /api/v1/pets/{petId}/health-logs` | 410 Gone | `/api/v1/pets/{petId}/memos` |
| `PATCH/DELETE /api/v1/health-logs/{logId}` | 410 Gone | `/api/v1/memos/{memoId}` |
| `POST /api/v1/pets/matings` | 410 Gone | `POST /api/v1/pets/{petId}/matings` |
| `DELETE /api/v1/pets/matings/{matingId}` | 410 Gone | `DELETE /api/v1/matings/{matingId}` |

---

## 작업 완료 후 루틴 (매번 지킬 것)

1. **Git 커밋 + push** → `github.com/subin9804/bit-pet` master
2. **Notion 진행상황 페이지 생성** → 진행상황 홈 하위에 `진행현황 YYYY-MM-DD 제목` 형식
3. **세션 요약 txt 저장** → `C:\Users\subin\Desktop\bit-pet\sessions\YYYY-MM-DD-제목.md`

---

## 작업 스타일

- 작업 범위에 합의하면 **중간 질문 없이 자율 진행**, 끝에 요약만 보고
- 비파괴적·되돌릴 수 있는 결정만 자율 처리
- 외부 시스템 영향(push·삭제·외부 API 호출)은 확인 후 진행
- Flutter UI는 디자인 확정 전까지 **뼈대(Skeleton)만** 구현, 상세 UI는 별도 지시 대기
- 새 Flyway 마이그레이션은 기존 파일 절대 수정 금지, 항상 다음 버전으로 신규 작성

---

## 주의사항 / 알려진 제약

- `build.gradle.kts`에 **hypersistence-utils 없음** → JSONB는 `@JdbcTypeCode(SqlTypes.JSON)` 사용
- OAuth2 로컬 개발 시 `application-local.yml`에 autoconfigure exclude 처리됨 (키 없어도 기동 가능)
- `alarm_mst`는 V13에서 삭제됨 — 알람 기능은 `routine_mst.alarm_time` + `routine_mst.is_alarm_enabled`로 관리
- Flutter `app_database.dart` 스키마 버전(`schemaVersion`) 변경 시 마이그레이션 콜백 필요
- `FeedResponse` enum은 Java(`io.bitpet.record.domain`)와 Flutter(`record_models.dart`) 양쪽에 존재
- `mating_rls` 테이블은 V18에서 `mating_dtl`로 리네임됨 — `MatingRls.java` 삭제됨
- `pet_photo_dtl` 테이블은 V20에서 `photo_dtl`로 이전됨 — `PetPhotoDtl.java` 삭제됨
- `health_memo_dtl` 테이블은 V15에서 `memo_dtl`로 리네임됨 — `HealthMemoDtl.java` 삭제됨
- Sync push에서 `health_memo` 리소스명 → `memo`로 변경됨 (Flutter 클라이언트 업데이트 필요)

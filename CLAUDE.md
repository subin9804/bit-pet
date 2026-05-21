# Bit-Pet 프로젝트 가이드

반려 파충류 사육자를 위한 개체 관리 + 커뮤니티 크로스플랫폼 앱.
모노레포: `bitpet_server` (Java 백엔드) + `bitpet_app` (Flutter 프론트엔드)

---

## 레포지토리 & 문서

- **GitHub**: https://github.com/subin9804/bit-pet
- **기획서 v3**: https://www.notion.so/bit-pet-v3-364dadff16ba81be978ed0fc1e581927
- **ERD v2**: https://www.notion.so/ERD_v2-364dadff16ba819ba40deb6e60061992
- **API 정의서 v1**: https://www.notion.so/366dadff16ba81ad9c60d79777eb03e4
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
pet/          개체 CRUD, 가계도, 메이팅
record/       기록 (weight, feeding, cleaning, health_memo)
routine/      루틴 도메인 (user 소유, routine_pet_rls, routine_log_dtl)
notification/ 알림 로그 + NotificationType enum
scheduler/    RoutineScheduler (@Scheduled 루틴 알람)
community/    게시글·댓글·좋아요
photo/        S3 presigned URL, PetPhotoDtl
storage/      S3Service (presignPut/presignGet/delete)
sync/         오프라인 동기화 API
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
  record/       기록 화면 (weight/feeding/cleaning/health)
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

> **다음 마이그레이션은 V15부터 작성.**

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

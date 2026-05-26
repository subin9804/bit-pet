# 2026-05-19 — API 명세 정합성 수정 + STEP6 기록 도메인 + Morph 도메인

## 세션 개요

이전 세션에서 STEP5(Pet/Relation/Mating)까지 완료된 상태에서, 이어서 진행.  
API 명세서 검토 → 수정 → STEP6 record 도메인 구현 → morph_cd 도메인 추가 순서로 작업.

---

## 1. API 명세 정합성 수정

### 근거
Notion API 명세서(`/API-364dadff16ba81ed88f2db1dd0572eae`) 검토 결과, 기존 구현과 HTTP 메서드 불일치 발견.

### 변경 내용

| 엔드포인트 | 기존 | 변경 후 |
|-----------|------|--------|
| `DELETE /api/v1/auth/logout` | POST | **DELETE** |
| `DELETE /api/v1/auth/withdraw` | POST | **DELETE** |

**파일:** `src/main/java/io/bitpet/auth/controller/AuthController.java`

---

## 2. STEP6 — 기록 도메인 (`io.bitpet.record`)

### 신규 엔티티 4개

| 엔티티 | 테이블 | 주요 필드 |
|--------|--------|----------|
| `WeightDtl` | `weight_dtl` | `petId`, `weightG (DECIMAL)`, `measuredAt`, `source (MANUAL/BLUETOOTH)`, `memo` |
| `FeedingDtl` | `feeding_dtl` | `petId`, `foodType`, `amount`, `unit`, `fedAt`, `memo` |
| `CleaningDtl` | `cleaning_dtl` | `petId`, `cleaningType (FULL/PARTIAL/WATER_CHANGE)`, `cleanedAt`, `memo` |
| `HealthMemoDtl` | `health_memo_dtl` | `petId`, `symptom`, `treatment`, `memo`, `recordedAt` |

- 모든 엔티티: `@SQLRestriction("deleted_at IS NULL")` + `softDelete()` 메서드

### API 엔드포인트

**체중 (Weight)**
```
GET    /api/v1/pets/{petId}/weights    — 체중 이력 조회
POST   /api/v1/pets/{petId}/weights    — 체중 입력
DELETE /api/v1/weights/{weightId}      — 체중 삭제
```

**급여 (Feeding)**
```
GET    /api/v1/pets/{petId}/feedings   — 급여 기록 목록
POST   /api/v1/pets/{petId}/feedings   — 급여 기록 등록
PATCH  /api/v1/feedings/{feedingId}    — 급여 기록 수정
DELETE /api/v1/feedings/{feedingId}    — 급여 기록 삭제
```

**청소 (Cleaning)**
```
GET    /api/v1/pets/{petId}/cleanings  — 청소 기록 목록
POST   /api/v1/pets/{petId}/cleanings  — 청소 기록 등록
PATCH  /api/v1/cleanings/{cleaningId}  — 청소 기록 수정
DELETE /api/v1/cleanings/{cleaningId}  — 청소 기록 삭제
```

**건강 메모 (HealthLog — 명세서의 `/health-logs` 매핑)**
```
GET    /api/v1/pets/{petId}/health-logs  — 건강 기록 목록
POST   /api/v1/pets/{petId}/health-logs  — 건강 기록 등록
PATCH  /api/v1/health-logs/{logId}       — 건강 기록 수정
DELETE /api/v1/health-logs/{logId}       — 건강 기록 삭제
```

### RecordService 소유권 검증

모든 기록 작업: `verifyPetOwnership(userId, petId)` → pet 주인 확인 후 처리.  
소유자 아닌 경우 `RECORD_ACCESS_DENIED (403)` 반환.

### 신규 ErrorCode

```java
WEIGHT_NOT_FOUND, FEEDING_NOT_FOUND, CLEANING_NOT_FOUND,
HEALTH_LOG_NOT_FOUND, RECORD_ACCESS_DENIED
```

### 신규 파일 목록

```
record/domain/       WeightDtl, FeedingDtl, CleaningDtl, HealthMemoDtl, WeightSource, CleaningType
record/repository/   WeightDtlRepository, FeedingDtlRepository, CleaningDtlRepository, HealthMemoDtlRepository
record/dto/          WeightCreateRequest, WeightResponse
                     FeedingCreateRequest, FeedingUpdateRequest, FeedingResponse
                     CleaningCreateRequest, CleaningUpdateRequest, CleaningResponse
                     HealthLogCreateRequest, HealthLogUpdateRequest, HealthLogResponse
record/service/      RecordService
record/controller/   WeightController, FeedingController, CleaningController, HealthLogController
```

---

## 3. Morph 도메인 추가

### 배경
`morph_cd` 테이블 FK 및 `description` 컬럼을 `pet_mst`에 추가 요청.

### Flyway V12 마이그레이션

```sql
CREATE TABLE morph_cd (
    id, species_id (FK→species_cd), name_ko, name_en, display_order, is_active, ...
);
ALTER TABLE pet_mst ADD COLUMN morph_id BIGINT NULL;  -- FK→morph_cd
ALTER TABLE pet_mst ADD COLUMN description TEXT NULL;
```

### 신규 파일

| 파일 | 내용 |
|------|------|
| `pet/domain/MorphCd.java` | 엔티티 (speciesId Long, nameKo, nameEn, displayOrder, isActive) |
| `pet/repository/MorphCdRepository.java` | `findAllBySpeciesIdAndIsActiveTrueOrderByDisplayOrderAsc` |
| `pet/dto/MorphCdResponse.java` | id, speciesId, nameKo, nameEn, displayOrder |

### 수정 파일

**PetMst 엔티티**
- `morph` 필드 추가: `@ManyToOne(LAZY) MorphCd`
- `description` 필드 추가: `TEXT nullable`
- `builder`, `updateProfile()` 시그니처 갱신

**DTO 3종**
- `PetCreateRequest` / `PetUpdateRequest`: `morphId (Long)`, `description (String)` 추가
- `PetResponse`: `morphId`, `morphNameKo`, `description` 추가

**PetService**
- `MorphCdRepository` 주입
- `resolveMorph(morphId, species)` 헬퍼: morph 존재 확인 + species 소속 여부 검증
- create / update 양쪽에서 호출
  - update 시 effective species = 요청에 species 명시 시 신규, 미명시 시 기존 pet species

**SpeciesController**
- `GET /api/v1/species/{speciesId}/morphs` 추가 (public 경로)
- `application.yml` public-paths에 `/api/v1/species/*/morphs` 추가

**신규 ErrorCode**
```java
MORPH_NOT_FOUND(404), MORPH_SPECIES_MISMATCH(400)
```

---

## 4. GitHub 커밋 이력 (2026-05-19)

| 커밋 | 내용 |
|------|------|
| `feat: API spec alignment + STEP6 record domain` | AUTH DELETE 수정 + record 도메인 전체 |
| `feat: morph_cd 도메인 + pet_mst morph_id/description 컬럼 추가` | V12 마이그레이션 + Morph 전체 |

브랜치: `master` → `subin9804/bit-pet`

---

## 5. 현재 Flyway 마이그레이션 현황

| 버전 | 내용 |
|------|------|
| V1 | user_mst, user_oauth_rls |
| V2 | pets (임시) |
| V3 | pet_mst 구조 개편 + species_cd + post_category_cd |
| V4 | weight_dtl, feeding_dtl, cleaning_dtl, health_memo_dtl |
| V5 | routine_mst, alarm_mst |
| V6 | pet_photo_dtl |
| V7 | pet_relation_rls, mating_rls |
| V8 | post_mst, post_comment_dtl, post_photo_dtl, post_like_rls |
| V9 | notification_log_dtl, device_token_rls, notification_template_cd |
| V10 | sync 컬럼 + fn_bump_sync_version() 트리거 |
| V11 | admin_role_rls, serial_pool_stat_mst |
| V12 | morph_cd + pet_mst(morph_id, description) ✅ |

---

## 6. 다음 단계

- **STEP7**: RoutineMst, AlarmMst CRUD + Spring Scheduler
  - 엔드포인트: `/api/v1/pets/{petId}/schedules`, `/api/v1/schedules/{id}`
- **STEP8**: LocalStack S3 + Presigned URL + PetPhotoDtl API
- **STEP9**: PostMst, PostCommentDtl, PostLikeRls 커뮤니티 API (`/api/v1/diary/...`)

# 2026-05-26 — v5 백엔드: memo/mating/laying/calendar/timeline/photo

## 작업 내용

### 신규 도메인 구현 (io.bitpet.record.*)

#### Memo (record/memo)
- `MemoDtl` (memo_dtl), `MemoTagCd` (memo_tag_cd), `MemoTagRls`, `MemoVetExtDtl`
- API: GET/POST `/api/v1/pets/{petId}/memos`, GET/PUT/DELETE `/api/v1/memos/{memoId}`
- API: GET `/api/v1/memo-tags` (인증 불필요)
- VET 태그 → `memo_vet_ext_dtl` 필수 (clinicName, cost, nextVisitAt)

#### Mating (record/mating)
- `MatingDtl` (mating_dtl) — malePetId/femalePetId nullable, tried_at, season_label
- API: POST/GET `/api/v1/pets/{petId}/matings`, GET/PUT/DELETE `/api/v1/matings/{matingId}`

#### Laying (record/laying)
- `LayingDtl` (laying_dtl), `LayingHatchDtl` (laying_hatch_dtl), `HatchStatus` enum
- API: POST/GET `/api/v1/pets/{petId}/layings`
- API: GET/PUT/DELETE `/api/v1/layings/{layingId}`
- API: POST/PUT/DELETE `/api/v1/layings/{layingId}/hatches/{hatchId}`
- API: POST `/api/v1/layings/{layingId}/hatches/{hatchId}/register-pet` → 새 개체 + 계보 자동 생성

#### Calendar (record/calendar)
- GET `/api/v1/pets/{petId}/calendar?yearMonth=YYYY-MM&categories=`
- JdbcTemplate UNION — weight/feeding/cleaning/memo/mating/laying 날짜 집계

#### Timeline (record/timeline)
- GET `/api/v1/pets/{petId}/records?from=&to=&categories=&limit=`
- JdbcTemplate per-category, 최신순 정렬, 기본 20개

### Photo 도메인 (photo)
- `PhotoDtl` 폴리모픽: entity_type IN (PET/MEMO/MATING/LAYING) + entity_id
- 신규 통합 API: POST `/api/v1/photos/presign`, POST `/api/v1/photos`, GET `/api/v1/photos`, DELETE `/api/v1/photos/{photoId}`
- PATCH `/api/v1/pets/{petId}/photos/{photoId}/profile`
- 구 `/api/v1/pets/{petId}/photos/**` → `PetPhotoService` 하위 호환 유지

### Flyway 마이그레이션 (V15–V21)
| V15 | health_memo_dtl → memo_dtl (content/logged_at/sync 컬럼) |
| V16 | memo_tag_cd + 시드 (VET/SHED/BEHAVIOR/ETC) |
| V17 | memo_tag_rls, memo_vet_ext_dtl |
| V18 | mating_rls → mating_dtl (tried_at, season_label, is_successful 등) |
| V19 | laying_dtl, laying_hatch_dtl |
| V20 | photo_dtl 폴리모픽, pet_photo_dtl → photo_dtl ID 보존 이전 (`OVERRIDING SYSTEM VALUE`) |
| V21 | 캘린더용 부분 인덱스 (WHERE deleted_at IS NULL) |

### Deprecated 처리
- `GET/POST /api/v1/pets/{petId}/health-logs` → 410 Gone (HealthLogController)
- `PATCH/DELETE /api/v1/health-logs/{logId}` → 410 Gone
- `POST /api/v1/pets/matings` → 410 Gone (PetController)
- `DELETE /api/v1/pets/matings/{matingId}` → 410 Gone

### 리팩토링 / 삭제
- 삭제: `MatingRls.java`, `MatingRlsRepository.java` (V18 이후 테이블 없음)
- 삭제: `HealthMemoDtl.java`, `HealthMemoDtlRepository.java` (V15 이후 테이블 없음)
- 삭제: `PetPhotoDtl.java`, `PetPhotoDtlRepository.java` (V20 이후 테이블 없음)
- 삭제: `pet/dto/MatingRequest.java`, `MatingResponse.java` (구 PetService mating 메서드 제거)
- 삭제: `record/dto/HealthLogResponse.java`, `HealthLogCreateRequest.java`, `HealthLogUpdateRequest.java`
- `PetService`: addMating/listMatings/deleteMating 메서드 제거
- `RecordService`: healthLogRepository → memoRepository, getRecentRecords에 MEMO 항목 추가
- `SyncService`: health_memo → memo (MemoDtl), mating/laying/laying_hatch pull SQL 추가, push는 memo만 지원
- `application.yml`: `/api/v1/memo-tags` public paths에 추가
- `MemoDtlRepository`: `findByClientIdAndClientChangeId`, `findAllByPetIdInOrderByLoggedAtDesc` 추가

### CLAUDE.md 업데이트
- Flyway 마이그레이션 V15-V21 추가, 다음 버전 V22
- 패키지 구조 업데이트 (record 서브패키지 구조 반영)
- 핵심 설계 결정사항에 memo/mating/laying/photo/sync v5 변경 추가
- Deprecated 엔드포인트 표 추가

## 커밋
`48c27f5` — feat(v5): memo/mating/laying/calendar/timeline/photo 백엔드 구현

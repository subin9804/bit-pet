# 2026-05-22 작업 세션: 루틴 도메인 전면 재설계 (v3.1/v3.2)

## 커밋 정보
- **커밋 해시**: `b9e15fb`
- **브랜치**: master
- **메시지**: feat: STEP13 — 루틴 도메인 전면 재설계 (v3.1/v3.2)
- **변경 파일**: 45개 파일, 2405개 추가, 359개 삭제

---

## 작업 배경

기획서 v3.1/v3.2에 따라 루틴 도메인을 전면 재설계.
- **루틴 소유권 변경**: pet 소유 → user 소유 (다수 개체 일괄 관리)
- **alarm_mst 제거**: 알람 필드를 routine_mst로 통합
- **routine_pet_rls 신설**: 루틴-개체 다대다 연결
- **routine_log_dtl 신설**: 개체별 수행 기록 (CLEANING/CUSTOM/WEIGHT 타입 지원)
- **루틴 완료 모달 (SCR-12)**: 일괄/개별 분기 + 카드 슬라이더
- **FAB 기록 바텀시트 (SCR-11)**: 4단계 플로우 하이브리드 개체 선택
- **개체 상세 루틴 탭 (SCR-08)**: 구독/구독해제 UX + 스트릭 플레이스홀더

---

## Java 백엔드 변경사항

### Flyway 마이그레이션 V13
파일: `bitpet_server/src/main/resources/db/migration/V13__routine_redesign.sql`

```sql
-- alarm_mst 제거
DROP TABLE IF EXISTS alarm_mst CASCADE;

-- routine_mst: pet_id -> user_id, 알람 필드 추가
ALTER TABLE routine_mst
  DROP COLUMN IF EXISTS pet_id,
  ADD COLUMN user_id BIGINT NOT NULL REFERENCES user_mst(id),
  ADD COLUMN alarm_time TIME,
  ADD COLUMN is_alarm_enabled BOOLEAN NOT NULL DEFAULT false;

-- routine_pet_rls: 루틴-개체 다대다
CREATE TABLE routine_pet_rls (
  id BIGSERIAL PRIMARY KEY,
  routine_id BIGINT NOT NULL REFERENCES routine_mst(id),
  pet_id BIGINT NOT NULL REFERENCES pet_mst(id),
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(routine_id, pet_id)
);

-- routine_log_dtl: 개체별 수행 기록
CREATE TABLE routine_log_dtl (
  id BIGSERIAL PRIMARY KEY,
  routine_id BIGINT NOT NULL REFERENCES routine_mst(id),
  pet_id BIGINT NOT NULL REFERENCES pet_mst(id),
  status VARCHAR(20) NOT NULL CHECK (status IN ('COMPLETED', 'REFUSED')),
  executed_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  extra_data JSONB,
  memo TEXT,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- feeding_dtl 확장
ALTER TABLE feeding_dtl
  ADD COLUMN routine_id BIGINT REFERENCES routine_mst(id),
  ADD COLUMN feed_response VARCHAR(20) CHECK (feed_response IN ('COMPLETE', 'PARTIAL', 'REFUSED'));

-- notification_log_dtl 확장
ALTER TABLE notification_log_dtl
  ADD COLUMN pet_count INTEGER;
```

### 신규 도메인 엔티티

#### RoutineLogStatus.java
```java
public enum RoutineLogStatus { COMPLETED, REFUSED }
```

#### RoutinePetRls.java
- routine_pet_rls 테이블 매핑
- 필드: id, routineId, petId, createdAt

#### RoutineLogDtl.java
- routine_log_dtl 테이블 매핑
- `@JdbcTypeCode(SqlTypes.JSON)` 어노테이션으로 JSONB 처리 (hypersistence-utils 불필요)
- `softDelete()` 메서드로 deletedAt 설정

#### FeedResponse.java
```java
public enum FeedResponse { COMPLETE, PARTIAL, REFUSED }
```

### 수정된 엔티티

#### RoutineMst.java
- `petId` → `userId` 변경
- `alarmTime` (LocalTime), `alarmEnabled` (boolean) 추가
- 인덱스: `idx_routine_mst_user_active`

#### RoutineType.java
- WEIGHT 추가 (기존: FEEDING, CLEANING, CUSTOM)

#### FeedingDtl.java
- `routineId` (Long, nullable), `feedResponse` (FeedResponse) 추가

#### NotificationLogDtl.java
- `petCount` (Integer) 추가

### 삭제된 파일
- `AlarmMst.java`
- `AlarmMstRepository.java`
- `AlarmCreateRequest.java`
- `AlarmUpdateRequest.java`
- `AlarmResponse.java`

### 신규 Repository

#### RoutinePetRlsRepository.java
- `findAllByRoutineIdOrderByPetIdAsc`
- `findAllByPetId`
- `findByRoutineIdAndPetId`
- `existsByRoutineIdAndPetId`
- `deleteByRoutineIdAndPetId`
- `countByRoutineId`
- `findPetIdsByRoutineId` (@Query JPQL)

#### RoutineLogDtlRepository.java
- `findAllByRoutineId`
- `findAllByPetId`
- `findTodayLogs`
- `countByRoutineIdAndStatusAndDeletedAtIsNull`

### 수정된 Repository

#### RoutineMstRepository.java
- `findAllByPetIdOrderByCreatedAtDesc` 제거
- `findAllByUserIdOrderByCreatedAtDesc` 추가
- `findAllByUserIdAndActiveOrderByCreatedAtDesc` 추가
- `findOverdueRoutines`: `alarmEnabled = true` 조건 추가

### 신규 DTO

#### RoutineCompleteBatchRequest.java
- executedAt, foodType, amount, unit, feedResponse, cleaningType, weightG, memo

#### RoutineCompleteIndividualRequest.java
- petId (@NotNull), status (@NotNull RoutineLogStatus) + 나머지 동일

#### RoutineLogResponse.java
- id, routineId, petId, status, executedAt, extraData (Map), memo, createdAt
- `from(RoutineLogDtl log)` 팩토리 메서드

### 수정된 DTO

#### RoutineCreateRequest.java
- routineType, title, cycleDays, alarmTime (LocalTime), alarmEnabled, petIds (List<Long>), memo

#### RoutineResponse.java
- userId (기존 petId 대체), alarmTime, alarmEnabled, petIds (List<Long>), petCount
- `from(RoutineMst r, List<Long> petIds)` 팩토리

#### RoutineUpdateRequest.java
- alarmTime, alarmEnabled 추가

#### FeedingCreateRequest.java / FeedingUpdateRequest.java
- `feedResponse` (FeedResponse) 필드 추가

#### FeedingResponse.java
- `routineId`, `feedResponse` 필드 추가

### RoutineService 전면 재작성

루틴 CRUD:
- `listRoutines(userId)`: 유저 소유 루틴 전체
- `getRoutine(userId, routineId)`: 단건 조회
- `createRoutine(userId, req)`: petIds 기반 routine_pet_rls INSERT
- `updateRoutine(userId, routineId, req)`
- `deleteRoutine(userId, routineId)`

개체 구독:
- `subscribePet(userId, routineId, petId)`: routine_pet_rls INSERT
- `unsubscribePet(userId, routineId, petId)`: routine_pet_rls DELETE
- `listSubscribedPets(userId, routineId)`: 구독 개체 목록

개체 관점:
- `listRoutinesForPet(userId, petId)`: RoutineWithSubscriptionResponse 목록

완료 처리:
- `completeBatch(userId, routineId, req)`: 모든 개체에 동일 기록 INSERT
- `completeIndividual(userId, routineId, req)`: 단일 개체 기록
- `saveSingleLog(routine, petId, req, status)`: 타입별 라우팅
  - FEEDING → feeding_dtl (routine_id 포함) + routine_log_dtl
  - WEIGHT → weight_dtl + routine_log_dtl
  - CLEANING → routine_log_dtl (extra_data에 cleaningType)
  - CUSTOM → routine_log_dtl (memo)
  - REFUSED + 메모 없음 → INSERT 안 함

### RoutineController 전면 재작성

```
GET    /api/v1/routines
GET    /api/v1/routines/{id}
POST   /api/v1/routines
PUT    /api/v1/routines/{id}
DELETE /api/v1/routines/{id}
GET    /api/v1/routines/{id}/pets
POST   /api/v1/routines/{id}/pets/{petId}
DELETE /api/v1/routines/{id}/pets/{petId}
GET    /api/v1/pets/{petId}/routines
POST   /api/v1/routines/{id}/complete/batch
POST   /api/v1/routines/{id}/complete/individual
GET    /api/v1/routines/{id}/logs
DELETE /api/v1/routine-logs/{logId}
```

### RoutineScheduler 재작성

- `routinePetRepository.findPetIdsByRoutineId()` 로 개체 목록 조회
- `buildTitle()` 메서드: 1마리 vs N마리 알림 메시지 분기
- `notificationService.createRoutineNotification(userId, repPetId, routineId, petCount, title, body)`

---

## Flutter 변경사항

### routine_models.dart (전면 재작성)
- `RoutineType`: FEEDING, CLEANING, WEIGHT, CUSTOM
- `RoutineLogStatus`: COMPLETED, REFUSED
- `Routine`: userId, petIds (List<int>), petCount 추가, petId 제거
- `RoutineWithSubscription`: routine + subscribed bool
- `RoutineLog`: id, routineId, petId, status, executedAt, extraData, memo, createdAt
- `CreateRoutineRequest`: routineType, title, cycleDays, alarmTime, alarmEnabled, petIds, memo
- `RoutineCompleteBatchRequest`: 배치 완료 요청 DTO
- `RoutineCompleteIndividualRequest`: 개별 완료 요청 DTO

### routine_repository.dart (전면 재작성)
14개 엔드포인트 구현:
- `getRoutines()` → GET /routines
- `getRoutine(routineId)` → GET /routines/{id}
- `createRoutine(request)` → POST /routines
- `updateRoutine(routineId, body)` → PUT /routines/{id}
- `deleteRoutine(routineId)` → DELETE /routines/{id}
- `subscribePet(routineId, petId)` → POST /routines/{id}/pets/{petId}
- `unsubscribePet(routineId, petId)` → DELETE /routines/{id}/pets/{petId}
- `getSubscribedPetIds(routineId)` → GET /routines/{id}/pets
- `getRoutinesForPet(petId)` → GET /pets/{petId}/routines
- `completeBatch(routineId, request)` → POST /routines/{id}/complete/batch
- `completeIndividual(routineId, request)` → POST /routines/{id}/complete/individual
- `getLogs(routineId)` → GET /routines/{id}/logs
- `deleteLog(logId)` → DELETE /routine-logs/{id}

### routine_provider.dart
- `routineListProvider`: FutureProvider<List<Routine>> (user 단위, family 파라미터 없음)
- `routineDetailProvider`: FutureProvider.family by routineId
- `routinesForPetProvider`: FutureProvider.family by petId
- `routineLogsProvider`: FutureProvider.family by routineId

### routine_screen.dart (SCR-08A)
- 사용자 루틴 목록 (`routineListProvider`)
- 타입별 아이콘/색상, D-Day 배지, 접힘/펼침 드롭다운
- 완료 처리 버튼 → `RoutineCompleteModal` 오픈
- FAB → 루틴 추가 (TODO: UI 확정 후 구현)

### routine_complete_modal.dart (SCR-12) [신규]
3단계 플로우:
1. 분기 선택 (2마리 이상일 때): 일괄 입력 vs 개별 입력
2-A. 일괄 입력: 타입별 폼 → 전체 개체 일괄 완료
2-B. 개별 카드 슬라이더: 개체별 완료/미완료 처리

타입별 입력 폼:
- FEEDING: 급여종류 TextField + FeedResponsePicker (완식/부분/거절)
- CLEANING: CleaningTypePicker (전체/부분/물갈기)
- WEIGHT: 숫자 입력 (g)
- CUSTOM: 메모만

### pet_routine_tab.dart (SCR-08) [신규]
- `routinesForPetProvider(petId)` 사용
- 구독/구독해제 토글 버튼
- 스트릭 뷰 플레이스홀더 (UI 확정 후 구현)

### fab_record_sheet.dart (SCR-11) [신규]
4단계 플로우:
1. 기록 유형 선택 (급여/체중/청소/건강)
2. 개체 선택 (전체/개별 체크박스)
3. 상세 입력 (타입별 폼, FeedResponsePicker 재사용)
4. 완료 확인 화면

- `routine_id = null` (FAB 독립 기록)
- `dashboard_tab.dart`에 FAB 추가하여 진입점 연결

### record_models.dart
- `FeedResponse` enum 추가 (COMPLETE, PARTIAL, REFUSED)
- `FeedingRecord.routineId` (int?) 필드 추가
- `FeedingRecord.feedResponse` 타입 String → FeedResponse? 변경

### app_database.dart
- `RoutinePetTable` 등록 (routine_table.dart에 이미 정의됨)

---

## 기술적 결정사항

### JSONB without hypersistence-utils
처음에는 `@Type(JsonBinaryType.class)` 방식 사용 시도 → 의존성 없어서 실패.
Hibernate 6의 내장 `@JdbcTypeCode(SqlTypes.JSON)` 사용으로 해결.
```java
@JdbcTypeCode(SqlTypes.JSON)
private Map<String, Object> extraData;
```

### REFUSED 기록 정책
- REFUSED + 메모 없음: INSERT 안 함 (의미 없는 거부 기록 방지)
- REFUSED + 메모 있음: status=REFUSED로 routine_log_dtl INSERT
- FEEDING 타입: REFUSED이면 feeding_dtl에 기록하지 않음

### FEEDING 타입 이중 기록
FEEDING 루틴 완료 시:
1. `feeding_dtl` INSERT (routine_id FK 포함, 상세 급여 데이터)
2. `routine_log_dtl` INSERT (완료 상태 추적용)

### WEIGHT 타입 이중 기록
1. `weight_dtl` INSERT (체중 기록)
2. `routine_log_dtl` INSERT (루틴 완료 상태 추적)

### 대표 개체 선정
`routine_pet_rls.pet_id ASC LIMIT 1` (가장 먼저 연결된 개체)
향후 수동 지정 기능은 `display_order` 컬럼 추가로 확장 예정.

---

## 남은 작업

- [ ] `pet_detail_screen.dart`에 TabBar 추가하여 `PetRoutineTab` 연결
- [ ] FAB 진입 시 개체 상세 컨텍스트에서 해당 개체 자동 체크 로직
- [ ] 루틴 완료 모달 — 개별 카드 슬라이더 좌우 스와이프 제스처
- [ ] 홈 대시보드 오늘의 루틴 카드 UI 구현
- [ ] 알림 수신 시 루틴 완료 모달 딥링크 연동
- [ ] Drift 오프라인 동기화 대상에 routine_log_dtl 포함 여부 결정

---

## Notion 링크
- **진행현황 페이지**: https://www.notion.so/367dadff16ba8175ad01e40bfaeabfac
- **API 정의서 v1** (§9 업데이트): https://www.notion.so/366dadff16ba81ad9c60d79777eb03e4

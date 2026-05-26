# 2026-05-26 — Flutter v5 업데이트: memo/mating/laying/cleaning/calendar/timeline

## 작업 내용

### 신규 파일
- `lib/core/db/tables/memo_table.dart` — MemoTable (tableName: `memo_dtl`, columns: id/petId/content/loggedAt/deletedAt/createdAt/updatedAt)

### 수정 파일

#### `lib/core/db/app_database.dart`
- `HealthMemoTable` → `MemoTable` 교체
- `schemaVersion` 2 → 3
- 마이그레이션 v2→v3: `DROP TABLE IF EXISTS health_memo_dtl` + `CREATE TABLE memo_dtl`

#### `lib/features/record/data/models/record_models.dart`
- `HealthMemo` 삭제 → `Memo`, `MemoTag`, `MemoVetExt` 추가
- 신규: `CleaningRecord`, `CleaningType` (FULL/PARTIAL/WATER_CHANGE)
- 신규: `MatingRecord`, `LayingRecord`, `HatchRecord`, `HatchStatus`
- 신규: `CalendarDay`, `TimelineItem`
- `RecentRecord.recordType` 주석 HEALTH → MEMO 업데이트

#### `lib/features/record/data/record_repository.dart`
- 구 API 제거: `getHealthLogs` (`/pets/{petId}/health-logs` → 410 Gone), `addHealthMemo`, `deleteHealthMemo`
- 신규: `getMemos`, `addMemo`, `updateMemo`, `deleteMemo` (`/pets/{petId}/memos`, `/memos/{id}`)
- 신규: `getMemoTags` (`/memo-tags`)
- 수정: `addCleaning` 정식 API (`/pets/{petId}/cleanings`, CleaningType + cleanedAt)
- 신규: `getCleanings` (`/pets/{petId}/cleanings`)
- 신규: `getMatings`, `addMating`, `deleteMating` (`/pets/{petId}/matings`, `/matings/{id}`)
- 신규: `getLayings`, `addLaying`, `deleteLaying` (`/pets/{petId}/layings`, `/layings/{id}`)
- 신규: `getCalendar` (`/pets/{petId}/calendar?yearMonth=&categories=`)
- 신규: `getTimeline` (`/pets/{petId}/records?from=&to=&categories=&limit=`)

#### `lib/features/record/providers/record_provider.dart`
- `healthMemoListProvider` → `memoListProvider`
- 신규: `cleaningListProvider`, `memoTagsProvider`, `matingListProvider`, `layingListProvider`

#### `lib/features/record/presentation/record_screen.dart`
- `recordType` 'health' → 'memo'
- `_HealthList` → `_MemoList` (content/loggedAt/tags 표시)
- `_CleaningList` 신설 (cleaningType/cleanedAt 표시)
- `_InputSheet`: 청소 SegmentedButton(FULL/PARTIAL/WATER_CHANGE), 메모 content 필드
- 불필요한 `go_router`, `pet_provider` import 제거

#### `lib/features/record/presentation/fab_record_sheet.dart`
- `_RecordType.health` → `_RecordType.memo`
- 청소 TODO 워크어라운드 제거 → `addCleaning(petId, _cleaningType, now, memo)` 직접 호출
- 메모: `_contentController` 추가, `addMemo` API 호출
- `_CleaningTypePicker` 위젯 추가 (ChoiceChip: 전체/부분/물교체)

### 미완료 (빌드 실행 필요)
- `app_database.g.dart` 재생성 필요:
  ```
  cd bitpet_app
  dart run build_runner build --delete-conflicting-outputs
  ```
- `health_memo_table.dart` 파일은 삭제해도 되지만 import 없으므로 무해함

## 커밋
`5688a1d` — feat(flutter/v5): v5 도메인 적용 — memo/mating/laying/cleaning/calendar/timeline

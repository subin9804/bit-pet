# 세션 요약 — 2026-05-23: 백엔드 미구현 API 3종 + 기획서 v4

## 작업 배경

Notion 진행현황 페이지 (2026-05-22 Flutter UI 재구현)에서 백엔드 미구현 API 3종이 식별됨.

## 구현한 내용

### 백엔드 신규 API (bitpet_server)

#### 1. GET /api/v1/routines/today
- 사용자의 모든 활성 루틴 + 각 루틴에 구독된 개체별 오늘 완료 상태 반환
- UTC 기준 당일 00:00 ~ 익일 00:00 내 status=COMPLETED 로그 조회
- 응답: `TodayRoutineResponse` (routineId, title, routineType, nextDueAt, pets[])
- pets[]: `PetTodayStatus` (petId, petName, completedToday, logId, executedAt)

#### 2. GET /api/v1/routines/{routineId}/today
- 특정 루틴의 오늘 완료 상태. 응답 구조는 위와 동일 (단일 객체)

#### 3. GET /api/v1/records/recent?limit=N
- 사용자 소유 개체의 feeding/weight/cleaning/health 최근 기록 통합 피드
- 기본 limit=10, 각 타입에서 최대 N건 조회 후 병합·시간순 정렬·top N 반환
- 응답: `RecentRecordResponse` (type, recordId, petId, petName, occurredAt, summary)

### 추가 변경사항
- `PetResponse`에 `speciesCategory` 필드 추가 (species_cd.category 값)
  - Flutter 개체 목록 화면(SCR-02)의 종 필터칩 렌더링에 사용
- `SyncService`의 `FeedingDtl.update()` 호출 시 feedResponse 인자 누락 버그 수정

### 수정된 파일 목록
| 파일 | 변경 유형 |
|------|----------|
| routine/dto/TodayRoutineResponse.java | 신규 |
| record/dto/RecentRecordResponse.java | 신규 |
| record/controller/RecordController.java | 신규 |
| routine/repository/RoutineLogDtlRepository.java | 쿼리 추가 |
| record/repository/FeedingDtlRepository.java | 쿼리 추가 |
| record/repository/WeightDtlRepository.java | 쿼리 추가 |
| record/repository/CleaningDtlRepository.java | 쿼리 추가 |
| record/repository/HealthMemoDtlRepository.java | 쿼리 추가 |
| routine/service/RoutineService.java | 메서드 추가 + import 버그 수정 |
| routine/controller/RoutineController.java | 엔드포인트 추가 |
| record/service/RecordService.java | 메서드 추가 |
| pet/dto/PetResponse.java | speciesCategory 필드 추가 |
| sync/service/SyncService.java | feedResponse 버그 수정 |

### Git
- 커밋: `327ee32` — feat(backend): 미구현 API 3종 추가 및 Pet category 노출
- GitHub master 브랜치 push 완료

## Notion 기획서 v4 생성

**URL**: https://www.notion.so/368dadff16ba81279764df1602d27bab

v3 전체 내용을 기반으로 v4 변경사항 병합:
- 네비게이션 구조 변경 (5탭 → 4탭 + 중앙 FAB)
- Flutter 화면 5종 재구현 내용 (SCR-01/02/02b/02c/06e)
- 신규 API 3종 스펙 상세
- PetResponse speciesCategory 변경점
- v3→v4 주요 변경점 비교표

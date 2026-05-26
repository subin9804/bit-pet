# Flutter UI 재구현 — 화면 01/02/02b/02c/06e

## 작업 일자
2026-05-22

## 작업 범위
reference.md 기반 5개 화면 전체 구현. 각 화면의 PNG 레퍼런스와 API를 매칭.

---

## 변경/신규 파일 목록

### UI 레이어
| 파일 | 화면 | 주요 변경 |
|------|------|---------|
| `home_screen.dart` | Shell | 5탭→4탭+중앙FAB (BottomAppBar+CircularNotchedRectangle) |
| `dashboard_tab.dart` | 01 홈 | 인삿말, TODAY 루틴 PageView, 내 개체 원형칩, 최근 기록 피드 |
| `pet_list_screen.dart` | 02 개체 | 개체/루틴 세그먼트 탭, 검색, 종 필터칩, 그리드/리스트 토글 |
| `routine_screen.dart` | 02b 루틴 | 타입 필터칩, 아코디언(설정+진행+캘린더), 알람토글 |
| `routine_today_check_sheet.dart` | 02c | 개체별 완료 체크 바텀시트 (NEW) |
| `feeding_record_sheet.dart` | 06e | 퍼-펫 피딩 기록 바텀시트 (NEW) |

### 데이터 레이어
| 파일 | 추가 내용 |
|------|---------|
| `routine_models.dart` | TodayRoutine, TodayPetStatus 모델 |
| `record_models.dart` | RecentRecord 모델 |
| `routine_repository.dart` | getTodayRoutines(), getTodayStatus(), completeAllPetsToday() |
| `record_repository.dart` | getRecentRecords() |
| `routine_provider.dart` | todayRoutinesProvider(StateNotifier), routineTodayStatusProvider |
| `record_provider.dart` | recentRecordsProvider |
| `app_text_styles.dart` | `title` 스타일 추가 |

### 라우팅
- `/records` → `/pets` 리다이렉트
- `/notifications` 라우트 추가 (알림 목록)

---

## API 매핑 요약

| 화면 | API 엔드포인트 |
|------|--------------|
| 홈(01) 루틴 슬라이더 | `GET /routines/today` |
| 홈(01) 내 개체 | `GET /pets` |
| 홈(01) 최근 기록 | `GET /records/recent?limit=5` |
| 홈(01) 알림 뱃지 | `GET /notifications` |
| 개체 관리(02) | `GET /pets`, `GET /species` |
| 루틴 관리(02b) | `GET /routines`, 알람토글 `PUT /routines/{id}` |
| 루틴 진행(02b 아코디언) | `GET /routines/{id}/today`, `GET /routines/{id}/logs` |
| 오늘 체크(02c) | `POST /routines/{id}/complete/individual` |
| 피딩 기록(06e) | `POST /pets/{id}/feedings` + `POST /routines/{id}/complete/individual` |

---

## 미구현/TODO
- 개체 카테고리 필터칩: Pet 모델에 category 없어 현재 종명 기반 필터 미동작
- 루틴 수정 바텀시트 (02b 수정 버튼)
- 체중/청소/사용자 루틴 타입의 06e 대응 입력 폼
- 개체 사진 업로드 (03번 화면 이미 구현됨)
- 백엔드 `GET /routines/today`, `GET /routines/{id}/today`, `GET /records/recent` API 구현 필요

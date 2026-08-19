# tailog(테일로그) 프로젝트 가이드

반려 파충류 사육자를 위한 개체 관리 + 커뮤니티 크로스플랫폼 앱.
모노레포: `bitpet_server` (Java 백엔드) + `bitpet_app` (Flutter 프론트엔드)

---

## 🏷️ 네이밍 규칙 (2026-08-02 개명)

`bit-pet` → **`tailog`** (한글 **테일로그**). tail + log. 도메인 `tailog.me` 보유.

**사용자 눈에 닿는 곳은 무조건 `tailog` / `테일로그`.** 새 UI 문자열·메일·랜딩·스토어 문구를
작성할 때 `bit-pet`, `비트펫`을 절대 쓰지 말 것.

내부 식별자는 **의도적으로 옛 이름을 유지**한다 (바꿀 실익이 없고 깨질 곳만 늘어남).
아래 값들을 발견해도 "고쳐야 할 잔재"가 아니므로 건드리지 말 것:

| 유지 (사용자 비노출) | 값 |
|---|---|
| 서버 Java 패키지 | `io.bitpet.**`, `BitPetApplication` |
| 디렉토리·Flutter 패키지명 | `bitpet_app/`, `bitpet_server/`, pubspec `name: bitpet_app` |
| DB명·계정 | `bitpet` |
| 환경변수 접두사 | `BITPET_*` (~25개) |
| 알림 채널 ID | `bitpet_default_channel` (3곳 일치 필요) |
| 로컬 캐시 파일 | `bitpet.sqlite` |
| GitHub 레포 | `github.com/subin9804/bit-pet` |

| 변경됨 (사용자 노출) | 값 |
|---|---|
| Android applicationId / iOS 번들 ID | **`me.tailog.app`** (양 플랫폼 동일. Play 업로드 후 영구 고정) |
| 앱 표시 이름 | `tailog` (AndroidManifest label, iOS CFBundleDisplayName/Name) |
| 딥링크·NFC 도메인 | **`tailog.me`** (구 `bitpet.kr`) |
| 메일 발신 | `noreply@tailog.me`, 제목 `[tailog]` |
| JWT issuer | `tailog` / 테스트 `tailog-test` (검증 시 issuer를 대조하지 않아 무해한 변경) |
| Firebase 프로젝트 ID | **`tailog-bba42`** (구 `bit-pet` 폐기. `tailog` 선점으로 접미사 자동 부여) |

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
adb reverse tcp:8080 tcp:8080   # 실기기 연결 시 (10.0.2.2는 Windows 방화벽에 막히는 경우 있음)
flutter run
```

### 앱 빌드 — 서버 주소 주입

`kBaseUrl`(`lib/core/api/api_client.dart`)은 `String.fromEnvironment('API_BASE_URL')`이고,
값을 안 주면 `http://localhost:8080/api/v1`로 떨어진다.

```bash
flutter run                       # 기본값(localhost) — 개발
flutter run --release             # 릴리즈 모드도 localhost + adb reverse 로 실기기 검증 가능
flutter build appbundle --dart-define=API_BASE_URL=https://tailog.me/api/v1   # Play 업로드
flutter build apk      --dart-define=API_BASE_URL=https://tailog.me/api/v1   # 사이드로딩
```

⚠️ **배포 빌드에 `--dart-define`을 빠뜨리면** 앱이 폰 자기 자신을 찾다가 모든 요청이 실패한다.
증상이 "네트워크 에러"라 원인이 안 보인다.

ℹ️ `kReleaseMode`로 분기하지 않는 건 의도적이다 — 그러면 실기기 릴리즈 빌드 테스트가 막힌다.
주소는 빌드 **환경**의 문제이지 빌드 **모드**의 문제가 아니다.

### 릴리즈 서명 (2026-08-11)

- 서명 정보는 **`android/key.properties`** (gitignore). 템플릿은 `android/key.properties.example`.
- 키스토어(`.jks`)는 **레포 밖**에 둔다. 잃어버리면 앱 업데이트를 영구히 못 올린다.
- `key.properties` 가 없으면 `build.gradle.kts` 가 **디버그 키로 폴백**한다 — 키스토어 없는
  환경에서도 `flutter run --release` 실기기 검증이 되게 하기 위한 것. 대신 빌드 로그에
  경고를 찍는다. 디버그 키로 서명된 AAB 는 Play 가 거부한다.

### 안드로이드 네트워크 설정 (2026-08-11)

- `INTERNET` 권한은 **`src/main/AndroidManifest.xml`** 에 있다. Flutter 템플릿은 이걸
  `debug`/`profile` 매니페스트에만 넣어주기 때문에, 옮기지 않으면 **릴리즈 빌드만 통신이
  전부 막힌다** — 개발 중에는 절대 안 드러나는 종류의 사고다. 지우지 말 것.
- `res/xml/network_security_config.xml` 은 평문(http)을 **`localhost` / `10.0.2.2` 에만**
  허용한다. Android 9+ 는 평문이 기본 차단이라, 이게 없으면 `flutter run --release` +
  `adb reverse` 로 실기기 검증을 할 수 없다. 나머지는 전부 https 강제 그대로다
  (`usesCleartextTraffic="true"` 로 전체를 열지 않는 이유).

ℹ️ Play는 AAB를 받아 **자기 앱 서명 키로 재서명**한다. 그래서 최종 앱의 지문이 업로드 키
지문과 다르고, `assetlinks.json`에는 **둘 다** 넣어야 한다 (NFC 딥링크 항목 참고).

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
nfc/          NFC 태그 이름표 (nfc_tag_mst + nfc_tag_bind_hst, 스캔·바인딩·해제, assetlinks.json, /t/{tagCd} 랜딩)
community/    게시글·댓글·좋아요
photo/        폴리모픽 사진 (photo_dtl: PET/MEMO/MATING/LAYING)
              PhotoController (/api/v1/photos/**)
              PetPhotoController (구 /api/v1/pets/{petId}/photos/** 하위 호환)
storage/      S3Service (presignPut/presignGet/delete)
sync/         오프라인 동기화 API (resources: pet/weight/feeding/cleaning/memo/mating/laying/laying_hatch)
common/       공통 (exception, entity, config, api 응답 포맷)
              entitlement/ 유료 티어 권한 판정 자리 — 현재 StubEntitlementService 가 항상 true.
                           ⚠️ 아직 **어떤 기능에도 적용되어 있지 않다**. 결제 연동 시 구현체만 교체
```

### 프론트엔드 (`lib/`)
```
core/
  api/          DioProvider, ApiResponse, AuthInterceptor
  auth/         TokenStorage
  db/           AppDatabase (Drift) + tables/
  nfc/          NfcPetScanSheet (개체 선택 자리의 '태그로 찾기'), NfcReader(NDEF 읽기+리더모드 선점), tag_url 파서
  router/       AppRouter (go_router)
  theme/        AppColors, AppTextStyles, AppTheme
  widgets/      공통 위젯 (EmptyState, SkeletonLoader, Toast, ConfirmModal)

features/
  auth/         로그인·회원가입
  pet/          개체 CRUD, 개체 상세
  record/       기록 화면 (weight/feeding/cleaning/memo/mating/laying)
  routine/      루틴 관리 (SCR-08A, SCR-08, SCR-12)
  notification/ 알림 목록
  nfc/          NFC 태그 (TagResolverScreen, 연결 모달, 이름표 관리)
  community/    커뮤니티 피드·게시글 상세
  home/         대시보드 (FAB → FabRecordSheet)
  my/           마이페이지
```

---

## Flyway 마이그레이션 현황

**2026-08-19 스쿼시 — 구 V1~V55 는 `V1__baseline_schema.sql` 하나로 합쳐졌고 파일은 삭제됐다.**

베이스라인은 V55까지 적용한 DB를 `pg_dump` 로 뽑은 것이라 순차 적용 결과와 동일하다.
(빈 DB에 새 V1만 적용해 다시 덤프한 뒤 diff 로 검증 — 구조 차이 0. CHECK 제약 표기만
PostgreSQL이 재정규화하는데 의미는 같다.)

- ⛔ **`V1__baseline_schema.sql` 은 절대 수정하지 말 것.** 고치면 체크섬이 바뀌어
  이미 적용된 모든 DB가 `validate` 단계에서 기동을 거부한다.
- ⛔ **스쿼시를 또 하지 말 것.** 운영 DB가 생긴 뒤로는 불가능하다. 배포 직전이라 가능했던 일회성 작업이다.
- **스쿼시 이후 추가된 마이그레이션**: V2(자유), V3(`user_agreement_dtl` — 약관·마케팅 동의 원장),
  V4(`user_notification_pref` — 알림 종류별 수신 설정 + `notification_log_dtl` 상태에 `SKIPPED` 추가).
  **다음은 V5.**
- 코드성 시드(`memo_tag_cd`, `post_category_cd`, `serial_pool_stat_mst`)는 베이스라인 하단에 들어 있다.
  종·모프 마스터는 그대로 `R__01`/`R__02` 담당.
- 어떤 컬럼이 왜 생겼는지 추적할 땐 git 이력을 본다:
  `git log --diff-filter=D --name-only -- 'bitpet_server/src/main/resources/db/migration/V*'`

<details>
<summary>구 V1~V55 이력 (파일은 삭제됨, 기록용)</summary>

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
| V22 | (이전 작업) |
| V23 | morph_cd v3.1/v3.2 — alias_list·has_health_concern 컬럼 추가, name_ko/name_en 100자 확장, pet_morph_rls 신설(N:N), pet_mst.morph_id·environment_memo 제거 |
| V24 | breeding_group 관련 |
| V25 | feeding_restructure |
| V26 | breeding_group_invite_code_drop |
| V27 | pet_mst.private_yn CHAR(1) 추가 — 'Y'=비공개(기본), 'N'=공개(전체 검색 허용) |
| V28 | pet_mst.private_yn CHAR(1) → VARCHAR(1) 타입 변경 (Hibernate 호환) |
| V29 | weight_dtl.routine_id 추가 (루틴 완료로 생성된 체중 기록 구분용) |
| V30 | pet_mst.hatching_date_precision 추가 (DAY/MONTH) |
| V31 | pet_mst.hatching_date_approximate 추가 |
| V32 | routine_mst.last_notified_at 추가 (알림 중복 발송 방지) |
| V33 | routine_mst.next_due_at/last_executed_at 타입 timestamptz → date |
| V34 | routine_mst.group_id 추가 — 루틴 소속 user → breeding_group 전환, 소유자 현재 그룹으로 백필 |
| V35 | routine_mst.start_date 추가 — 루틴 시작일 고정 보존(캘린더 표시 하한), created_at 기준 백필 |
| V36~V48 | (표 미반영 — 실제 파일 기준: cleaning/memo routine_id, pet_deceased_at, memo_tag POOP, routine soft delete, pet_keeper_rls, user_share_code, pet_share_invitation 3종, breeding_group 제거, record_created_by_user, routine_log_link_dtl, post_pinned) |
| V49 | nfc_tag_mst 신설 — NFC 태그 이름표 (tag_cd PK, pet_id/user_id nullable, default_action_cd) |
| V50 | feeding_dtl.refused_yn 추가 (거식) — food_type NOT NULL 해제 + CHECK로 둘을 묶음(Y면 food_type NULL / N이면 NOT NULL), 거식 부분 인덱스 |
| V51 | nfc_tag_mst 보완 — chip_type/batch_no/status 추가(+상태 백필), tag_cd 대문자 CHECK, scan_cnt·last_scan_at 제거 |
| V52 | nfc_tag_mst 정정 — default_action_cd 제거(축이 잘못된 설계), tag_cd 포맷을 Crockford Base32 6자 `^[0-9A-HJKMNP-TV-Z]{6}$` 로 확정 |
| V53 | pet_mst.user_id NOT NULL 해제 — 탈퇴 익명화 개체(가계도에서 '정보 없음') 지원. 권한 판정은 계속 pet_keeper_rls |
| V54 | 탈퇴 개체 처리 — pet_mst.is_orphaned, user_mst.show_nickname_in_pedigree, s3_delete_queue_dtl(커밋 후 S3 삭제 재시도 큐) 신설 |
| V55 | nfc_tag_bind_hst 신설 — 태그 연결 이력(append-only, BIND/REBIND/UNBIND/REVOKE). 태그 소유권 분쟁 판정 근거. FK 없음(개체·유저가 사라져도 이력은 남아야 함) |

</details>

---

## 핵심 설계 결정사항

### 루틴 도메인 (v3.1 → v6 그룹 소속)
- **v6: 루틴은 사육 그룹 소속** (`routine_mst.group_id`). user_id는 생성자로 유지
  - 조회·접근제어 모두 그룹 기준: 그룹 멤버면 그룹 전체 루틴 조회/완료 가능
  - `group_id NULL` = 그룹 미소속 유저의 개인 루틴 (본인만 접근)
  - 그룹 가입/탈퇴/해산 시 `routineRepo.assignGroupToUserRoutines`/`removeGroupFromUserRoutines`/`removeGroupFromAllRoutines`로 pet과 함께 동기화
  - 개체 검증도 그룹 기준: `verifyPetAccessible` (본인 개체 OR 같은 그룹 개체)
  - 스케줄러(알림)는 전역 스캔 유지 — 그룹과 무관
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

### 급여 거식 (V50)
- `feeding_dtl.refused_yn = 'Y'` → **먹이 정보 없이 메모만** 남는 기록. `food_type`은 NULL
- 불변식을 **DB CHECK + 엔티티 양쪽**에서 강제 (`ck_feeding_dtl_food_type_by_refused`, `FeedingDtl.applyRefused`)
  → REST·루틴 완료·오프라인 sync 어느 경로로 저장해도 "거식인데 먹이가 남은" 행이 생기지 않는다
- 요청 DTO의 `refused`는 **부분 수정 시 모드 전환 신호** — null이면 그대로, 값이 오면 먹이 필드를 통째로 갈아끼운다
- 앱: `FeedFormData.isRefused` (폼 최상단 토글). 켜면 종류·사이즈·마릿수·영양제가 사라지고 메모만 남으며,
  `FeedItemsEditor`에서 거식은 **단독 항목** — 추가 시 기존 목록을 비우고 컴포저를 감춘다
- 먹이 종류 `직접입력`(`FoodType.custom`)도 사이즈·마릿수를 그대로 받는다 (이름만 사용자가 적는 것)
- 급여량 자유 입력은 `size_label`(VARCHAR 10)에 저장 — 재로딩 시 값이 칩 목록에 없으면 직접입력 모드로 복원

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

### 알림 수신 설정 (V4, 2026-08-20)

`user_notification_pref` — **유저당 1행, 종류당 1컬럼**(routine / comment / post_like).
행이 아니라 컬럼인 이유: 이 조회는 알림을 보낼 때마다 도는 경로다.

- **행이 없으면 전부 켜짐.** 처음 하나를 끌 때 lazy 하게 생성한다 → 기존 유저 백필이 필요 없다
- **끈 것은 푸시일 뿐 기록이 아니다.** 억제돼도 `notification_log_dtl` 행은 그대로 쌓여 앱 내
  알림함에 보인다. 상태는 `SKIPPED` — `SENT` 로 두면 발송 통계가 거짓이 되고 `FAILED` 는 장애 알람을 울린다
- **억제 지점은 `NotificationService.save()` 한 곳.** 모든 발송이 여기를 지나므로 다른 데서 검사하지 말 것
- **`SYSTEM`(공지)은 끌 수 없다** — 요청 DTO에 필드 자체가 없다. 끌 수 없는 항목의 필드를 열어두고
  서버가 조용히 무시하면 "껐는데 계속 온다"가 된다. 응답에는 `system: true` 로 내려 앱이 '항상 켜짐'을 표시
- **마케팅의 단일 진실은 `user_agreement_dtl`(법적 원장)이지 이 테이블이 아니다.**
  `NotificationPrefService` 는 `AgreementService.changeOptionalAgreement` 로 위임만 한다. ⛔ 여기에 컬럼을 만들지 말 것
- `UserNotificationPref.allows()` 의 default 는 **true**(보낸다) — 새 타입이 조용히 안 가는 것보다 가는 게 눈에 띈다
- 앱: `/my/notifications` → `NotificationSettingsScreen`. 낙관적 갱신 + 실패 시 롤백.
  OS 알림 권한이 꺼져 있으면 상단 경고 배너(권한 없으면 앱 안 토글이 다 켜져 있어도 알림이 안 와 앱 버그로 보인다)

### FCM 푸시 알림
- Firebase 프로젝트: `tailog-bba42` (project_number `326050818454`), Android 패키지 `me.tailog.app`
  - `tailog` 는 전역 선점되어 있어 콘솔이 접미사를 붙였다. 사용자 비노출 값이라 그대로 쓴다.
  - 구 프로젝트 `bit-pet`(`531955989389`)은 개명과 함께 폐기 — 기기 토큰이 프로젝트 스코프라 전부 재등록된다.
- **클라이언트 설정**: `bitpet_app/android/app/google-services.json` + `lib/firebase_options.dart` (둘 다 같은 값 — 하나 바뀌면 같이 갱신)
  - **둘 다 gitignore 됨** (레포가 public이라 API 키 노출 방지) → 새 PC에서 클론하면 이 두 파일이 없어 **빌드 실패**함
  - Firebase Console > 프로젝트 설정 > 내 앱 > `google-services.json` 다운로드 → `bitpet_app/android/app/`에 배치
  - `firebase_options.dart`는 google-services.json 값을 그대로 옮긴 것 (apiKey/appId/messagingSenderId/projectId/storageBucket)
- **서버 자격증명**: `bitpet_server/secrets/firebase-service-account.json` (gitignore 됨)
  - Firebase Console > 프로젝트 설정 > 서비스 계정 > 새 비공개 키 생성
  - 경로 변경은 `BITPET_FCM_CREDENTIALS`, 끄려면 `BITPET_FCM_ENABLED=false`
  - **키가 없으면 푸시만 꺼지고 서버는 정상 기동** — 알림은 `notification_log_dtl`에 계속 쌓이므로 앱 내 알림함은 동작
- **발송 흐름**: `NotificationService.save()` → `FcmSender.send()` → 유저의 `device_token_rls` 토큰 전체로 멀티캐스트
  - `UNREGISTERED`/`INVALID_ARGUMENT` 응답 토큰은 자동 삭제
  - 푸시 실패는 알림 이력을 롤백시키지 않음 (status만 FAILED)
  - data 페이로드: `notificationId, type, petId, routineId, referenceId, petCount`
- **토큰 API**: `POST /api/v1/device-tokens` (upsert) / `DELETE /api/v1/device-tokens?deviceToken=` (로그아웃)
- **앱 측**: `core/push/push_service.dart` — 로그인 성공/앱 시작 시 `initialize()`, 로그아웃 시 `unregisterToken()`
  - 알림 채널 ID `bitpet_default_channel` 은 AndroidManifest·서버 설정·PushService 3곳이 일치해야 함
  - 포그라운드 알림은 OS가 안 띄우므로 `flutter_local_notifications`로 직접 표시
- **iOS 미구현**: Apple 개발자 계정 + APNs 인증 키 + `GoogleService-Info.plist` 필요. 현재 iOS는 `firebase_options.dart`에서 `UnsupportedError` → main에서 catch되어 푸시 없이 실행

### NFC 태그 이름표 (v2)
- **핵심 원칙**: 태그에는 `https://tailog.me/t/{tagCd}` **URL만** 굽혀 있고, 태그↔개체 연결은 **서버 DB에만** 존재
  - 앱은 태그에 **쓰지 않는다**(굽는 건 생산 공정). 읽기는 두 경로다:
    1. **딥링크** — 앱이 꺼져 있거나 배경일 때. OS가 URL을 열고 `TagResolverScreen` 이 받는다
    2. **앱 내 스캔** — `core/nfc/NfcPetScanSheet`. `nfc_manager`(3.x) 로 NDEF(URL)만 읽는다. **UID는 쓰지 않는다**
  - ⚠️ **v1의 "앱은 NFC를 읽지 않는다 → `nfc_manager` 불필요"는 폐기됐다.** 뒤집은 이유는 읽기가 아니라 **선점**이다.
    앱이 떠 있는 상태에서 태그를 탭하면 App Link 인텐트가 발동해 현재 화면이 개체 상세로 갈아엎힌다
    (부모 개체를 고르던 중에 그 개체 상세로 튕겨나간다). `NfcManager.startSession` 은 Android 에서
    `enableReaderMode` 를 켜므로 그동안 인텐트가 우리 콜백으로 대신 들어온다.
    **시트를 닫을 때 `stop()` 을 빠뜨리면 리더 모드가 살아남아 딥링크가 통째로 죽는다** — `dispose` 에서 반드시 해제
  - URL 파싱은 관대하게: `core/nfc/tag_url.dart`. 호스트 접미 일치(`www.`·서브도메인) + `/t/{code}` 세그먼트에서 코드만 뽑아 **대문자 정규화**.
    우리 호스트가 아니면 '**tailog 이름표가 아닙니다**' 안내
- `tag_cd` = **Crockford Base32 랜덤 6자** (`TagCodeGenerator`, `0123456789ABCDEFGHJKMNPQRSTVWXYZ` — I/L/O/U 제외).
  **일련번호와 완전히 다른 체계, 절대 순차 금지** (순차면 남의 태그 주소를 추측 가능)
  - V52 이전은 `BP` + 랜덤 4자였다. 고정 접두사가 경우의 수를 32⁴(105만)로 묶어버려 접두사를 떼고 6자 전부 랜덤(32⁶ ≈ 10.7억)으로 넓혔다
  - **생성기 POOL 과 DB `ck_nfc_tag_mst_cd_format` 은 같은 집합이어야 한다.** 구 POOL 은 L/U 를 허용했으므로 V52 는 위반 행이 있으면 코드를 찍어주고 멈춘다
  - 조회 시 서버가 `toUpperCase()` 정규화 후 처리하고, DB 도 `ck_nfc_tag_mst_cd_upper` 로 소문자 행을 막는다 (정규화가 빠지면 PK 가 갈라져 같은 태그가 두 행이 됨)
- ⛔ **태그별 기본 동작(`default_action_cd`)은 V52에서 제거됐다 — 되살리지 말 것.**
  축이 잘못된 설계였다. 작업 종류는 태그가 아니라 **그날의 작업**에 종속된다 (급여일엔 전부 급여, 체중 재는 날엔 전부 체중).
  태그마다 동작을 고정해두면 오히려 방해가 된다. 스캔하면 개체 상세로만 들어간다
- **태그 생애주기** `nfc_tag_mst.status` (V51): `STOCK`(미판매) → `SOLD`(판매·미연결) → `BOUND`(연결됨) / `REVOKED`(분실·복제로 영구 차단)
  - `unlink()` 는 `STOCK` 이 아니라 **`SOLD`** 로 되돌린다 — 이미 유저 손에 넘어간 태그다
  - `chip_type` 기본 `NTAG203` — **패스워드 보호 불가 세대라 락 미적용 출고**. `batch_no` 는 불량 회수 단위
  - **REVOKED 는 404 가 아니라 `TagStatus.REVOKED`** 로 내려 "사용 중지된 태그" 안내를 띄운다 (실재하는 코드와 위조 코드를 구분). 연결 시도는 `TAG_REVOKED` 410
  - 어드민 회수: `POST /admin/tags/revoke?tagCds=`, `POST /admin/tags/revoke-batch?batchNo=` (되살리는 API 는 없음)
- **스캔 횟수는 서버에 쌓지 않는다** (V51에서 `scan_cnt`/`last_scan_at` 제거) — 스캔마다 UPDATE 가 도는 구조였다. 사용률은 클라이언트 애널리틱스 이벤트로 본다
- **테이블 분리**: `pet_mst`의 컬럼이 아니라 `nfc_tag_mst` 별도 테이블 — 재사용·해제·분실 처리가 깔끔
  - `unlink()`는 `pet_id`/`user_id`만 비우고 **`linked_at`은 남긴다** → "판매됐지만 미연결(온보딩 이탈)" 재고 쿼리가 가능해짐
  - 재고 쿼리: 미판매 = `pet_id IS NULL AND linked_at IS NULL` / 판매·미연결 = `pet_id IS NULL AND linked_at IS NOT NULL`
- **API** (`io.bitpet.nfc`) — 스캔·바인딩은 `/api/v1/nfc`, 태그 관리는 구 `/api/v1/tags`:
  - `GET /api/v1/nfc/tags/{tagCd}/resolve` → `NfcScanResponse{status, tagCd, pet}`. 상태 + **개체 카드**(`PetCardResponse`)를 한 번에.
    개체 상세를 다시 부르면 남의 개체에서 403 이 나기 때문에 카드를 여기서 같이 내린다
  - `POST /api/v1/nfc/bindings {tagCd, petId, rebind}` — **사육자(OWNER/KEEPER)면 붙일 수 있다** (`assertKeeper`).
    이름표는 개체 이름이 새겨진 채 팔려서 어느 개체용인지가 실물에 이미 박혀 있다 → 붙이는 데 소유권 판단이 필요 없고,
    같이 키우는 사람이 이름표를 샀는데 못 붙이는 쪽이 이상하다. 해제·이력 조회도 같은 기준
    ⛔ `pet_mst.user_id` 로 판정하지 말 것 (표시용 비정규화 값이고 고아 개체에선 null 이 된다)
    ⛔ 태그 권한을 `tag.user_id`(붙인 본인)만으로 보지 말 것 — 공동사육자가 붙인 이름표를 소유자가 못 떼게 된다.
    `assertCanManage` 는 "붙인 본인 **또는** 현재 붙어 있는 개체의 사육자"를 본다 (미연결 재고 태그는 개체가 없으므로 전자가 필요)
  - 구 경로는 태그 관리 화면이 계속 쓴다: `GET /api/v1/tags/{tagCd}`, `POST /{tagCd}/link`(**deprecated** — `bind`로 위임), `DELETE /{tagCd}/link`, `GET /tags/my`
- **남의 개체 스캔 시 필드 축소는 서버가 한다.** `PetCardResponse` 자체가 "남에게 보여도 되는 전부"(이름·종·모프·성별·해칭일)라
  사육기록·체중·커뮤니티 활동은 애초에 담기지 않고, `owner` 는 OWNED_BY_OTHER 에서 **null 로 비워 내보낸다**.
  ⛔ 클라이언트 숨김 처리로 대체하지 말 것 — 숨김은 응답을 까 보면 무너진다 (`NfcScanBindIntegrationTest` 가 이걸 검증한다)
- **재연결(rebind)은 확인을 강제한다**: 내 다른 개체에 붙어 있는 태그면 409 `TAG_REBIND_CONFIRM_REQUIRED`(어느 개체인지 메시지에 담김)
  → 앱이 확인 다이얼로그를 띄우고 `rebind=true` 로 재요청. 남의 개체에 붙은 태그는 409 `TAG_ALREADY_LINKED` — 확인으로 넘길 수 없다
  - ℹ️ **rebind 는 "이름표를 다른 개체로 옮기는 기능"이 아니다.** 이름이 각인돼 있어 실제 이동은 성립하지 않는다.
    실사용은 **잘못 붙인 걸 되돌리는 것**(각인은 '레오'인데 목록에서 옆 개체를 눌러버림) 하나뿐이므로, 막지 말고 확인만 받는다
- **연결 이력** `nfc_tag_bind_hst` (V55, append-only): BIND/REBIND/UNBIND/REVOKE. 실물 태그는 손을 옮겨 다니고
  "내 태그를 가로챘다"는 신고는 현재 상태만으로 판정할 수 없다. 개체 물리 삭제·차단으로 끊긴 것도 `actor_id = NULL` 로 남긴다
  - 어드민: `POST /api/v1/admin/tags/issue?count=&chipType=&batchNo=` (재고 발급), `GET /api/v1/admin/tags/stats` (unsold/linked/released/revoked),
    `POST /api/v1/admin/tags/bindings?tagCd=&petId=` (**출고 전 사전 연결** — 사육자 검증 없음. 태그 소유자는 어드민이 아니라 **개체의 소유자**로 달고, 이력 `actor_id` 에 어드민을 남긴다)
- 🚨 **`/api/v1/admin/**` 은 URL 로 보호되지 않는다.** `SecurityConfig` 는 `publicPaths` 외 전부 `anyRequest().authenticated()` 뿐이라
  **로그인만 하면 아무나 도달한다.** 어드민 컨트롤러는 메서드마다 `AdminGuard.assertAdmin(principal.userId())` 를 직접 호출할 것
  (`admin_role_rls` 조회. JWT role 클레임은 발급 시점 스냅샷이라 권한 회수가 즉시 반영되지 않으므로 쓰지 않는다).
  ⛔ 새 어드민 엔드포인트를 추가하면서 가드를 빠뜨리지 말 것 — 태그 영구 차단처럼 되돌릴 수 없는 동작이 열려 있다
- **딥링크 공개 경로** (`public-paths`): `/.well-known/**`, `/t/**`
  - `AssetLinksController` — 지문 미설정 시 **404 반환** (지문 없는 파일은 autoVerify를 조용히 실패시켜 링크가 브라우저로 샌다)
  - `TagLandingController` — 미설치·비로그인용 랜딩. **개체 이름만** 노출, 체중·급여 기록 절대 금지. 모르는 코드도 404 대신 일반 랜딩
- 🚨 **assetlinks.json 최대 함정**: AAB 업로드 시 Google이 **재서명**하므로 업로드 키 지문이 아니라
  **Play 앱 서명 키 지문**(Play Console > 설정 > 앱 서명, 업로드 후에만 보임)이 필요. 로컬 빌드 테스트를 위해 **둘 다** 넣을 것
  - 설정: `bitpet.deeplink.*` (`BITPET_ANDROID_SHA256` 등 환경변수)
- **앱 측**: `features/nfc/`
  - AndroidManifest — `autoVerify="true"` intent-filter (`https` / `tailog.me` / pathPrefix `/t/`) + `flutter_deeplinking_enabled` 메타데이터
    - ⚠️ 콜드 스타트: 앱이 꺼진 상태의 첫 링크는 go_router 초기화보다 먼저 도착 → 위 메타데이터 없으면 **홈으로 빠진다**. 반드시 앱 완전 종료 상태로 실기기 테스트
  - `/t/:tagCd` → `TagResolverScreen` (경유 화면, ShellRoute 바깥). status로 분기, 로그아웃 상태면 `PendingTagLink`에 담아두고 로그인 후 복귀
  - 개체 진입은 `context.go('/home')` → `context.push('/pets/:id')` — 홈을 스택 하단에 깔지 않으면 뒤로가기 한 번에 앱이 종료됨
  - 태그 스캔은 **기록 시트를 자동으로 열지 않는다** (V52). `?openRecord=feed|scale` 자동 오픈 자체는 `PetDetailScreen`에 남아 있지만 태그 경로에서는 쓰지 않는다
  - 마이페이지 > 이름표 관리(`/my/tags`) — 연결 해제만 (양도 시 원 소유자가 해제 → 새 주인이 재연결). 목록 캡션에 `사용 중지됨`/`chip_type` 표시
- **제작·출고**: 랜덤 코드 100개 발급(`/admin/tags/issue`, 배치번호 함께) → 칩(현재 입고분 **NTAG203**)에 URL 굽기 → 재고.
  주문이 들어오면 각인 이름을 받아 **PETG**(PLA는 사육장 열·습도에 변형) 3D 프린팅 → 재고 태그 하나를 부착.
  **이때 어느 개체용인지가 이미 정해지므로**(각인 이름 = 그 개체) `POST /admin/tags/bindings` 로 **출고 전에 붙여서 내보낸다**. 고객은 받아서 찍기만 하면 된다
  - 앱에서 고객이 직접 붙이는 경로(`POST /api/v1/nfc/bindings`)도 계속 유지한다 — 미연결로 나간 재고와 사전 연결 실패분 대비
- **v1.1+**: 양도 플로우, 사육장 단위 태그, iOS Universal Links (제품 라인업은 각인·외형으로만 구분 — 태그 데이터는 1종)

### 개체 권한 경계 — OWNER / KEEPER (2026-08-09 확정)

판정의 단일 소스는 `pet_keeper_rls` (`PetKeeperService`). ⛔ `pet_mst.user_id` 로 판정하지 말 것 —
표시용 비정규화 값이고 고아 개체에선 null 이 된다.

| | 범위 |
|---|---|
| `assertKeeper` (OWNER + KEEPER) | 기록·조회·루틴 / 프로필 수정·대표사진·`privateYn` / **이별 표시·취소** / **가계도 부모 연결·해제** / NFC 이름표 부착·해제 |
| `assertOwner` (OWNER 전용) | 개체 삭제·벌크 삭제 / 공유 초대·해제 / 입분양(소유권 이전) |

**기준은 "되돌릴 수 있는가 / 소유권이 움직이는가"** 이지 중요도가 아니다.

두 역할은 실질적으로 공동 사육자이고 **대부분 가족**이라, 일상 동작을 소유자에게 묶어두면 함께
키우는 쪽이 계속 막힌다. 동시에 **사장-직원처럼 수직 관계**일 수도 있으므로 되돌릴 수 없거나
개체가 남에게 넘어가는 동작만 소유자에게 남긴다. 그 사이 것들은 전부 반대 동작이 있다
(이별↔이별 취소, 관계 등록↔해제).

- **이별(폐사)이 KEEPER 인 이유**: 소유권 판단이 아니라 **일어난 사실의 기록**이고, 그 사실을 먼저
  아는 사람이 소유자라는 보장이 없다. 소유자 계정을 기다리면 기록 시점이 어긋난다
- **가계도**: 판정 축이 **'자식 쪽'**이라는 게 핵심이고 OWNER냐 KEEPER냐가 아니다. 부모 쪽 소유자에게
  권한을 주면 그게 곧 차단 절차가 되어 '승인 없음' 원칙이 깨진다 (아래 V53 항목)
- **`privateYn` 은 KEEPER 유지** — 되돌릴 수 있고 소유권과 무관. 폼의 한 필드라 분리하지 않는다
  (2026-08-07 미결이었던 항목, 여기서 닫힘)
- ⚠️ **REST 와 sync push 의 경계는 반드시 같아야 한다.** `SyncService` 의 pet upsert 가 `assertOwner`
  로 남아 있어 "REST 로는 이름이 고쳐지는데 오프라인 동기화만 403" 이던 불일치가 있었다
- **역할 세분화(STAFF 등)는 실제 수직 관계 사용자가 생긴 뒤에** 한다. `PetKeeperRole` enum 에 값을
  더하는 쪽이, 열어둔 권한을 나중에 회수하는 것보다 싸다

### 가계도 부모 등록 (V53)
- **부모는 항상 실존 개체(`pet_mst`) 참조.** 텍스트 직접 입력 없음. 폐사(DECEASED) 개체도 부모로 등록 가능
- **소유자와 무관하게 등록 가능. 승인·차단 절차 없음** — 남의 개체를 내 가계도에 부모로 걸 수 있다
  - `addRelation`은 **자식만** 사육자 검증(`assertKeeper`), 부모는 실존 여부만 본다
  - `deleteRelation`도 **자식 쪽 사육자만**. 부모 소유자에게 삭제권을 주면 그게 곧 차단 절차가 되어 "승인 없음" 원칙이 깨진다
  - ℹ️ 판정 축은 **'자식 쪽'**이지 OWNER/KEEPER 가 아니다 (2026-08-09 `assertOwner`→`assertKeeper`). 위 권한 경계 항목 참고
  - 자기 자신(`PET_RELATION_SELF`)·역방향 중복(`PET_RELATION_CYCLE`)만 막는다
- ⛔ **검증/승인 도메인은 만들지 않는다** (`pedigree_verify_req`, `verify_status`, `verify_source` 등). 사칭 억제는 아래 소유자 노출로 대신한다
- **소유자 노출**: 가계도 노드에 `owner { userId, nickname, isMe, isOrphaned }`.
  `isMe`/`isOrphaned`는 **서버가 판정해서 내린다** — 앱이 currentUserId와 비교하게 두면 같은 분기가 화면마다 흩어진다
  - `isOrphaned` = `user_id IS NULL`(V53 익명화) **또는 탈퇴로 소프트 삭제된 계정**. 화면에선 둘 다 '정보 없음'
- **가계도 노드는 `PetResponse`가 아니라 `PetCardResponse`** — 남의 개체가 섞이는 자리라 메모·입양일·최근 체중이 따라 나가면 안 된다
  - `isKeeper`(전체 상세 가능) / `canOpenDetail`(= isKeeper || 공개)을 서버가 파생시켜 내린다
- API: `GET /pets/{petId}/genealogy`, `GET /pets/{petId}/public`(비공개는 404), `GET /users/{userId}/profile`,
  `GET /pets/by-serial/card`(부모 선택용 — **정확 일치**로만 남의 개체를 연다. 목록 열람은 없음)
- 앱: `PedigreeParentCard`(썸네일 + 소유자 12sp / 개체명 15sp, **탭 타겟 분리**), 비공개 개체는 최소 정보 바텀시트,
  화면 `/pets/:id/public`·`/users/:userId`
  - 소유자 줄은 `isMe`면 **아예 렌더링하지 않는다**. 유저명이 보인다 = 남의 개체라는 신호

### 회원 탈퇴 개체 처리 (V54)

`AuthService.withdraw` → `PetWithdrawalService.process(userId)` → 계정 소프트 삭제까지 **한 트랜잭션**.

- **순서가 핵심**: ① 탈퇴자 개체끼리의 상호 참조(`pet_relation_rls` 부모·자식이 **둘 다** 탈퇴자 개체인 행)와
  탈퇴자 소유 `mating_dtl` 을 **먼저** 지운다 → ② 그래야 남는 게 '남이 거는 참조'뿐이라 판정이 정확해진다
  - 이 선행 처리가 없으면 "가입 → 자기 개체끼리 연결 → 바로 탈퇴" 계정의 개체가 전부 보존돼 쓰레기가 된다
  - ⚠️ **자식 쪽 행까지 참조로 세지 말 것.** 참조는 `parent_pet_id = 내 개체` 인 행만 센다.
    양방향으로 세면 참조가 절대 0이 되지 않아 정리 배치가 영원히 동작하지 않는다
- **분기** — (A) 참조 0건 → `pet_mst` + 기록·사진·루틴 전부 물리 삭제 /
  (B) 참조 1건 이상 → `user_id = NULL, is_orphaned = true` 로 **익명화 보존**
  - (B) 유지 항목: **개체명**(혈통 식별의 핵심), species, morph, sex, hatched_at, 부모 참조.
    사육 기록 전부 삭제, 사진은 **대표 1장만** 남기고 나머지 삭제
  - 양쪽 다 `nfc_tag_mst` 는 `unlink()` 로 pet_id/user_id 만 비우고 상태는 **`SOLD` 유지**.
    ⛔ **STOCK 으로 되돌리지 말 것** — 계정이 사라져도 태그 실물은 그 사람 손에 있고 굽힌 URL 은
    락이 걸려 바꿀 수 없다. 회수해 되팔 수 있는 물건이 아니라서 STOCK 으로 세면 재고 수치만 거짓이 된다
  - **공유 개체(KEEPER)는 사용자가 탈퇴 화면에서 고른다** — `DELETE /auth/withdraw?handOverSharedPets=`
    - `true`(기본) → 최초 합류 KEEPER 에게 **기록·사진째** 소유권 이전(`promoteToOwner`).
      `false` → 다른 개체와 똑같이 삭제/익명화, 공동 사육자는 접근권을 잃는다
    - 자동으로 정하지 않는 이유: "내 기록을 남의 계정에 남기고 싶지 않다"와 "함께 보던 사람에게
      남겨주고 싶다"는 둘 다 정당하다. 값이 안 오면 **넘기는 쪽이 기본** — 지운 건 되돌릴 수 없다
    - 선택 단위는 **개체별이 아니라 일괄**. 대신 `GET /auth/withdraw/preview` 로 개체명과
      받게 될 사람을 미리 보여줘 결과를 감추지 않는다 (목록이 비면 앱은 선택지를 띄우지 않는다)
    - ⚠️ 이전 순서: **탈퇴자 OWNER 행을 지우고 flush 한 뒤** 승격해야 한다. 반대로 하면 OWNER 가
      잠시 둘이 되어 `idx_pet_keeper_owner` 유니크 제약에 걸린다
- **고아 개체 신규 참조 차단은 API 레벨에서**: `PetService.addRelation`(→ `PET_ORPHANED` 409),
  `findCardBySerial`/`findBySerial`(→ 404), `MatingService.create/update`, `NfcTagService.resolve/peekPetName`.
  기존 참조는 유지되므로 가계도에는 계속 보인다 → 참조 수가 **단조 감소**해 자연 소멸한다
- **정리 배치** `OrphanPetCleanupScheduler` — 매일 03:10 KST. `pet_relation_rls`·`mating_dtl` 어디서도
  참조되지 않는 고아를 물리 삭제하고, 연쇄 삭제가 생기므로 **더 지울 게 없을 때까지 라운드를 반복**한다
- **S3 는 커밋 직후 비동기**: 트랜잭션 안에서는 `s3_delete_queue_dtl` 에 키를 적재만 하고
  (`S3DeleteQueueService.enqueue`, `Propagation.MANDATORY`), `S3DeleteQueueDrainer`가
  `@TransactionalEventListener` + `@Async` 로 **커밋된 직후 바로** 지운다
  - 큐 테이블의 목적은 "나중에 몰아 지우기"가 **아니라** S3 호출을 트랜잭션 밖으로 빼는 것이다 —
    안에서 지우면 이후 롤백 시 파일만 사라지고, 반대로 S3 장애가 탈퇴를 롤백시킨다
  - ⛔ **`@Scheduled` 는 정상 경로가 아니라 재시도 그물이다** (1시간 주기, 최대 10회).
    S3 일시 장애로 실패했거나 커밋~삭제 사이에 서버가 죽어 남은 행만 줍는다.
    주기를 분 단위로 조이지 말 것 — 평소엔 빈 큐를 확인하는 쿼리만 반복된다
  - 배치 루프를 `S3DeleteQueueService` 밖(`Drainer`)에 둔 건 프록시 경유로 **배치마다 독립 트랜잭션**을
    만들기 위해서다. 한 트랜잭션으로 묶으면 중간에 터질 때 성공 기록까지 날아가 같은 키를 또 지운다
- ⚠️ **`photo_dtl` 은 폴리모픽이라 FK 가 없다** — CASCADE 가 안 걸리므로 개체의 PET/MEMO/MATING/LAYING
  사진을 서브쿼리로 긁어 수동 삭제해야 한다 (`PetPurgeRepository.PHOTO_SCOPE`)
- ⚠️ 물리 삭제는 **네이티브 쿼리로** 한다. `@SQLRestriction("deleted_at IS NULL")` 때문에 JPQL·파생 쿼리는
  소프트 삭제된 행에 닿지 못한다

### 가계도 닉네임 공개 설정 (V54)
- `user_mst.show_nickname_in_pedigree` (기본 true). `PATCH /api/v1/auth/me` 의 `showNicknameInPedigree`
- false면 응답의 nickname 을 **'비공개'로 치환하고 `userId` 를 아예 내리지 않는다**(프로필 이동 불가).
  `GET /users/{userId}/profile` 도 `USER_PROFILE_HIDDEN` 403. 단 **본인에게는 그대로 노출**한다
- **'정보 없음'(isOrphaned=주인 없음)과 '비공개'(주인은 있으나 숨김)는 다른 상태다.** 앱도 구분해 표시:
  `PedigreeParentCard`, `parent_pet_bottom_sheet`, `pet_form_screen`, `public_pet_screen` 네 곳이 같은 분기를 쓴다

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
  (2026-08-19 스쿼시 이후 V2~V4 추가됨, **다음은 V5**. `V1__baseline_schema.sql` 수정 = 모든 DB 기동 불가)

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
- **`IntegrationTestBase` 에 `@Testcontainers`/`@Container` 를 붙이지 말 것.** 그 조합은 컨테이너 수명을
  테스트 클래스 단위로 관리해서, 첫 클래스가 끝나면 static 컨테이너를 멈춰버린다 → 두 번째 클래스부터
  전부 `CannotCreateTransactionException(ConnectException)`. static 블록에서 직접 `start()` 하는
  싱글턴 방식이 정답 (테스트 클래스가 하나뿐이면 드러나지 않는 함정)

# 2026-05-09 — Flyway 도입 + OAuth2 + Testcontainers + 도메인 설계

| 항목 | 값 |
|---|---|
| 날짜 | 2026-05-09 (작업은 2026-05-08 시작 → 2026-05-09 마무리) |
| 모델 | Claude Opus 4.7 (`claude-opus-4-7`) |
| 작업 위치 | `C:\Users\subin\IdeaProjects\Bit-Pet` |
| 커밋 | `13bf149` (master) |
| 변경 통계 | 32 files changed, 1378 insertions(+), 129 deletions(-) |
| 빌드 | `clean compileJava + compileTestJava` → BUILD SUCCESSFUL |

## 한 줄 요약
백엔드 초기 세팅 단계 마무리 — Flyway 도입과 ERD(`_mst`/`_rls`) 기준 user 도메인 정렬, OAuth2(Google/Kakao/Naver) 로그인 구현, Testcontainers 통합 테스트 골격, 커뮤니티 + 오프라인 동기화 설계 문서까지 한 번에 진행.

---

## 진행한 작업

### A. Flyway 도입 + ERD user 도메인 정렬 (2026-05-08 작업 → 5/9 푸시)
- `build.gradle.kts`: `flyway-core`, `flyway-database-postgresql`
- `application.yml`: `spring.flyway.{enabled,locations,baseline-on-migrate,validate-on-migrate}`
- `application-local.yml`: `ddl-auto: update` → `validate` (prod는 이미 validate)
- `db/migration/V1__init_schema.sql` — `user_mst`, `user_oauth_rls` (인덱스/FK/UNIQUE/CHECK)
- `db/migration/V2__pets.sql` — 기존 pets 테이블을 Flyway 통제로 편입
- 엔티티/도메인 정렬:
  - `User` → `UserMst` (`@SQLRestriction("deleted_at IS NULL")`)
  - 새 필드: profileImageUrl / userType / lastLoginAt / deletedAt
  - `UserOAuthRls` 신규 (UserMst @ManyToOne)
  - `Role` → `UserType{GENERAL, ADMIN}`
  - `AuthProvider` → `OAuthProvider{GOOGLE, KAKAO, NAVER}`
  - `UserRepository` → `UserMstRepository`, `UserOAuthRlsRepository` 신규
  - JWT claim 키 `role` 유지, 값만 `userType.name()`로
  - `UserResponse` DTO: `userType`, `profileImageUrl` 노출

### B. OAuth2 (Google / Kakao / Naver) 로그인
- `application.yml`: `spring.security.oauth2.client.{registration,provider}` + `bitpet.oauth2.{success,failure}-redirect-uri`, public-paths에 `/oauth2/authorization/**`, `/login/oauth2/code/**`
- 신규 `io.bitpet.auth.oauth/`:
  - `OAuth2UserInfo` 인터페이스 + Google/Kakao/Naver 구현 + `OAuth2UserInfoFactory`
  - `OAuth2UserPrincipal` (Spring Security `OAuth2User` 어댑터, `UserMst` 보유)
  - `OAuth2Properties` (`@ConfigurationProperties("bitpet.oauth2")`)
  - `CustomOAuth2UserService` — `(provider, providerUserId)` 조회 → 없으면 이메일로 UserMst 조회 → 없으면 `UserMst.createOAuth(...)` (랜덤 BCrypt 주입), `UserOAuthRls` 생성
  - `OAuth2SuccessHandler` — JWT 발급 + Redis refresh 저장 + `successRedirectUri?accessToken=…&refreshToken=…` 리다이렉트
  - `OAuth2FailureHandler` — 실패 시 `failureRedirectUri?error=…` 리다이렉트
- `SecurityConfig`: `ObjectProvider<ClientRegistrationRepository>`로 OAuth 클라이언트 키 없을 때도 앱 부팅 가능 (조건부 `oauth2Login`)
- `UserMst.createOAuth(...)` 팩토리, `password_hash NOT NULL` 유지하기 위해 OAuth 사용자에게 랜덤 UUID + BCrypt 주입 (로그인에 매칭되지 않음)
- `ErrorCode`: `AUTH_OAUTH_PROVIDER_NOT_SUPPORTED`, `AUTH_OAUTH_USER_INFO_MISSING` 추가
- 카카오 등 이메일 미제공 케이스 → `kakao_<id>@oauth.bitpet.local` 신택틱 이메일

### C. Testcontainers 통합 테스트 골격
- `build.gradle.kts`: `spring-boot-testcontainers`, `testcontainers:junit-jupiter`, `testcontainers:postgresql`
- `src/test/resources/application-test.yml`
- `src/test/java/io/bitpet/support/IntegrationTestBase.java`
  - Postgres `@ServiceConnection`
  - Redis `GenericContainer` + `@DynamicPropertySource`
  - `@SpringBootTest` + `@AutoConfigureMockMvc` + `@ActiveProfiles("test")`
- `src/test/java/io/bitpet/auth/AuthFlowIntegrationTest.java`
  - `signup → login → refresh` 토큰 교체 플로우
  - 이메일 중복 시 409
- 실행은 사용자 환경에서 Docker Desktop 켠 뒤 `./gradlew test`

### D. 도메인 설계 문서 (저장소 내)
- `docs/community-feed-design.md` — `_mst/_dtl/_rls/_cd` 적용 ERD 초안 (post_mst, comment_mst, *_like_rls, follow_rls, bookmark_rls, tag_mst, post_tag_rls, report_dtl 등) · 18개 API 초안 · 피드 v1 pull → v1.5 Redis cache → v2 fan-out · V3~V6 마이그레이션 계획
- `docs/offline-sync-design.md` — 서버 LWW + tombstone · per-row `sync_version`(전역 시퀀스) · `(client_id, client_change_id)` 멱등성 · `/api/v1/sync/changes`, `/api/v1/sync/push` API · M1(pet) → M5(CRDT) 로드맵

### E. Notion 진행상황 페이지
- 신규 페이지: [2026-05-09] Flyway 도입 + ERD 기준 user 도메인 정렬
  - https://www.notion.so/35adadff16ba81d8b8f7df7fcb1c6a2c
- Bit-pet 페이지 "진행상황" 컬럼 안으로 이동은 사용자가 직접 처리
- 4개 다음 단계 항목 모두 체크 + 결과 섹션 추가

---

## 주요 결정사항

| 영역 | 결정 | 이유 |
|---|---|---|
| 스키마 관리 | Flyway 단일 통제, JPA `validate` | 운영 안정성, 변경 이력 추적 |
| 명명 규칙 | `_mst`/`_dtl`/`_rls`/`_cd` | 사용자 ERD 규칙 적용 |
| Soft Delete | `deleted_at TIMESTAMPTZ NULL` + `@SQLRestriction` | 사용자 데이터는 복구 여지 보존 |
| OAuth 사용자 password_hash | 랜덤 BCrypt 주입 | ERD `NOT NULL` 제약 유지, 보안 영향 없음 |
| OAuth 미인증 키 | `ClientRegistrationRepository` 조건부 wiring | 키 없어도 앱 부팅 가능 |
| 동기화 모델 | 서버 LWW + tombstone (v1) | 1인-1기기 가정, 단순화 |
| 피드 전략 | v1 pull → v1.5 Redis cache → v2 fan-out | 점진적 도입 |
| Pet 도메인 | _mst 리네이밍 보류 | ERD 미확정, V3+에서 처리 |

---

## 다음 이슈 (GitHub 수동 등록용)

> `gh` CLI · `GITHUB_TOKEN` 둘 다 없어서 자동 등록 못 함. 아래 4개를 https://github.com/subin9804/bit-pet/issues/new 에서 그대로 복붙.
> 또는 `winget install GitHub.cli` → `gh auth login` → 다음 세션에서 자동 등록.

---

### Issue #1 — `[feat] 커뮤니티 도메인 V3~V6 마이그레이션 + 엔티티/API 구현`

**Labels:** `feature`, `backend`, `community`

**Body:**
```markdown
## 배경
[2026-05-09 진행상황](https://www.notion.so/35adadff16ba81d8b8f7df7fcb1c6a2c)에서 커뮤니티/피드 도메인 설계가 끝남 (`docs/community-feed-design.md`). 이제 마이그레이션과 엔티티/API를 단계적으로 구현.

## 작업
- [ ] V3: `tag_mst`, `post_type_cd`, `report_reason_cd`
- [ ] V4: `post_mst`, `post_image_dtl`, `post_tag_rls`
- [ ] V5: `comment_mst`, `post_like_rls`, `comment_like_rls`
- [ ] V6: `follow_rls`, `bookmark_rls`, `report_dtl`
- [ ] 각 단계마다 엔티티 + Repository + Service + Controller (Post → Comment → Like → Follow → Bookmark → Report)
- [ ] cursor 기반 페이지네이션 적용
- [ ] `like_count`, `comment_count` denormalized 갱신 로직
- [ ] Testcontainers 통합 테스트 추가

## 비범위
- 실시간 피드(WebSocket), 검색, 추천 — v2 이후
- Redis 피드 캐시 (v1.5 별도 이슈로)

## 참고
- 설계: `docs/community-feed-design.md`
- 명명 규칙: `_mst`/`_dtl`/`_rls`/`_cd`, 공통 컬럼 `created_at/updated_at/deleted_at`
```

---

### Issue #2 — `[feat] 오프라인 동기화 V7~V8 + Sync API (pet 우선)`

**Labels:** `feature`, `backend`, `offline-sync`

**Body:**
```markdown
## 배경
[2026-05-09 진행상황](https://www.notion.so/35adadff16ba81d8b8f7df7fcb1c6a2c)에서 오프라인 동기화 설계 완료 (`docs/offline-sync-design.md`). 모델: 서버 LWW + tombstone, per-row `sync_version`(전역 시퀀스), `(client_id, client_change_id)` 멱등성.

## 작업 (M1 — pet 도메인부터)
- [ ] V7: 모든 syncable 테이블에 `sync_version BIGINT NOT NULL`, `client_id VARCHAR(64)`, `client_change_id UUID` 컬럼 + 인덱스 추가
- [ ] V8: `sync_version` 단조 증가 보장 — PostgreSQL SEQUENCE + BEFORE UPDATE 트리거
- [ ] `GET /api/v1/sync/changes?since=<cursor>&resources=pet&limit=200` (tombstone 포함)
- [ ] `POST /api/v1/sync/push` (batch upsert/delete, APPLIED/CONFLICT/REJECTED 응답)
- [ ] cursor 포맷: `<server_max_updated_at_ms>_<sync_version>`
- [ ] echo 방지: `client_id` 일치 row는 응답에서 제외
- [ ] 멱등성 — `(client_id, client_change_id)` UNIQUE 충돌 시 기존 row 그대로 반환
- [ ] Testcontainers 기반 통합 테스트 (오프라인 시나리오 시뮬레이션)

## 다음 마일스톤 (별도 이슈)
- M2: post / comment / 인터랙션 sync 확장
- M3: 충돌 시 사용자 머지 UI
- M4: WebSocket 실시간 push

## 참고
- 설계: `docs/offline-sync-design.md`
```

---

### Issue #3 — `[chore] OAuth2 클라이언트 키 발급 + Google/Kakao/Naver 종단간 동작 검증`

**Labels:** `chore`, `auth`

**Body:**
```markdown
## 배경
OAuth2 코드 구현은 끝났음 (`io.bitpet.auth.oauth.*`). 이제 실제 클라이언트 키를 발급해 종단간 흐름 검증 필요.

## 작업
- [ ] Google Cloud Console — OAuth 2.0 클라이언트 생성, redirect URI: `http://localhost:8080/login/oauth2/code/google`
- [ ] Kakao Developers — REST API 키 발급, redirect URI: `http://localhost:8080/login/oauth2/code/kakao`
- [ ] Naver Developers — 애플리케이션 등록, redirect URI: `http://localhost:8080/login/oauth2/code/naver`
- [ ] 환경변수 설정:
  - `BITPET_OAUTH_GOOGLE_CLIENT_ID/SECRET`
  - `BITPET_OAUTH_KAKAO_CLIENT_ID/SECRET`
  - `BITPET_OAUTH_NAVER_CLIENT_ID/SECRET`
  - `BITPET_OAUTH_SUCCESS_REDIRECT`, `BITPET_OAUTH_FAILURE_REDIRECT`
- [ ] 각 provider별 종단간 검증:
  - `/oauth2/authorization/{provider}` → provider 로그인 → 콜백 → JWT 발급 → 프론트로 redirect
  - `user_mst` row 생성 (신규 사용자)
  - `user_oauth_rls` row 생성
  - 재로그인 시 같은 `user_mst.id`로 매핑
- [ ] 카카오는 이메일 동의 옵션 — 이메일 없을 때 신택틱 이메일(`kakao_<id>@oauth.bitpet.local`) 동작 확인
- [ ] prod 배포 시 `BITPET_OAUTH_*` Secret 등록

## 비범위
- 모바일 앱(딥링크) 흐름은 클라이언트 팀 작업
```

---

### Issue #4 — `[docs] ERD_v2 Notion 페이지에 커뮤니티 도메인 반영`

**Labels:** `documentation`

**Body:**
```markdown
## 배경
[ERD_v1](https://www.notion.so/356dadff16ba8176a4c0cfad9cbafc67)은 user/pet 중심. 5/9 세션에서 커뮤니티 도메인 ERD 초안이 정리됨 (`docs/community-feed-design.md`).

## 작업
- [ ] Bit-pet > DB 컬럼에 ERD_v2 페이지 신규 생성
- [ ] user_mst, user_oauth_rls (확정 스키마)
- [ ] pet_mst (현재 `pets` → 추후 정렬 예정 표기)
- [ ] post_mst, post_image_dtl, post_tag_rls, tag_mst
- [ ] comment_mst
- [ ] post_like_rls, comment_like_rls, bookmark_rls, follow_rls
- [ ] report_dtl, report_reason_cd, post_type_cd
- [ ] sync 컬럼 (`sync_version`, `client_id`, `client_change_id`)도 별도 섹션 표기
- [ ] 다이어그램(figjam 또는 dbdiagram) 첨부 검토

## 참고
- `docs/community-feed-design.md`
- `docs/offline-sync-design.md`
```

---

## 사용자 다음 액션
1. Bit-pet Notion 페이지 "진행상황" 컬럼 안으로 [2026-05-09] 페이지 이동
2. https://github.com/subin9804/bit-pet/issues/new 에서 위 4개 이슈 등록
3. (또는) `winget install GitHub.cli` → `gh auth login` → 다음 세션에서 자동 등록 가능
4. Docker Desktop 켜고 `./gradlew test` 로 Testcontainers 흐름 1회 검증
5. OAuth 클라이언트 키 발급 시작 (Issue #3)

---

## 메모 / 학습
- Notion MCP integration이 Bit-pet 페이지 트리에서 일부 페이지(특히 "진행상황" 컨테이너 페이지)에 쓰기 권한이 없음 — 새 페이지는 Bit-pet 직속으로 생성된 뒤 사용자가 컬럼 안으로 이동해야 함
- `gh` CLI · `GITHUB_TOKEN` 환경변수 둘 다 없어 GitHub 이슈 자동 등록은 이번 세션에서 불가
- Spring Boot 3.5의 `@ServiceConnection`은 PostgreSQL은 자동 binding되지만 Redis는 별도 처리(GenericContainer + DynamicPropertySource) 필요

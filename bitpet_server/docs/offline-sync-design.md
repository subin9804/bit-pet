# 오프라인 동기화 (Local-First) 계층 설계 (v1 초안)

작성일: 2026-05-09 · 상태: **초안 (착수)**

## 1. 목표
- 클라이언트(앱)에 SQLite 미러 — 오프라인에서도 읽기/쓰기 가능
- 네트워크 복구 시 변경사항 자동 동기화
- 충돌은 **서버 LWW(Last-Write-Wins)** 기준, 충돌 발생을 클라이언트에 알려 UI에서 처리 가능하게

## 2. 동기화 모델 결정

| 후보 | 선택 | 이유 |
|---|---|---|
| **LWW + 서버 시계** | ✅ v1 | 단순. `updated_at`(서버 시계) 비교로 결정. 사용자 1인-1기기 가정에서 충돌 거의 없음 |
| Vector clock | ❌ | 다중 기기 동시 편집이 흔하지 않은 도메인 |
| CRDT | ❌ | 구현 복잡도 ↑, v1엔 불필요. 실시간 협업이 들어오면 v3+에서 검토 |

## 3. 동기화 가능한 리소스 (Syncable)
v1 대상:
- `user_mst` (자기 자신)
- `pet_mst` (owner_id = me)
- `post_mst` + `post_image_dtl` (author_id = me)
- `comment_mst` (author_id = me)
- `bookmark_rls`, `follow_rls`, `post_like_rls` (user_id = me)

비대상 (서버 권위):
- 카운트 컬럼 (like_count, comment_count) — 서버 계산값
- `report_dtl`, 운영 관련 테이블

## 4. 스키마 추가 사항

### 4.1 모든 syncable 테이블에 추가
```sql
ALTER TABLE <syncable_table>
  ADD COLUMN sync_version BIGINT NOT NULL DEFAULT 1,
  ADD COLUMN client_id VARCHAR(64) NULL,           -- 변경을 만든 클라이언트 device id
  ADD COLUMN client_change_id UUID NULL;           -- 동일 변경 멱등성 보장 (중복 push 방어)

CREATE UNIQUE INDEX uk_<table>_client_change_id
  ON <syncable_table> (client_id, client_change_id) WHERE client_change_id IS NOT NULL;
```
- `sync_version`: PostgreSQL 시퀀스 또는 트리거로 단조증가. 전역(per-user partitioned) 단일 카운터 유지.
- `client_id`: 어떤 기기가 만든 변경인지 식별 → echo 방지 (push한 클라이언트에는 그 변경을 다시 안 내려줌)
- `client_change_id`: 클라이언트가 발급한 UUID. 같은 변경이 두 번 들어와도 무시.

### 4.2 변경 로그(옵션, v1에선 불필요)
- 단일 테이블 `sync_change_log` 도입은 보류
- 대신 각 테이블의 `(updated_at, sync_version)` 조회로 변경 추적

## 5. API

### 5.1 Pull — 변경사항 조회
```
GET /api/v1/sync/changes?since=<cursor>&resources=pet,post,comment&limit=200
Authorization: Bearer <access>
```

응답:
```json
{
  "cursor": "1715200000000_42",
  "hasMore": false,
  "changes": {
    "pet": [
      {
        "id": 1, "name": "Rocky", "species": "REPTILE",
        "syncVersion": 17, "updatedAt": "2026-05-09T08:30:00Z",
        "deletedAt": null, "clientId": "ios-A1B2"
      }
    ],
    "post": [ ... ]
  }
}
```
- `cursor` = `<server_max_updated_at_ms>_<sync_version>` (안전한 단조 증가)
- 삭제는 `deleted_at` 채운 row로 표현 (tombstone)
- 클라이언트는 cursor 저장 → 다음 호출 시 since로 전달

### 5.2 Push — 로컬 변경 업로드
```
POST /api/v1/sync/push
Authorization: Bearer <access>
{
  "clientId": "ios-A1B2",
  "operations": [
    {
      "resource": "pet",
      "op": "upsert",
      "clientChangeId": "uuid",
      "data": {
        "id": null,                   // null이면 신규
        "name": "Rocky",
        "localUpdatedAt": "2026-05-09T08:25:00Z"
      }
    },
    {
      "resource": "comment",
      "op": "delete",
      "clientChangeId": "uuid",
      "data": { "id": 42 }
    }
  ]
}
```

응답:
```json
{
  "results": [
    {
      "clientChangeId": "uuid",
      "status": "APPLIED",
      "serverId": 17,
      "serverUpdatedAt": "2026-05-09T08:30:00Z",
      "syncVersion": 1024
    },
    {
      "clientChangeId": "uuid",
      "status": "CONFLICT",
      "reason": "stale_update",
      "serverState": { ... }
    },
    {
      "clientChangeId": "uuid",
      "status": "REJECTED",
      "reason": "validation_error"
    }
  ]
}
```

**충돌 판정 (LWW)**
- 서버 row의 `updated_at >= operation.localUpdatedAt` 이면 충돌 → 서버 상태로 클라이언트 덮어쓰기
- 그렇지 않으면 적용

**멱등성**
- `(client_id, client_change_id)` UNIQUE 제약 → 같은 변경 두 번 push 되어도 두 번째는 기존 row return.

## 6. 클라이언트 구현 가이드 (앱 팀 참고용)

### 6.1 SQLite 스키마
- 서버 스키마와 1:1 미러
- `_pending_ops` 테이블 추가:
  ```
  id INTEGER PK AUTOINCREMENT
  resource TEXT
  op TEXT (upsert/delete)
  payload TEXT (JSON)
  client_change_id TEXT (UUID)
  created_at INTEGER (epoch ms)
  retries INTEGER DEFAULT 0
  ```

### 6.2 동기화 사이클
1. 앱 부팅 / 네트워크 회복 / 주기적 (e.g. 5분)
2. **Push 단계**: `_pending_ops` 비우기 — 서버에 batched push
3. **Pull 단계**: 저장된 cursor로 since 호출 → 응답을 SQLite에 반영
4. cursor 저장

### 6.3 오프라인 쓰기 흐름
1. UI 즉시 SQLite 갱신 (낙관적)
2. `_pending_ops`에 변경 enqueue (clientChangeId UUID 생성)
3. 네트워크 가능하면 즉시 push 시도, 실패 시 백오프

### 6.4 충돌 시 UX
- 서버가 CONFLICT 반환 → 로컬 row를 서버 상태로 덮어씀 + 사용자에게 토스트로 알림
- 옵션: "내 변경사항 보기" 버튼으로 백업 데이터 보존

## 7. 보안
- 모든 sync API는 access JWT 필요
- 서버는 항상 `userId`를 토큰에서 추출, payload의 user_id는 무시 (탈취 방지)
- bookmark/follow 등 user_id 명시 필요한 경우 토큰 user_id로 강제

## 8. 성능 / 운영 고려
- pull batch size 기본 200, max 1000
- 서버는 `(updated_at, sync_version)` 복합 인덱스로 incremental 조회 빠르게
- 공감/팔로우 같은 고빈도 변경은 합치기(coalesce) — 클라이언트가 push 전 동일 resource 중복 op는 마지막만 남김
- `sync_version` 시퀀스는 per-user 또는 global. v1은 global postgres SEQUENCE로 충분 (수백만 사용자까지 무리 없음)

## 9. 마이그레이션 계획
- V7: 기존 syncable 테이블에 `sync_version`, `client_id`, `client_change_id` 컬럼 추가 + 인덱스
- V8: 트리거 또는 BEFORE UPDATE 함수로 `sync_version` 단조 증가 보장
- 기존 row는 `sync_version = 1`로 백필

## 10. 단계적 도입 로드맵
1. **M1 (v1.0)**: pet 도메인만 sync API 우선 구현 → 클라이언트 검증
2. **M2 (v1.1)**: post / comment / 인터랙션 동기화 추가
3. **M3 (v1.2)**: 충돌 시 사용자 머지 UI 옵션
4. **M4 (v2)**: 실시간 push (WebSocket) — 다른 기기에서 변경 발생 시 즉시 알림
5. **M5 (v3)**: CRDT 검토 (협업 다이어리 등 기능 추가 시)

## 11. 결정 요약
- 동기화 모델: **서버 LWW + tombstone**
- 추적 단위: per-row `sync_version` (전역 시퀀스)
- 멱등성: `(client_id, client_change_id)` UNIQUE
- v1 대상 리소스: pet 우선 → 점진 확대

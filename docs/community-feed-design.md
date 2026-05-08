# 커뮤니티 / 피드 도메인 설계 (v1 초안)

작성일: 2026-05-09 · 상태: **초안 (착수)**

## 1. 범위와 비범위
**v1 범위**
- 게시글(글/이미지) 작성·수정·삭제
- 댓글 (대댓글 1단계)
- 좋아요 (게시글/댓글)
- 팔로우 관계
- 개인 피드(타임라인) — 팔로잉 + 본인 글
- 태그 / 북마크
- 신고

**비범위 (v2 이후)**
- 실시간 피드(WebSocket)
- 알림 시스템
- 검색(Elasticsearch)
- 추천 알고리즘 / 인기 피드
- 동영상 업로드

## 2. 명명 규칙 적용
- 핵심 엔티티 → `_mst`
- 상세/이력 → `_dtl`
- 관계 테이블 → `_rls`
- 코드성 마스터 → `_cd`
- 공통 컬럼: `id BIGSERIAL PK`, `created_at`, `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`, soft-delete 대상은 `deleted_at TIMESTAMPTZ NULL`

## 3. ERD 초안

### 3.1 게시글 영역

#### `post_mst`
| 컬럼 | 타입 | 비고 |
|---|---|---|
| id | BIGSERIAL PK | |
| author_id | BIGINT NOT NULL FK → user_mst.id | |
| title | VARCHAR(120) NULL | 일반 피드 글에서는 NULL 허용 |
| content | TEXT NOT NULL | |
| post_type | VARCHAR(20) NOT NULL | TEXT / PHOTO / DIARY (post_type_cd) |
| visibility | VARCHAR(20) NOT NULL DEFAULT 'PUBLIC' | PUBLIC / FOLLOWERS / PRIVATE |
| like_count | INT NOT NULL DEFAULT 0 | denormalized |
| comment_count | INT NOT NULL DEFAULT 0 | denormalized |
| created_at, updated_at, deleted_at | | Soft Delete |

Index: `(author_id, created_at DESC)`, `(visibility, created_at DESC)`, `deleted_at`

#### `post_image_dtl`
| 컬럼 | 타입 |
|---|---|
| id | BIGSERIAL PK |
| post_id | BIGINT NOT NULL FK → post_mst.id ON DELETE CASCADE |
| image_url | TEXT NOT NULL |
| sort_order | SMALLINT NOT NULL DEFAULT 0 |
| created_at | TIMESTAMPTZ |

Index: `(post_id, sort_order)`

#### `post_tag_rls`
| 컬럼 | 타입 |
|---|---|
| id | BIGSERIAL PK |
| post_id | BIGINT NOT NULL FK → post_mst.id ON DELETE CASCADE |
| tag_id | BIGINT NOT NULL FK → tag_mst.id |
| created_at | TIMESTAMPTZ |

Unique: `(post_id, tag_id)` · Index: `tag_id`

#### `tag_mst`
| 컬럼 | 타입 |
|---|---|
| id | BIGSERIAL PK |
| name | VARCHAR(50) UNIQUE NOT NULL |
| usage_count | INT NOT NULL DEFAULT 0 |
| created_at | TIMESTAMPTZ |

### 3.2 댓글 영역

#### `comment_mst`
| 컬럼 | 타입 |
|---|---|
| id | BIGSERIAL PK |
| post_id | BIGINT NOT NULL FK → post_mst.id ON DELETE CASCADE |
| author_id | BIGINT NOT NULL FK → user_mst.id |
| parent_comment_id | BIGINT NULL FK → comment_mst.id | (대댓글, 1단계만 허용) |
| content | TEXT NOT NULL |
| like_count | INT NOT NULL DEFAULT 0 |
| created_at, updated_at, deleted_at | | Soft Delete |

Index: `(post_id, created_at)`, `parent_comment_id`

### 3.3 인터랙션 영역

#### `post_like_rls`
| id | post_id | user_id | created_at |
|---|---|---|---|

Unique: `(post_id, user_id)` · Index: `user_id`

#### `comment_like_rls`
| id | comment_id | user_id | created_at |
|---|---|---|---|

Unique: `(comment_id, user_id)`

#### `bookmark_rls`
| id | user_id | post_id | created_at |
|---|---|---|---|

Unique: `(user_id, post_id)` · Index: `(user_id, created_at DESC)`

#### `follow_rls`
| id | follower_id | following_id | created_at |
|---|---|---|---|

Unique: `(follower_id, following_id)` · Index: `following_id`
- 자기 자신 팔로우 금지 — 애플리케이션 레벨 검증

### 3.4 신고 영역

#### `report_dtl`
| 컬럼 | 타입 |
|---|---|
| id | BIGSERIAL PK |
| reporter_id | BIGINT NOT NULL FK → user_mst.id |
| target_type | VARCHAR(20) NOT NULL | POST / COMMENT / USER |
| target_id | BIGINT NOT NULL | |
| reason_code | VARCHAR(30) NOT NULL FK → report_reason_cd.code |
| description | TEXT NULL |
| status | VARCHAR(20) NOT NULL DEFAULT 'PENDING' | PENDING / REVIEWED / REJECTED |
| created_at, updated_at | | |

Index: `(target_type, target_id)`, `status`

### 3.5 코드성 마스터
- `post_type_cd` (TEXT, PHOTO, DIARY, ...)
- `report_reason_cd` (SPAM, HATE, NUDITY, OTHER)
- `visibility_cd` (선택 — enum과 컬럼 CHECK 제약으로 충분하면 생략)

## 4. 피드(타임라인) 전략

### 4.1 v1: Pull-based (Read fan-out)
```sql
-- 본인 + 팔로잉 사용자의 PUBLIC/FOLLOWERS 글
SELECT p.* FROM post_mst p
WHERE p.deleted_at IS NULL
  AND (
    p.author_id = :me
    OR p.author_id IN (SELECT following_id FROM follow_rls WHERE follower_id = :me)
  )
  AND p.visibility IN ('PUBLIC', 'FOLLOWERS')
ORDER BY p.created_at DESC
LIMIT :pageSize;
```

**장점**: 글 작성 시 추가 비용 없음, 단순함  
**단점**: 팔로잉 수가 많아질수록 쿼리 비용 증가

### 4.2 v1.5: Pull + Redis cache
- 사용자별 피드 ID 리스트를 Redis Sorted Set에 캐시 (`feed:{userId}` → score=created_at)
- TTL 짧게 (5분), miss 시 DB에서 재생성
- 캐시 키 무효화: 본인이 새 글을 쓰면 본인 follower들의 캐시 invalidate

### 4.3 v2 후보: Push-based (Write fan-out)
- 글 작성 시 follower들의 `feed:{followerId}`에 글 ID push
- 인플루언서(팔로워 수 ≥ N) 예외 처리 필요 (hot user 문제)

**결정**: v1은 4.1 단순 pull, v1.5에서 Redis 캐시 도입.

## 5. API 설계 (v1)

| 메서드 | 경로 | 인증 | 설명 |
|---|---|---|---|
| POST | /api/v1/posts | ✓ | 게시글 작성 |
| GET | /api/v1/posts/{id} | ✓ | 단건 조회 |
| PATCH | /api/v1/posts/{id} | ✓ | 작성자 수정 |
| DELETE | /api/v1/posts/{id} | ✓ | Soft Delete |
| GET | /api/v1/posts/me | ✓ | 내 글 목록 |
| GET | /api/v1/feed | ✓ | 타임라인 |
| GET | /api/v1/users/{id}/posts | ✓ | 특정 사용자 글 목록 |
| POST | /api/v1/posts/{id}/likes | ✓ | 좋아요 |
| DELETE | /api/v1/posts/{id}/likes | ✓ | 좋아요 취소 |
| POST | /api/v1/posts/{id}/comments | ✓ | 댓글 작성 |
| GET | /api/v1/posts/{id}/comments | ✓ | 댓글 목록 |
| DELETE | /api/v1/comments/{id} | ✓ | 댓글 삭제 |
| POST | /api/v1/comments/{id}/likes | ✓ | 댓글 좋아요 |
| POST | /api/v1/users/{id}/follow | ✓ | 팔로우 |
| DELETE | /api/v1/users/{id}/follow | ✓ | 언팔로우 |
| POST | /api/v1/posts/{id}/bookmarks | ✓ | 북마크 |
| GET | /api/v1/bookmarks | ✓ | 내 북마크 목록 |
| POST | /api/v1/reports | ✓ | 신고 |

페이지네이션: `cursor` 기반 (created_at + id) 권장 — 무한 스크롤 친화적.

## 6. 동시성 / 일관성
- 좋아요: `INSERT ... ON CONFLICT DO NOTHING` + 카운트는 트리거 또는 애플리케이션 레벨 증분
- 카운트 컬럼(`like_count`, `comment_count`)는 denormalized — 주기적 reconciliation job 추천
- N+1 방지: feed 쿼리에서 author 정보를 join 또는 fetch join

## 7. 보안 / 권한
- visibility=PRIVATE는 작성자 본인만, FOLLOWERS는 팔로워+본인만 조회
- 수정/삭제는 작성자만 (admin 우회는 별도 endpoint)
- 신고 24h 내 동일 target 중복 방지 — 애플리케이션 검증

## 8. 마이그레이션 계획
- V3: tag_mst, post_type_cd, visibility 관련 코드/테이블
- V4: post_mst, post_image_dtl, post_tag_rls
- V5: comment_mst, post_like_rls, comment_like_rls
- V6: follow_rls, bookmark_rls, report_reason_cd, report_dtl
- 각 V마다 인덱스 함께 추가

## 9. 다음 단계
1. tag/post 영역 ERD 검토 → ERD_v2 Notion 페이지 업데이트
2. V3 마이그레이션 SQL 작성
3. 엔티티 + Repository + Service skeleton (post → comment → like → follow 순)
4. 통합 테스트 (Testcontainers 기반)
5. Redis 피드 캐시는 v1.5 마일스톤

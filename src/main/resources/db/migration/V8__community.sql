-- =============================================================================
-- V8: 커뮤니티 도메인
-- post_mst, post_comment_dtl, post_photo_dtl, post_like_rls
-- v2.1 결정 #6: 댓글 테이블명 = post_comment_dtl (comment_mst 아님)
-- v2.1 결정 #10: post_like_rls 도입
-- =============================================================================

-- -----------------------------------------------------------------------------
-- post_mst : 게시글
-- -----------------------------------------------------------------------------
CREATE TABLE post_mst (
    id            BIGSERIAL    PRIMARY KEY,
    user_id       BIGINT       NOT NULL,
    category_id   BIGINT       NOT NULL,
    title         VARCHAR(200) NOT NULL,
    content       TEXT         NOT NULL,
    view_count    INTEGER      NOT NULL DEFAULT 0,
    like_count    INTEGER      NOT NULL DEFAULT 0,
    comment_count INTEGER      NOT NULL DEFAULT 0,
    deleted_at    TIMESTAMPTZ  NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_post_mst_user     FOREIGN KEY (user_id)     REFERENCES user_mst(id),
    CONSTRAINT fk_post_mst_category FOREIGN KEY (category_id) REFERENCES post_category_cd(id)
);

CREATE INDEX idx_post_mst_category_time ON post_mst(category_id, created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_post_mst_user_time     ON post_mst(user_id,     created_at DESC) WHERE deleted_at IS NULL;

COMMENT ON TABLE  post_mst             IS '게시글';
COMMENT ON COLUMN post_mst.like_count  IS 'Redis INCR 기반 집계 + 주기적 reconciliation';
COMMENT ON COLUMN post_mst.deleted_at  IS 'Soft Delete';

-- -----------------------------------------------------------------------------
-- post_photo_dtl : 게시글 이미지 (최대 5장 — 애플리케이션 레벨 검증)
-- -----------------------------------------------------------------------------
CREATE TABLE post_photo_dtl (
    id            BIGSERIAL    PRIMARY KEY,
    post_id       BIGINT       NOT NULL,
    s3_key        VARCHAR(255) NOT NULL,
    display_order INTEGER      NOT NULL DEFAULT 0,
    width         INTEGER      NULL,
    height        INTEGER      NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_post_photo_dtl_post FOREIGN KEY (post_id) REFERENCES post_mst(id) ON DELETE CASCADE
);

CREATE INDEX idx_post_photo_dtl_post ON post_photo_dtl(post_id, display_order);

COMMENT ON TABLE post_photo_dtl IS '게시글 이미지 (장당 최대 5장은 앱 레벨 검증)';

-- -----------------------------------------------------------------------------
-- post_comment_dtl : 댓글 (1단계 대댓글 지원)
-- v2.1 결정 #6: comment_mst → post_comment_dtl
-- -----------------------------------------------------------------------------
CREATE TABLE post_comment_dtl (
    id                BIGSERIAL PRIMARY KEY,
    post_id           BIGINT    NOT NULL,
    user_id           BIGINT    NOT NULL,
    parent_comment_id BIGINT    NULL,
    content           TEXT      NOT NULL,
    deleted_at        TIMESTAMPTZ NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_post_comment_post    FOREIGN KEY (post_id)  REFERENCES post_mst(id) ON DELETE CASCADE,
    CONSTRAINT fk_post_comment_user    FOREIGN KEY (user_id)  REFERENCES user_mst(id),
    CONSTRAINT fk_post_comment_parent  FOREIGN KEY (parent_comment_id) REFERENCES post_comment_dtl(id) ON DELETE CASCADE
);

CREATE INDEX idx_post_comment_dtl_post   ON post_comment_dtl(post_id, created_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_post_comment_dtl_parent ON post_comment_dtl(parent_comment_id)   WHERE parent_comment_id IS NOT NULL;

COMMENT ON TABLE  post_comment_dtl                   IS '댓글 (1단계 대댓글 지원)';
COMMENT ON COLUMN post_comment_dtl.parent_comment_id IS 'NULL이면 최상위 댓글, NOT NULL이면 대댓글';

-- -----------------------------------------------------------------------------
-- post_like_rls : 좋아요
-- v2.1 결정 #10: post_like_rls 도입
-- -----------------------------------------------------------------------------
CREATE TABLE post_like_rls (
    id         BIGSERIAL   PRIMARY KEY,
    post_id    BIGINT      NOT NULL,
    user_id    BIGINT      NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_post_like_rls_post FOREIGN KEY (post_id) REFERENCES post_mst(id) ON DELETE CASCADE,
    CONSTRAINT fk_post_like_rls_user FOREIGN KEY (user_id) REFERENCES user_mst(id) ON DELETE CASCADE,
    CONSTRAINT uk_post_like_rls      UNIQUE (post_id, user_id)
);

CREATE INDEX idx_post_like_rls_user ON post_like_rls(user_id);

COMMENT ON TABLE post_like_rls IS '좋아요 (스키마 구축, MVP 공개 여부 추후 결정)';

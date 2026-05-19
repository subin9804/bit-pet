-- =============================================================================
-- V10: 오프라인 동기화 컬럼 + 트리거
-- 대상: pet_mst, weight_dtl, feeding_dtl, cleaning_dtl, health_memo_dtl,
--       post_mst, post_comment_dtl, post_like_rls
-- =============================================================================

-- sync_version 전역 시퀀스
CREATE SEQUENCE IF NOT EXISTS sync_version_seq START 1 INCREMENT 1;

-- 동기화 컬럼 추가 헬퍼 (각 테이블에 직접 추가)
ALTER TABLE pet_mst ADD COLUMN sync_version    BIGINT      NOT NULL DEFAULT 1;
ALTER TABLE pet_mst ADD COLUMN client_id       VARCHAR(64) NULL;
ALTER TABLE pet_mst ADD COLUMN client_change_id UUID        NULL;
ALTER TABLE pet_mst ADD CONSTRAINT uk_pet_mst_sync
    UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE weight_dtl ADD COLUMN sync_version     BIGINT      NOT NULL DEFAULT 1;
ALTER TABLE weight_dtl ADD COLUMN client_id        VARCHAR(64) NULL;
ALTER TABLE weight_dtl ADD COLUMN client_change_id UUID        NULL;
ALTER TABLE weight_dtl ADD CONSTRAINT uk_weight_dtl_sync
    UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE feeding_dtl ADD COLUMN sync_version     BIGINT      NOT NULL DEFAULT 1;
ALTER TABLE feeding_dtl ADD COLUMN client_id        VARCHAR(64) NULL;
ALTER TABLE feeding_dtl ADD COLUMN client_change_id UUID        NULL;
ALTER TABLE feeding_dtl ADD CONSTRAINT uk_feeding_dtl_sync
    UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE cleaning_dtl ADD COLUMN sync_version     BIGINT      NOT NULL DEFAULT 1;
ALTER TABLE cleaning_dtl ADD COLUMN client_id        VARCHAR(64) NULL;
ALTER TABLE cleaning_dtl ADD COLUMN client_change_id UUID        NULL;
ALTER TABLE cleaning_dtl ADD CONSTRAINT uk_cleaning_dtl_sync
    UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE health_memo_dtl ADD COLUMN sync_version     BIGINT      NOT NULL DEFAULT 1;
ALTER TABLE health_memo_dtl ADD COLUMN client_id        VARCHAR(64) NULL;
ALTER TABLE health_memo_dtl ADD COLUMN client_change_id UUID        NULL;
ALTER TABLE health_memo_dtl ADD CONSTRAINT uk_health_memo_dtl_sync
    UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE post_mst ADD COLUMN sync_version     BIGINT      NOT NULL DEFAULT 1;
ALTER TABLE post_mst ADD COLUMN client_id        VARCHAR(64) NULL;
ALTER TABLE post_mst ADD COLUMN client_change_id UUID        NULL;
ALTER TABLE post_mst ADD CONSTRAINT uk_post_mst_sync
    UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE post_comment_dtl ADD COLUMN sync_version     BIGINT      NOT NULL DEFAULT 1;
ALTER TABLE post_comment_dtl ADD COLUMN client_id        VARCHAR(64) NULL;
ALTER TABLE post_comment_dtl ADD COLUMN client_change_id UUID        NULL;
ALTER TABLE post_comment_dtl ADD CONSTRAINT uk_post_comment_dtl_sync
    UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE post_like_rls ADD COLUMN sync_version     BIGINT      NOT NULL DEFAULT 1;
ALTER TABLE post_like_rls ADD COLUMN client_id        VARCHAR(64) NULL;
ALTER TABLE post_like_rls ADD COLUMN client_change_id UUID        NULL;
ALTER TABLE post_like_rls ADD CONSTRAINT uk_post_like_rls_sync
    UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

-- -----------------------------------------------------------------------------
-- sync_version 단조 증가 트리거 (BEFORE UPDATE)
-- 각 대상 테이블에 공통 트리거 함수 1개 재사용
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_bump_sync_version()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.sync_version := nextval('sync_version_seq');
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_pet_mst_sync_version
    BEFORE UPDATE ON pet_mst
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

CREATE TRIGGER trg_weight_dtl_sync_version
    BEFORE UPDATE ON weight_dtl
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

CREATE TRIGGER trg_feeding_dtl_sync_version
    BEFORE UPDATE ON feeding_dtl
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

CREATE TRIGGER trg_cleaning_dtl_sync_version
    BEFORE UPDATE ON cleaning_dtl
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

CREATE TRIGGER trg_health_memo_dtl_sync_version
    BEFORE UPDATE ON health_memo_dtl
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

CREATE TRIGGER trg_post_mst_sync_version
    BEFORE UPDATE ON post_mst
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

CREATE TRIGGER trg_post_comment_dtl_sync_version
    BEFORE UPDATE ON post_comment_dtl
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

CREATE TRIGGER trg_post_like_rls_sync_version
    BEFORE UPDATE ON post_like_rls
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

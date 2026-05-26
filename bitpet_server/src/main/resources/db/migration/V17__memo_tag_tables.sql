-- =============================================================================
-- V17: memo_tag_rls (메모↔태그 다대다) + memo_vet_ext_dtl (병원 확장 1:0..1)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- memo_tag_rls : 메모↔태그 다대다
-- -----------------------------------------------------------------------------
CREATE TABLE memo_tag_rls (
    memo_id          BIGINT      NOT NULL,
    tag_id           BIGINT      NOT NULL,
    sync_version     BIGINT      NOT NULL DEFAULT 1,
    client_id        VARCHAR(64) NULL,
    client_change_id UUID        NULL,
    PRIMARY KEY (memo_id, tag_id),
    CONSTRAINT fk_memo_tag_rls_memo FOREIGN KEY (memo_id) REFERENCES memo_dtl(id)    ON DELETE CASCADE,
    CONSTRAINT fk_memo_tag_rls_tag  FOREIGN KEY (tag_id)  REFERENCES memo_tag_cd(id) ON DELETE RESTRICT
);

CREATE INDEX idx_memo_tag_rls_tag ON memo_tag_rls (tag_id, memo_id);
ALTER TABLE memo_tag_rls ADD CONSTRAINT uk_memo_tag_rls_sync
    UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER trg_memo_tag_rls_sync_version
    BEFORE UPDATE ON memo_tag_rls
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

-- -----------------------------------------------------------------------------
-- memo_vet_ext_dtl : VET 태그 메모 확장 (1:0..1)
-- -----------------------------------------------------------------------------
CREATE TABLE memo_vet_ext_dtl (
    memo_id          BIGINT       PRIMARY KEY,
    clinic_name      VARCHAR(100) NULL,
    cost             INTEGER      NULL,
    next_visit_at    TIMESTAMPTZ  NULL,
    sync_version     BIGINT       NOT NULL DEFAULT 1,
    client_id        VARCHAR(64)  NULL,
    client_change_id UUID         NULL,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_memo_vet_ext_memo FOREIGN KEY (memo_id) REFERENCES memo_dtl(id) ON DELETE CASCADE,
    CONSTRAINT chk_memo_vet_ext_cost CHECK (cost IS NULL OR cost >= 0)
);

CREATE INDEX idx_memo_vet_ext_next_visit ON memo_vet_ext_dtl (next_visit_at)
    WHERE next_visit_at IS NOT NULL;
ALTER TABLE memo_vet_ext_dtl ADD CONSTRAINT uk_memo_vet_ext_sync
    UNIQUE (client_id, client_change_id) DEFERRABLE INITIALLY DEFERRED;

CREATE TRIGGER trg_memo_vet_ext_dtl_sync_version
    BEFORE UPDATE ON memo_vet_ext_dtl
    FOR EACH ROW EXECUTE FUNCTION fn_bump_sync_version();

COMMENT ON TABLE memo_tag_rls     IS '메모↔태그 다대다 연결';
COMMENT ON TABLE memo_vet_ext_dtl IS '병원(VET) 태그 메모 확장 필드 (1:0..1)';
COMMENT ON COLUMN memo_vet_ext_dtl.next_visit_at IS '다음 방문 예정일 — 알림 스케줄러용 인덱스 포함';

-- 커뮤니티 공지 상단 고정
-- pinned_yn = 'Y'인 게시글은 목록에서 최신순보다 우선해 상단에 노출된다.
-- 설정은 관리자(admin_role_rls)만 가능하며, 클라이언트 UI에는 별도 뱃지를 표시하지 않는다.

ALTER TABLE post_mst ADD COLUMN pinned_yn VARCHAR(1) NOT NULL DEFAULT 'N';

CREATE INDEX idx_post_mst_pinned_time ON post_mst (pinned_yn, created_at DESC);

COMMENT ON COLUMN post_mst.pinned_yn IS '공지 상단 고정 여부 Y/N (관리자만 설정)';

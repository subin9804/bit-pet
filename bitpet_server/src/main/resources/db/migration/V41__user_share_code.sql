-- =============================================================================
-- V41: user_mst.share_code — 개체 공유/입분양 대상 식별 코드
--   - 다른 사육자가 이 코드로 나를 지정해 개체를 공유/입분양
--   - NULL 허용: 지연(lazy) 발급 — 공유 화면 최초 진입 시 ShareCodeGenerator가 생성
--   - 값이 있으면 전역 유일
--
--   ※ 백필하지 않는다. 코드 문자 풀(0/O/I/1 제외)·충돌 재시도는 SQL로 부적합하며,
--     ShareCodeGenerator.generateUnique()(GET /pets/share/my-code)가 담당한다.
--     기존 유저는 자신의 공유코드를 조회하는 순간 발급받는다.
-- =============================================================================

ALTER TABLE user_mst ADD COLUMN share_code VARCHAR(8);

CREATE UNIQUE INDEX idx_user_mst_share_code
    ON user_mst(share_code) WHERE share_code IS NOT NULL;

COMMENT ON COLUMN user_mst.share_code IS '개체 공유/입분양 대상 식별 코드 (전역 유일). 마이페이지에서 확인';

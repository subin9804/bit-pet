-- 닉네임 유일성 — 회원가입 '중복확인' 이 실제로 보장이 되게 한다.
--
-- 서비스 계층에서 existsByNameIgnoreCase 로 먼저 걸러내지만 그것만으로는 부족하다:
--   ① 중복확인과 가입 사이에 남이 같은 닉네임으로 가입할 수 있고 (TOCTOU)
--   ② PATCH /auth/me 로 닉네임을 바꾸는 경로도 같은 창이 열려 있다
-- 확인 버튼이 거짓말을 하지 않으려면 최종 판정은 DB 가 해야 한다.

-- 대소문자를 구분하지 않는다. 'Tailog' 와 'tailog' 가 공존하면 가계도·커뮤니티에서
-- 같은 사람으로 오인된다 (사칭 억제가 닉네임 노출의 목적이므로 치명적).
--
-- deleted_at IS NULL 부분 인덱스인 이유: 탈퇴는 소프트 삭제라 행이 남는다.
-- 조건을 빼면 탈퇴한 계정이 닉네임을 영구히 붙잡아 아무도 못 쓰게 된다.
-- 엔티티의 @SQLRestriction("deleted_at IS NULL") 과 범위가 정확히 일치한다.
CREATE UNIQUE INDEX idx_user_mst_name_unique
    ON user_mst (lower(name))
    WHERE deleted_at IS NULL;

COMMENT ON INDEX idx_user_mst_name_unique IS
    '닉네임 중복 방지 (대소문자 무시, 탈퇴 계정 제외)';

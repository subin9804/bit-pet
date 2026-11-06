-- 만 14세가 된 자녀 계정의 보호자 연결 해제 (2026-11-06)
--
-- guardian_user_id 를 NULL 로 지우지 않고 '해제 시각'만 따로 찍는다. guardian_user_id 는
-- 법정대리인 동의 기록(user_agreement_dtl.GUARDIAN)이 누구의 동의였는지 따라가는 유일한
-- 경로라 지우면 안 된다 (V21 탈퇴 스크럽도 같은 이유로 남긴다).
--
-- 값이 있으면 더 이상 그 보호자의 자녀가 아니다: 자녀 목록에서 빠지고, 보호자가 삭제할 수 없고,
-- 보호자 탈퇴도 막지 않는다. 넓히는 방향(nullable 추가)이라 구버전 서버와 공존해도 안전하다.
ALTER TABLE user_mst ADD COLUMN guardian_released_at timestamp with time zone;

COMMENT ON COLUMN user_mst.guardian_released_at IS
    '보호자 연결 해제 시각 — 만 14세 도달 시 GuardianReleaseScheduler 가 찍는다. guardian_user_id 는 동의 근거라 남긴다';

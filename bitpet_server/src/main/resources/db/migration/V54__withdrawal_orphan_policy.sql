-- =============================================================================
-- V54: 회원 탈퇴 시 개체 처리 정책
--
--   탈퇴 회원의 개체는 두 갈래로 갈린다.
--     (A) 남이 거는 참조가 하나도 없음 → 개체·기록·사진 전부 물리 삭제
--     (B) 남의 가계도/메이팅이 참조 중   → 익명화 보존(is_orphaned = true)
--
--   (B)를 두는 이유는 하나다. 남의 자식 개체에 부모로 박혀 있는 개체를 지우면
--   그쪽 가계도가 끊긴다. 그래서 소유자만 떼어내고(user_id NULL) 혈통 식별에
--   필요한 정보(개체명·종·모프·성별·해칭일·부모 참조)만 남긴다.
--
--   is_orphaned 는 user_id IS NULL 과 겹치지만 따로 둔다. "소유자가 비어 있다"가
--   아니라 "신규 참조 대상에서 제외한다"는 별개의 의미를 지녀야 하고, 정리 배치도
--   이 플래그 하나로 스캔한다.
-- =============================================================================

ALTER TABLE pet_mst ADD COLUMN is_orphaned BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN pet_mst.is_orphaned IS
    '탈퇴 익명화 개체. 신규 참조(부모 등록·메이팅 상대) 대상에서 제외되고, 참조가 0이 되면 정리 배치가 물리 삭제한다';

-- 정리 배치·차단 조회용. 고아는 전체 개체 대비 극소수라 부분 인덱스로 둔다
CREATE INDEX idx_pet_mst_orphaned ON pet_mst (id) WHERE is_orphaned = true;

-- -----------------------------------------------------------------------------
-- 프라이버시 — 가계도에 닉네임을 노출할지
--   false 면 응답의 nickname 을 '비공개'로 치환하고 userId 를 내리지 않는다
--   (프로필로 이동할 수 없다). 개체명은 혈통 식별 정보라 항상 노출된다.
-- -----------------------------------------------------------------------------
ALTER TABLE user_mst ADD COLUMN show_nickname_in_pedigree BOOLEAN NOT NULL DEFAULT true;

COMMENT ON COLUMN user_mst.show_nickname_in_pedigree IS
    '가계도/개체 카드에 내 닉네임을 노출할지. false 면 "비공개"로 치환되고 프로필 이동 불가';

-- -----------------------------------------------------------------------------
-- S3 삭제 재시도 큐
--   탈퇴는 하나의 트랜잭션이지만 S3 삭제는 그 안에서 못 한다 — 외부 호출이 실패해도
--   DB 를 롤백해선 안 되고, 성공한 뒤 롤백되면 파일만 사라진다. 그래서 삭제할 키를
--   트랜잭션 안에서 이 테이블에 적재만 하고, 커밋 뒤 배치가 비동기로 지운다.
-- -----------------------------------------------------------------------------
CREATE TABLE s3_delete_queue_dtl (
    id           BIGSERIAL    PRIMARY KEY,
    s3_key       VARCHAR(255) NOT NULL,
    attempt_cnt  INT          NOT NULL DEFAULT 0,
    last_error   TEXT,
    succeeded_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- 배치가 훑는 건 미처리분뿐이다. 성공분은 감사 로그로 남기되 스캔에서 빠진다
CREATE INDEX idx_s3_delete_queue_pending
    ON s3_delete_queue_dtl (attempt_cnt, id) WHERE succeeded_at IS NULL;

COMMENT ON TABLE  s3_delete_queue_dtl            IS 'S3 오브젝트 삭제 재시도 큐 (탈퇴·개체 정리에서 적재)';
COMMENT ON COLUMN s3_delete_queue_dtl.attempt_cnt IS '시도 횟수. 한계치를 넘기면 배치가 손대지 않고 수동 확인 대상으로 남긴다';

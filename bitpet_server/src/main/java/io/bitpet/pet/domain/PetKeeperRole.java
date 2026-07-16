package io.bitpet.pet.domain;

public enum PetKeeperRole {
    /** 개체 소유자 (개체당 1명) — 프로필 수정·삭제·공유·입분양 권한 */
    OWNER,
    /** 공유받은 사육자 — 기록 작성·루틴 수행 권한 */
    KEEPER
}

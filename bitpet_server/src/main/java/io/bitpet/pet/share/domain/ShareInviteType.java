package io.bitpet.pet.share.domain;

public enum ShareInviteType {
    /** 공유 — invitee를 KEEPER로 추가 (기존 OWNER 유지) */
    SHARE,
    /** 입분양 — invitee가 OWNER가 되고 기존 OWNER는 제외 */
    TRANSFER
}

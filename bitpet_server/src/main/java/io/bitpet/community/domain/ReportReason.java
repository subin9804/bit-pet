package io.bitpet.community.domain;

import lombok.Getter;

/**
 * 신고 사유.
 *
 * <p>{@link #ILLEGAL_TRADE} 와 {@link #ANIMAL_CRUELTY} 는 일반 커뮤니티 세트에는 없는 항목이다.
 * 파충류 커뮤니티에서 실제로 문제가 되는 신고는 대부분 이 둘이고, "기타" 로 뭉뚱그리면
 * 운영자가 큐에서 위험한 건을 먼저 집어낼 수 없다.
 */
@Getter
public enum ReportReason {
    SPAM("도배·광고"),
    ABUSE("욕설·혐오 표현"),
    SEXUAL("음란물"),
    PRIVACY("개인정보 노출"),
    ILLEGAL_TRADE("불법 분양·판매"),
    ANIMAL_CRUELTY("동물 학대"),
    ETC("기타");

    private final String label;

    ReportReason(String label) { this.label = label; }
}

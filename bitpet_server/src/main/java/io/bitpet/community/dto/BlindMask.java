package io.bitpet.community.dto;

/**
 * 블라인드된 글·댓글의 치환 문구.
 *
 * <p>가리는 일은 <b>응답 DTO 의 {@code of()} 안에서만</b> 한다. 서비스에서 엔티티의 내용을
 * 바꾸면 그대로 영속화돼 원문이 사라지고, 호출부에서 가리면 새 경로가 생길 때마다 잊는다.
 * 엔티티는 블라인드 여부만 들고 있고, 치환은 여기 한 곳을 지난다.
 */
public final class BlindMask {

    public static final String TITLE   = "운영자에 의해 가려진 글입니다";
    public static final String CONTENT = "신고가 접수되어 운영자가 가린 내용입니다.";
    public static final String COMMENT = "신고가 접수되어 운영자가 가린 댓글입니다.";

    private BlindMask() {}
}

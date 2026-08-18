package io.bitpet.auth.dto;

/**
 * 닉네임 중복확인 결과.
 *
 * <p>{@code available} 만 내리지 않고 {@code reason} 을 함께 주는 이유:
 * 쓸 수 없는 이유가 "이미 있음" 하나가 아니다. 길이·문자 규칙·예약어가 모두 여기서 걸리는데,
 * 앱이 전부 "사용할 수 없는 닉네임입니다" 로 뭉뚱그리면 사용자가 뭘 고쳐야 할지 모른다.
 * 규칙 판정은 서버가 단일 소스로 갖고, 문구만 서버가 내려준다.
 *
 * @param available 사용 가능 여부
 * @param reason    불가 사유(사용자에게 그대로 보여줄 한국어 문장). 사용 가능하면 null
 */
public record NicknameCheckResponse(boolean available, String reason) {

    public static NicknameCheckResponse ok() {
        return new NicknameCheckResponse(true, null);
    }

    public static NicknameCheckResponse no(String reason) {
        return new NicknameCheckResponse(false, reason);
    }
}

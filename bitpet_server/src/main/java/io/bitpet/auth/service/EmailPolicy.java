package io.bitpet.auth.service;

import java.util.Locale;

/**
 * 이메일 정규화 — 앞뒤 공백 제거 + 소문자 (2026-11-03).
 *
 * <p>전엔 글자 그대로 비교해서 {@code Su9804@Gmail.com} 으로 가입한 사람이 구글 로그인
 * ({@code su9804@gmail.com})을 하면 기존 계정에 안 붙고 새 계정이 생겼다. 대소문자만 다른
 * 주소로 두 번 가입하는 것도 막지 못했다.
 *
 * <p>새로 저장하는 이메일은 이걸 거친 값이고, 조회는 대소문자를 무시한다
 * ({@code UserMstRepository#findByEmailLoose}) — 이 규칙 전에 저장된 대문자 섞인 주소도 찾아야 해서.
 */
public final class EmailPolicy {

    private EmailPolicy() {}

    public static String normalize(String email) {
        return email == null ? null : email.trim().toLowerCase(Locale.ROOT);
    }

    /** 제공자가 이메일을 안 줘서 만든 자리표시 주소. 화면에 보여 주면 안 된다. */
    public static boolean isSynthetic(String email) {
        return email != null && email.endsWith("@oauth.bitpet.local");
    }
}

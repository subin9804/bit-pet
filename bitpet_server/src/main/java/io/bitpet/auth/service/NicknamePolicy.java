package io.bitpet.auth.service;

import java.util.Set;
import java.util.regex.Pattern;

/**
 * 닉네임 형식 규칙 — 회원가입 중복확인·가입·프로필 수정이 모두 이 클래스를 거친다.
 *
 * <p>한 곳에 모아둔 이유는 세 경로가 각자 검사하면 반드시 어긋나기 때문이다.
 * 중복확인은 통과했는데 가입에서 거절당하는 상황이 그렇게 만들어진다.
 *
 * <p>⚠️ 여기서 판정한 결과와 DB 의 {@code idx_user_mst_name_unique}(lower(name) 유니크)는
 * 범위가 같아야 한다. 정규화 방식을 바꾸려면 마이그레이션도 함께 고쳐야 한다.
 */
public final class NicknamePolicy {

    public static final int MIN_LENGTH = 2;
    public static final int MAX_LENGTH = 20;

    /**
     * 한글(완성형)·영문·숫자·밑줄만 허용한다.
     *
     * <p>공백을 막는 이유: 앞뒤 공백은 trim 으로 지워지지만 가운데 공백은 남아
     * '테 일 로 그' 처럼 눈으로는 같아 보이는 닉네임을 무한히 만들 수 있다.
     * 자음·모음 단독(ㄱ, ㅏ)도 같은 이유로 제외한다 — 완성형만 받는다.
     */
    private static final Pattern ALLOWED = Pattern.compile("^[가-힣a-zA-Z0-9_]+$");

    /**
     * 예약어. 운영자 사칭을 막는다.
     *
     * <p>가계도·커뮤니티에 닉네임이 그대로 노출되는데, '관리자'가 남의 개체에 댓글을 달면
     * 그 자체로 공지처럼 읽힌다. 포함(contains)이 아니라 완전 일치로만 막는다 —
     * '관리자' 를 부분 일치로 막으면 '개체관리자유' 같은 멀쩡한 닉네임까지 걸린다.
     */
    private static final Set<String> RESERVED = Set.of(
            "admin", "administrator", "root", "system", "official",
            "tailog", "tailogofficial", "테일로그", "테일로그공식",
            "관리자", "운영자", "운영팀", "고객센터", "공지", "공지사항"
    );

    private NicknamePolicy() {
    }

    /** 저장·비교에 쓸 정규화 형태. 앞뒤 공백만 제거한다(대소문자는 보존 — 표시에 쓰이므로). */
    public static String normalize(String raw) {
        return raw == null ? "" : raw.trim();
    }

    /**
     * 외부에서 받은 이름을 규칙에 맞는 닉네임으로 깎는다. OAuth 로그인 전용.
     *
     * <p>카카오·네이버는 '김 수빈', 'Kim Subin(김수빈)' 처럼 공백과 괄호가 섞인 이름을 준다.
     * 그대로 저장하면 나중에 그 사용자가 프로필을 저장할 때 자기 닉네임이 형식 위반으로
     * 거절당한다 — 아무것도 안 고쳤는데 저장이 막히는 상태가 된다.
     *
     * <p>사용자를 막지 않는 것이 최우선이므로 여기서는 <b>거절하지 않고 항상 쓸 수 있는 값</b>을
     * 만들어 낸다. 예약어까지 걸리면 접미사가 붙어 유일해지므로 그대로 통과시킨다.
     */
    public static String sanitizeForOAuth(String rawName, String fallback) {
        String base = normalize(rawName).replaceAll("[^가-힣a-zA-Z0-9_]", "");
        if (base.isEmpty()) {
            base = fallback;
        }
        if (base.codePointCount(0, base.length()) > MAX_LENGTH) {
            base = base.substring(0, base.offsetByCodePoints(0, MAX_LENGTH));
        }
        // 깎고 나니 1자만 남는 경우('김 수' → '김수'는 괜찮지만 'A B' → 'AB' 가 아닌 'A ' → 'A')
        while (base.codePointCount(0, base.length()) < MIN_LENGTH) {
            base = base + "0";
        }
        return base;
    }

    /**
     * 유일한 닉네임이 될 때까지 접미사를 붙인다.
     *
     * <p>{@code taken} 은 "이미 쓰이고 있는가"를 판정하는 함수다. 저장소를 직접 참조하지 않아
     * OAuth 경로와 테스트가 같은 로직을 쓸 수 있다.
     *
     * <p>MAX_LENGTH 를 넘지 않도록 앞부분을 잘라내며 붙인다 — 자르지 않으면 20자 이름을 가진
     * 사용자들끼리 접미사가 무한히 늘어나며 컬럼 길이를 넘긴다.
     */
    public static String makeUnique(String base, java.util.function.Predicate<String> taken) {
        if (!taken.test(base)) {
            return base;
        }
        for (int i = 2; i < 10_000; i++) {
            String suffix = String.valueOf(i);
            int room = MAX_LENGTH - suffix.length();
            String head = base.codePointCount(0, base.length()) > room
                    ? base.substring(0, base.offsetByCodePoints(0, room))
                    : base;
            String candidate = head + suffix;
            if (!taken.test(candidate)) {
                return candidate;
            }
        }
        // 1만 번을 다 쓴 경우. 실질적으로 도달하지 않지만 무한 루프로 두지 않는다.
        throw new IllegalStateException("사용 가능한 닉네임을 만들지 못했습니다: " + base);
    }

    /**
     * 형식 검사.
     *
     * @return 문제가 없으면 null, 있으면 사용자에게 보여줄 사유
     */
    public static String validateFormat(String nickname) {
        if (nickname.isEmpty()) {
            return "닉네임을 입력해 주세요";
        }
        // 길이는 문자 수로 센다. codePointCount 를 쓰지 않으면 이모지가 2자로 세어져
        // "2자 이상"을 이모지 하나로 통과시킬 수 있다.
        int length = nickname.codePointCount(0, nickname.length());
        if (length < MIN_LENGTH) {
            return MIN_LENGTH + "자 이상 입력해 주세요";
        }
        if (length > MAX_LENGTH) {
            return MAX_LENGTH + "자까지 쓸 수 있어요";
        }
        if (!ALLOWED.matcher(nickname).matches()) {
            return "한글·영문·숫자·밑줄(_)만 쓸 수 있어요";
        }
        if (RESERVED.contains(nickname.toLowerCase())) {
            return "사용할 수 없는 닉네임이에요";
        }
        return null;
    }
}

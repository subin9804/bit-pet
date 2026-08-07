package io.bitpet.nfc.service;

import io.bitpet.nfc.repository.NfcTagMstRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;
import java.util.HashSet;
import java.util.Set;

/**
 * NFC 태그 코드 발급기 — Crockford Base32 랜덤 6자 (예: 7K3MPQ).
 *
 * <p>순차 번호를 쓰면 남의 태그 주소를 추측할 수 있으므로 반드시 랜덤으로 생성한다.
 *
 * <p>구버전은 {@code BP} 접두사 + 랜덤 4자였다. 접두사는 고정값이라 실효 경우의 수를
 * 32<sup>4</sup>(약 105만)로 묶어버리는데, URL 을 그대로 노출하는 태그에서는 너무 좁다.
 * 접두사를 떼고 6자 전부를 랜덤으로 돌려 32<sup>6</sup>(약 10.7억)으로 넓혔다.
 */
@Component
@RequiredArgsConstructor
public class TagCodeGenerator {

    /**
     * Crockford Base32 — 0-9 + A-Z 에서 I/L/O/U 를 뺀 32자.
     * I/L/O 는 1/0 과 헷갈려서, U 는 욕설 조합을 피하려고 뺀다 (손으로 옮겨 적을 수 있어야 함).
     * DB 의 {@code ck_nfc_tag_mst_cd_format} 과 같은 집합이어야 한다.
     */
    private static final char[] POOL = "0123456789ABCDEFGHJKMNPQRSTVWXYZ".toCharArray();
    private static final int CODE_LENGTH = 6;
    private static final int MAX_ATTEMPTS = 32;

    private final NfcTagMstRepository tagRepository;
    private final SecureRandom random = new SecureRandom();

    public String generateUnique() {
        for (int attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
            String candidate = randomCode();
            if (!tagRepository.existsById(candidate)) {
                return candidate;
            }
        }
        throw new IllegalStateException("Failed to generate a unique NFC tag code");
    }

    /**
     * 재고 생산용 — 서로 중복되지 않는 코드 {@code count} 개.
     * 배치 안에서의 중복은 메모리에서, 기존 태그와의 중복은 DB 조회로 막는다.
     */
    public Set<String> generateUnique(int count) {
        Set<String> codes = new HashSet<>(count * 2);
        int attempts = 0;
        int maxAttempts = count * MAX_ATTEMPTS;
        while (codes.size() < count) {
            if (++attempts > maxAttempts) {
                throw new IllegalStateException(
                        "Failed to generate " + count + " unique NFC tag codes — 코드 길이를 늘려야 합니다.");
            }
            String candidate = randomCode();
            if (!codes.contains(candidate) && !tagRepository.existsById(candidate)) {
                codes.add(candidate);
            }
        }
        return codes;
    }

    private String randomCode() {
        StringBuilder sb = new StringBuilder(CODE_LENGTH);
        for (int i = 0; i < CODE_LENGTH; i++) {
            sb.append(POOL[random.nextInt(POOL.length)]);
        }
        return sb.toString();
    }
}

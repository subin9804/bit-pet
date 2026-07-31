package io.bitpet.nfc.service;

import io.bitpet.nfc.repository.NfcTagMstRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;
import java.util.HashSet;
import java.util.Set;

/**
 * NFC 태그 코드 발급기 — {@code BP} + 랜덤 4자 (예: BP7K3M).
 *
 * <p>순차 번호를 쓰면 남의 태그 주소를 추측할 수 있으므로 반드시 랜덤으로 생성한다.
 * 개체 일련번호(pet_mst.serial_no)와는 완전히 다른 체계다 — 접두사 BP 로 육안 구분.
 */
@Component
@RequiredArgsConstructor
public class TagCodeGenerator {

    /** 혼동 문자(0/O/I/1) 제외 — 손으로 옮겨 적을 수 있어야 함 */
    private static final char[] POOL = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ".toCharArray();
    private static final String PREFIX = "BP";
    private static final int RANDOM_LENGTH = 4;
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
        StringBuilder sb = new StringBuilder(PREFIX.length() + RANDOM_LENGTH);
        sb.append(PREFIX);
        for (int i = 0; i < RANDOM_LENGTH; i++) {
            sb.append(POOL[random.nextInt(POOL.length)]);
        }
        return sb.toString();
    }
}

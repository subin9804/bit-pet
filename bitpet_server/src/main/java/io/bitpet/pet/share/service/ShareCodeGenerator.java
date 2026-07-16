package io.bitpet.pet.share.service;

import io.bitpet.auth.repository.UserMstRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;

/**
 * 유저 공유코드 발급기 — 개체 공유/입분양 대상 식별용.
 * 8자리, 혼동 문자(0/O/I/1) 제외 풀. 전역 유일 보장.
 */
@Component
@RequiredArgsConstructor
public class ShareCodeGenerator {

    private static final char[] POOL =
            "23456789ABCDEFGHJKLMNPQRSTUVWXYZ".toCharArray();
    private static final int LENGTH = 8;
    private static final int MAX_ATTEMPTS = 32;

    private final UserMstRepository userRepository;
    private final SecureRandom random = new SecureRandom();

    public String generateUnique() {
        for (int attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
            String candidate = randomCode();
            if (!userRepository.existsByShareCode(candidate)) {
                return candidate;
            }
        }
        throw new IllegalStateException("Failed to generate a unique share code");
    }

    private String randomCode() {
        char[] buf = new char[LENGTH];
        for (int i = 0; i < LENGTH; i++) {
            buf[i] = POOL[random.nextInt(POOL.length)];
        }
        return new String(buf);
    }
}

package io.bitpet.pet.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.repository.PetMstRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;

/**
 * 개체 일련번호 발급기 (v3 기준).
 * - 32자 풀 (0/O/I/1 제외)
 * - 초기 6자리, 풀 80% 도달 시 7자리로 자동 확장, 최대 8자리
 * - 현재 길이에서 32회 충돌 시 강제로 길이 +1 확장
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SerialNumberGenerator {

    private static final int MAX_ATTEMPTS_PER_LENGTH = 32;

    private final SerialNumberProperties properties;
    private final PetMstRepository petRepository;
    private final SecureRandom random = new SecureRandom();

    private char[] poolChars;

    @PostConstruct
    void init() {
        if (properties.pool() == null || properties.pool().isBlank()) {
            throw new IllegalStateException("bitpet.serial-number.pool must not be empty");
        }
        if (properties.initialLength() < 1 || properties.maxLength() < properties.initialLength()) {
            throw new IllegalStateException("invalid initial-length / max-length config");
        }
        if (properties.expansionThreshold() <= 0 || properties.expansionThreshold() >= 1) {
            throw new IllegalStateException("expansion-threshold must be in (0, 1)");
        }
        this.poolChars = properties.pool().toCharArray();
        log.info("SerialNumberGenerator initialized: poolSize={}, initialLength={}, threshold={}, maxLength={}",
                poolChars.length, properties.initialLength(), properties.expansionThreshold(), properties.maxLength());
    }

    public String generate() {
        int length = currentLength();
        for (int attempt = 0; attempt < MAX_ATTEMPTS_PER_LENGTH; attempt++) {
            String candidate = randomCode(length);
            if (!petRepository.existsBySerialNo(candidate)) {
                return candidate;
            }
        }
        int expanded = Math.min(length + 1, properties.maxLength());
        if (expanded == length) {
            throw new BusinessException(ErrorCode.PET_SERIAL_GENERATION_FAILED);
        }
        log.warn("Serial collision threshold reached at length {}, expanding to {}", length, expanded);
        for (int attempt = 0; attempt < MAX_ATTEMPTS_PER_LENGTH; attempt++) {
            String candidate = randomCode(expanded);
            if (!petRepository.existsBySerialNo(candidate)) {
                return candidate;
            }
        }
        throw new BusinessException(ErrorCode.PET_SERIAL_GENERATION_FAILED);
    }

    int currentLength() {
        long total = petRepository.count();
        int length = properties.initialLength();
        while (length < properties.maxLength()) {
            long capacity = capacityOf(length);
            if (capacity <= 0) break;
            if ((double) total / capacity < properties.expansionThreshold()) {
                return length;
            }
            length++;
        }
        return length;
    }

    private long capacityOf(int length) {
        long capacity = 1L;
        for (int i = 0; i < length; i++) {
            capacity *= poolChars.length;
            if (capacity < 0) return Long.MAX_VALUE;
        }
        return capacity;
    }

    private String randomCode(int length) {
        char[] buf = new char[length];
        for (int i = 0; i < length; i++) {
            buf[i] = poolChars[random.nextInt(poolChars.length)];
        }
        return new String(buf);
    }
}

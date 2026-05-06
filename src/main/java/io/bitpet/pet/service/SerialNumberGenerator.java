package io.bitpet.pet.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.repository.PetRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;

/**
 * 6자리 일련번호 발급기. 풀(0/O/I/1 제외, 32자) 사용.
 * 발급된 개수가 현재 길이 공간의 expansionThreshold(기본 80%)에 도달하면 길이 +1로 확장.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SerialNumberGenerator {

    private static final int MAX_ATTEMPTS_PER_LENGTH = 32;

    private final SerialNumberProperties properties;
    private final PetRepository petRepository;
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

    /**
     * 새 일련번호를 생성한다. DB에 중복이 없을 때까지 재시도하며,
     * 현재 길이 공간이 expansionThreshold 이상으로 채워졌으면 길이를 +1 한다.
     */
    public String generate() {
        int length = currentLength();
        for (int attempt = 0; attempt < MAX_ATTEMPTS_PER_LENGTH; attempt++) {
            String candidate = randomCode(length);
            if (!petRepository.existsBySerialNumber(candidate)) {
                return candidate;
            }
        }
        // 모든 시도가 충돌 → 한 단계 길이 확장 후 재시도
        int expanded = Math.min(length + 1, properties.maxLength());
        if (expanded == length) {
            throw new BusinessException(ErrorCode.PET_SERIAL_GENERATION_FAILED);
        }
        log.warn("Serial collision threshold reached at length {}, expanding to {}", length, expanded);
        for (int attempt = 0; attempt < MAX_ATTEMPTS_PER_LENGTH; attempt++) {
            String candidate = randomCode(expanded);
            if (!petRepository.existsBySerialNumber(candidate)) {
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
            if (capacity < 0) return Long.MAX_VALUE; // overflow guard
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

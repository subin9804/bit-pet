package io.bitpet.pet.service;

import io.bitpet.pet.domain.SerialPoolStatMst;
import io.bitpet.pet.dto.SerialPoolStatResponse;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.pet.repository.SerialPoolStatRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SerialPoolService {

    private static final double EXPANSION_THRESHOLD = 0.80;

    private final PetMstRepository petRepo;
    private final SerialPoolStatRepository statRepo;
    private final SerialNumberGenerator serialNumberGenerator;

    public List<SerialPoolStatResponse> listStats() {
        return statRepo.findAllByOrderBySerialLengthAsc()
                .stream().map(SerialPoolStatResponse::from).toList();
    }

    @Transactional
    @Scheduled(cron = "0 0 2 * * *")
    public void refreshStats() {
        long totalPets = petRepo.count();
        List<SerialPoolStatMst> stats = statRepo.findAllByOrderBySerialLengthAsc();

        int currentLength = serialNumberGenerator.currentLength();

        for (SerialPoolStatMst stat : stats) {
            long capacity = stat.getTotalCapacity();
            BigDecimal rate = capacity > 0
                    ? BigDecimal.valueOf(totalPets).divide(BigDecimal.valueOf(capacity), 4, RoundingMode.HALF_UP)
                    : BigDecimal.ONE;

            stat.refresh(totalPets, rate);

            boolean shouldBeCurrent = (stat.getSerialLength() == currentLength);
            if (shouldBeCurrent && !stat.isCurrent()) {
                stat.markCurrent(true);
                stat.markExpanded();
                log.warn("[SerialPool] Expanded to length={} (usedCount={}, rate={})",
                        stat.getSerialLength(), totalPets, rate);
            } else if (!shouldBeCurrent && stat.isCurrent()) {
                stat.markCurrent(false);
            }
        }

        statRepo.saveAll(stats);

        stats.stream()
                .filter(s -> s.getSerialLength() == currentLength)
                .findFirst()
                .ifPresent(s -> {
                    if (s.getUsageRate().doubleValue() >= EXPANSION_THRESHOLD) {
                        log.warn("[SerialPool] Usage rate {}% at length={} — approaching expansion threshold",
                                String.format("%.2f", s.getUsageRate().doubleValue() * 100), s.getSerialLength());
                    }
                });

        log.info("[SerialPool] Stats refreshed: totalPets={}, currentLength={}", totalPets, currentLength);
    }

    @Transactional
    public SerialPoolStatResponse forceRefresh() {
        refreshStats();
        return statRepo.findByCurrent(true)
                .map(SerialPoolStatResponse::from)
                .orElseThrow();
    }
}

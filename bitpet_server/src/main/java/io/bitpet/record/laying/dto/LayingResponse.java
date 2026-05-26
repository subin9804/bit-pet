package io.bitpet.record.laying.dto;

import io.bitpet.record.laying.domain.LayingDtl;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public record LayingResponse(
        Long layingId,
        Long petId,
        Long matingId,
        Instant laidAt,
        int eggCountTotal,
        Integer eggCountFertile,
        BigDecimal incubationTemp,
        BigDecimal incubationHumidity,
        String memo,
        List<HatchResponse> hatches,
        LayingHatchStats stats,
        Instant createdAt,
        Instant updatedAt
) {
    public static LayingResponse of(LayingDtl laying, List<HatchResponse> hatches) {
        long hatchedCount = hatches.stream().filter(h -> h.status().name().equals("HATCHED")).count();
        long failedCount  = hatches.stream().filter(h -> h.status().name().equals("FAILED") || h.status().name().equals("SLUG")).count();
        long pendingCount = hatches.stream().filter(h -> h.status().name().equals("PENDING")).count();

        return new LayingResponse(
                laying.getId(),
                laying.getPetId(),
                laying.getMatingId(),
                laying.getLaidAt(),
                laying.getEggCountTotal(),
                laying.getEggCountFertile(),
                laying.getIncubationTemp(),
                laying.getIncubationHumidity(),
                laying.getMemo(),
                hatches,
                new LayingHatchStats(hatchedCount, failedCount, pendingCount),
                laying.getCreatedAt(),
                laying.getUpdatedAt()
        );
    }
}

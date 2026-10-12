package io.bitpet.record.laying.dto;

import io.bitpet.pet.domain.PetMst;
import io.bitpet.record.laying.domain.LayingDtl;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public record LayingResponse(
        Long layingId,
        Long petId,
        /** 어미 이름 — '알' 탭의 클러치 카드가 개체를 따로 조회하지 않도록 같이 내린다 */
        String petName,
        String speciesName,
        Long matingId,
        Instant laidAt,
        int eggCountTotal,
        Integer eggCountFertile,
        BigDecimal incubationTemp,
        BigDecimal incubationHumidity,
        String memo,
        List<HatchResponse> hatches,
        List<LayingNoteResponse> notes,
        LayingHatchStats stats,
        Instant createdAt,
        Instant updatedAt
) {
    public static LayingResponse of(LayingDtl laying, List<HatchResponse> hatches) {
        return of(laying, hatches, List.of(), null);
    }

    public static LayingResponse of(LayingDtl laying, List<HatchResponse> hatches,
                                    List<LayingNoteResponse> notes, PetMst pet) {
        long hatchedCount = hatches.stream().filter(h -> h.status().name().equals("HATCHED")).count();
        long failedCount  = hatches.stream().filter(h -> h.status().name().equals("FAILED") || h.status().name().equals("SLUG")).count();
        long pendingCount = hatches.stream().filter(h -> h.status().name().equals("PENDING")).count();

        return new LayingResponse(
                laying.getId(),
                laying.getPetId(),
                pet != null ? pet.getName() : null,
                pet != null && pet.getSpecies() != null ? pet.getSpecies().getNameKo() : null,
                laying.getMatingId(),
                laying.getLaidAt(),
                laying.getEggCountTotal(),
                laying.getEggCountFertile(),
                laying.getIncubationTemp(),
                laying.getIncubationHumidity(),
                laying.getMemo(),
                hatches,
                notes != null ? notes : List.of(),
                new LayingHatchStats(hatchedCount, failedCount, pendingCount),
                laying.getCreatedAt(),
                laying.getUpdatedAt()
        );
    }
}

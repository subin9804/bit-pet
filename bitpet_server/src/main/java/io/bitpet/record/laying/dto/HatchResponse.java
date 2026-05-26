package io.bitpet.record.laying.dto;

import io.bitpet.pet.domain.PetMst;
import io.bitpet.record.laying.domain.HatchStatus;
import io.bitpet.record.laying.domain.LayingHatchDtl;
import io.bitpet.record.mating.dto.PetSummaryDto;

import java.time.Instant;

public record HatchResponse(
        Long hatchId,
        HatchStatus status,
        Instant hatchedAt,
        Long hatchedPetId,
        PetSummaryDto hatchedPetSummary,
        String memo,
        Instant createdAt,
        Instant updatedAt
) {
    public static HatchResponse of(LayingHatchDtl hatch, PetMst hatchedPet) {
        return new HatchResponse(
                hatch.getId(),
                hatch.getStatus(),
                hatch.getHatchedAt(),
                hatch.getHatchedPetId(),
                PetSummaryDto.from(hatchedPet),
                hatch.getMemo(),
                hatch.getCreatedAt(),
                hatch.getUpdatedAt()
        );
    }
}

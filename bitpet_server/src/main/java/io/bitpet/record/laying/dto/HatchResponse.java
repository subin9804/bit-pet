package io.bitpet.record.laying.dto;

import io.bitpet.pet.domain.PetMst;
import io.bitpet.record.laying.domain.HatchStatus;
import io.bitpet.record.laying.domain.LayingHatchDtl;
import io.bitpet.record.mating.dto.PetSummaryDto;

import java.time.Instant;

public record HatchResponse(
        Long hatchId,
        Integer eggIndex,
        HatchStatus status,
        Instant hatchedAt,
        Long hatchedPetId,
        PetSummaryDto hatchedPetSummary,
        String memo,
        Instant createdAt,
        Instant updatedAt
) {
    /**
     * {@code hatchedPet} 은 {@code hatchedPetId} 로 조회한 개체이고, <b>없으면 null 이다</b>
     * (소프트 삭제된 개체는 {@code @SQLRestriction} 때문에 조회에 걸리지 않는다).
     *
     * <p>⚠️ <b>개체를 못 찾으면 id 도 내리지 않는다.</b> 앱은 {@code hatchedPetId != null} 로
     * '등록됨'을 판정하고 탭하면 {@code /pets/{id}} 로 보내므로, id 만 살려 내보내면
     * 알 칸이 등록된 것처럼 보이는데 눌러도 없는 개체로 가는 유령 상태가 된다.
     * ⛔ 둘을 따로 내보내지 말 것 — 하나의 사실이다.
     */
    public static HatchResponse of(LayingHatchDtl hatch, PetMst hatchedPet) {
        return new HatchResponse(
                hatch.getId(),
                hatch.getEggIndex(),
                hatch.getStatus(),
                hatch.getHatchedAt(),
                hatchedPet != null ? hatch.getHatchedPetId() : null,
                PetSummaryDto.from(hatchedPet),
                hatch.getMemo(),
                hatch.getCreatedAt(),
                hatch.getUpdatedAt()
        );
    }
}

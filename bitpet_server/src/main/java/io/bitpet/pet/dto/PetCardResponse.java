package io.bitpet.pet.dto;

import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.domain.RelationType;

import java.time.LocalDate;
import java.util.List;

/**
 * 가계도 노드 / 남의 개체 공개 조회용 카드.
 *
 * <p><b>{@link PetResponse} 를 재사용하지 않는 이유</b>: 가계도에는 남의 개체가 그대로
 * 섞인다. 부모 등록에 승인이 없으니 내가 모르는 사람의 개체가 부모로 걸려 있을 수 있고,
 * 반대로 내 개체가 남의 가계도에 자식으로 걸릴 수도 있다. 그런 개체까지
 * PetResponse 를 통째로 내려주면 메모·입양일·최근 체중 같은 사육 기록이 따라 나간다.
 * 여기 있는 필드가 남에게 보여도 되는 전부다 — 이름, 종·모프, 성별, 해칭일, 썸네일.
 *
 * @param relationId   가계도 노드일 때만. 공개 조회는 null
 * @param relationType FATHER / MOTHER. 공개 조회는 null
 * @param privateYn    'Y' 비공개 / 'N' 공개(검색 허용)
 * @param isKeeper     요청자가 이 개체의 사육자(OWNER/KEEPER)인지 → 전체 상세 화면으로 갈 수 있다
 * @param canOpenDetail 요청자가 개체 상세로 들어갈 수 있는지 (사육자이거나 공개 개체).
 *                      false 면 앱은 이 카드의 정보만으로 바텀시트를 띄운다
 */
public record PetCardResponse(
        Long relationId,
        RelationType relationType,
        Long petId,
        String name,
        String serialNo,
        PetGender gender,
        Long speciesId,
        String speciesNameKo,
        List<MorphCdResponse> morphs,
        LocalDate hatchingDate,
        String hatchingDatePrecision,
        Boolean hatchingDateApproximate,
        LocalDate deceasedAt,
        String colorCode,
        String profileImageUrl,
        String privateYn,
        boolean isKeeper,
        boolean canOpenDetail,
        PetOwnerResponse owner
) {
    public static PetCardResponse of(PetMst pet,
                                     Long relationId,
                                     RelationType relationType,
                                     String profileImageUrl,
                                     boolean isKeeper,
                                     PetOwnerResponse owner) {
        return new PetCardResponse(
                relationId,
                relationType,
                pet.getId(),
                pet.getName(),
                pet.getSerialNo(),
                pet.getGender(),
                pet.getSpecies() != null ? pet.getSpecies().getId() : null,
                pet.getSpecies() != null ? pet.getSpecies().getNameKo() : null,
                pet.getMorphs().stream().map(rls -> MorphCdResponse.from(rls.getMorph())).toList(),
                pet.getHatchingDate(),
                pet.getHatchingDatePrecision() != null ? pet.getHatchingDatePrecision() : "DAY",
                pet.getHatchingDateApproximate() != null ? pet.getHatchingDateApproximate() : false,
                pet.getDeceasedAt(),
                pet.getColorCode(),
                profileImageUrl,
                pet.getPrivateYn(),
                isKeeper,
                isKeeper || "N".equals(pet.getPrivateYn()),
                owner
        );
    }
}

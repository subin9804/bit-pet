package io.bitpet.pet.dto;

import java.util.List;

/**
 * 가계도 조회 응답.
 *
 * <p>부모·자식은 남의 개체일 수 있어 {@link PetCardResponse}(소유자 포함, 사육 기록 제외)로 내린다.
 * 가운데 개체({@code pet})는 요청자가 사육자인 개체이므로 전체 정보를 그대로 준다.
 *
 * <p>{@code grandparents} 는 부모별로 묶은 조부모다 — 앱 가계도 탭이 조부모·부모·개체·자식
 * 네 세대를 그린다. 부모가 남의 개체여도 그 부모 카드는 이미 이 응답에 실리므로, 한 세대 위도
 * 같은 카드 규칙(사육 기록 제외)으로 내린다. 그 이상은 내리지 않는다.
 *
 * <p>{@code siblings} 는 동배(같은 클러치 또는 같은 부모·해칭일). 요청자가 사육하거나 공개된
 * 개체만 싣는다 — 판정은 {@code PetService.findClutchmates}.
 */
public record GenealogyResponse(
        PetResponse pet,
        List<PetCardResponse> parents,
        List<PetCardResponse> children,
        List<Grandparents> grandparents,
        List<PetCardResponse> siblings
) {
    /** {@code parentPetId} 개체의 부모들 (= 가운데 개체의 조부모). */
    public record Grandparents(Long parentPetId, List<PetCardResponse> parents) {}
}

package io.bitpet.pet.dto;

import java.util.List;

/**
 * 가계도 조회 응답.
 *
 * <p>부모·자식은 남의 개체일 수 있어 {@link PetCardResponse}(소유자 포함, 사육 기록 제외)로 내린다.
 * 가운데 개체({@code pet})는 요청자가 사육자인 개체이므로 전체 정보를 그대로 준다.
 */
public record GenealogyResponse(
        PetResponse pet,
        List<PetCardResponse> parents,
        List<PetCardResponse> children
) {}

package io.bitpet.pet.dto;

/**
 * 이름 사용 가능 여부.
 *
 * <p>{@code name} 을 되돌려주는 이유: 폼은 입력할 때마다 물어보므로 응답이 순서대로 오지
 * 않는다. 어느 입력에 대한 답인지 모르면 한 글자 전의 결과가 현재 입력을 덮어 "쓸 수 있는
 * 이름인데 빨간 글씨"가 남는다.
 */
public record PetNameAvailabilityResponse(
        String name,
        boolean available
) {}

package io.bitpet.pet.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * 내 개체 목록 순서 저장 — 앱이 보여주는 순서 그대로의 개체 id.
 *
 * <p>순서는 사람마다 따로 저장된다(공유받은 개체도 내 목록에서의 자리만 바뀐다).
 * 내가 사육하지 않는 id 는 무시하고, 빠진 내 개체는 뒤로 붙인다.
 */
public record PetReorderRequest(
        @NotNull(message = "순서를 보내주세요")
        @Size(max = 500, message = "한 번에 최대 500마리까지 정렬할 수 있습니다")
        List<Long> petIds
) {}

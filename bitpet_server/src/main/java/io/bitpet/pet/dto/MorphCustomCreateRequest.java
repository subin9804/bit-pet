package io.bitpet.pet.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** 카탈로그에 없는 조합 모프를 사용자가 직접 등록할 때 (V7). */
public record MorphCustomCreateRequest(
        @NotBlank(message = "모프 이름을 입력해주세요.")
        @Size(max = 100, message = "모프 이름은 100자를 넘을 수 없습니다.")
        String nameKo
) {
}

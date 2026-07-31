package io.bitpet.nfc.dto;

import io.bitpet.nfc.domain.TagActionCd;
import jakarta.validation.constraints.NotNull;

public record TagLinkRequest(
        @NotNull Long petId,
        /** 생략 시 PET_DETAIL */
        TagActionCd defaultActionCd
) {}

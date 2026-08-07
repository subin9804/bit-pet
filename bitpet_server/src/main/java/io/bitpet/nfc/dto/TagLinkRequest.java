package io.bitpet.nfc.dto;

import jakarta.validation.constraints.NotNull;

/** 태그를 어느 개체에 붙일지. 태그별 동작 지정은 없다 (V52) */
public record TagLinkRequest(
        @NotNull Long petId
) {}

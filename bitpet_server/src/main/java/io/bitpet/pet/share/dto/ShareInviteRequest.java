package io.bitpet.pet.share.dto;

import io.bitpet.pet.share.domain.ShareInviteType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/** 개체 공유·입분양 초대 요청 (대상은 공유코드로 식별) */
public record ShareInviteRequest(
        @NotBlank String shareCode,
        @NotNull ShareInviteType inviteType
) {}

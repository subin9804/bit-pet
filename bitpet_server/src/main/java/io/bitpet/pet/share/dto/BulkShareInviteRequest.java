package io.bitpet.pet.share.dto;

import io.bitpet.pet.share.domain.ShareInviteType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.util.List;

/** 여러 개체를 한 번에 공유·입분양 초대 (대상은 공유코드로 식별) */
public record BulkShareInviteRequest(
        @NotBlank String shareCode,
        @NotNull ShareInviteType inviteType,
        @NotEmpty List<Long> petIds
) {}

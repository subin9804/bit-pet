package io.bitpet.pet.share.dto;

import io.bitpet.pet.share.domain.PetShareInvitation;
import io.bitpet.pet.share.domain.ShareInviteStatus;
import io.bitpet.pet.share.domain.ShareInviteType;

import java.time.Instant;

/** 공유·입분양 초대 응답 (받은/보낸 함 공용) */
public record ShareInvitationResponse(
        Long id,
        Long petId,
        String petName,
        Long inviterUserId,
        String inviterName,
        Long inviteeUserId,
        String inviteeName,
        ShareInviteType inviteType,
        ShareInviteStatus status,
        Instant createdAt,
        Instant expiresAt,
        Instant respondedAt
) {
    public static ShareInvitationResponse of(PetShareInvitation inv, String petName,
                                             String inviterName, String inviteeName) {
        return new ShareInvitationResponse(
                inv.getId(), inv.getPetId(), petName,
                inv.getInviterUserId(), inviterName,
                inv.getInviteeUserId(), inviteeName,
                inv.getInviteType(), inv.getStatus(),
                inv.getCreatedAt(), inv.getExpiresAt(), inv.getRespondedAt());
    }
}

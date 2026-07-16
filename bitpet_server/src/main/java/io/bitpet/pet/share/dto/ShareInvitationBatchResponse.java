package io.bitpet.pet.share.dto;

import io.bitpet.pet.share.domain.PetShareInvitation;
import io.bitpet.pet.share.domain.ShareInviteStatus;
import io.bitpet.pet.share.domain.ShareInviteType;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * 배치(벌크) 초대 응답 — 같은 batch_id 로 묶인 초대들을 한 카드로 표현.
 * 받은 초대함/벌크 초대 결과 공용.
 */
public record ShareInvitationBatchResponse(
        UUID batchId,
        Long inviterUserId,
        String inviterName,
        Long inviteeUserId,
        String inviteeName,
        ShareInviteType inviteType,
        Instant createdAt,
        Instant expiresAt,
        List<PetItem> pets
) {
    /** 배치에 포함된 개체 1건 */
    public record PetItem(
            Long invitationId,
            Long petId,
            String petName,
            ShareInviteStatus status
    ) {}

    /**
     * 같은 배치의 초대 목록으로 응답 조립.
     * @param items      배치 초대 행들 (동일 batch_id 가정)
     * @param petNames   petId → petName
     * @param inviterName / inviteeName 표시용 이름
     */
    public static ShareInvitationBatchResponse of(
            List<PetShareInvitation> items,
            java.util.function.Function<Long, String> petNames,
            String inviterName,
            String inviteeName) {
        PetShareInvitation head = items.get(0);
        List<PetItem> pets = items.stream()
                .map(inv -> new PetItem(
                        inv.getId(), inv.getPetId(),
                        petNames.apply(inv.getPetId()), inv.getStatus()))
                .toList();
        return new ShareInvitationBatchResponse(
                head.getBatchId(),
                head.getInviterUserId(), inviterName,
                head.getInviteeUserId(), inviteeName,
                head.getInviteType(),
                head.getCreatedAt(), head.getExpiresAt(),
                pets);
    }
}

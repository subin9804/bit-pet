package io.bitpet.pet.share.dto;

import io.bitpet.pet.domain.PetKeeperRole;

import java.time.Instant;

/** 개체 사육자(공유 멤버) 응답 */
public record KeeperResponse(
        Long userId,
        String name,
        String profileImageUrl,
        PetKeeperRole role,
        Instant joinedAt
) {}

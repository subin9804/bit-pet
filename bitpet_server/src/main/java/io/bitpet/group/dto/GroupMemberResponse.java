package io.bitpet.group.dto;

import io.bitpet.group.domain.BreedingGroupUserRls;
import io.bitpet.group.domain.GroupRole;

import java.time.Instant;

public record GroupMemberResponse(
        Long userId,
        String name,
        String email,
        GroupRole role,
        Instant joinedAt
) {
    public static GroupMemberResponse of(BreedingGroupUserRls rls, String name, String email) {
        return new GroupMemberResponse(
                rls.getUserId(),
                name,
                email,
                rls.getRole(),
                rls.getJoinedAt()
        );
    }
}

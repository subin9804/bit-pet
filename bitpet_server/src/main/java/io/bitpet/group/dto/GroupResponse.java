package io.bitpet.group.dto;

import io.bitpet.group.domain.BreedingGroupMst;
import io.bitpet.group.domain.GroupRole;

import java.util.List;

public record GroupResponse(
        Long id,
        String name,
        String inviteCode,
        Long ownerId,
        GroupRole myRole,
        List<GroupMemberResponse> members
) {
    public static GroupResponse of(BreedingGroupMst group, GroupRole myRole,
                                   List<GroupMemberResponse> members) {
        return new GroupResponse(
                group.getId(),
                group.getName(),
                group.getInviteCode(),
                group.getOwnerId(),
                myRole,
                members
        );
    }
}

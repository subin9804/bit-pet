package io.bitpet.group.domain;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Getter
@Table(
        name = "breeding_group_user_rls",
        indexes = {
                @Index(name = "idx_breeding_group_user_group", columnList = "group_id")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class BreedingGroupUserRls {

    @EmbeddedId
    private BreedingGroupUserRlsId id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private GroupRole role;

    @Column(name = "joined_at", nullable = false, updatable = false)
    private Instant joinedAt;

    public static BreedingGroupUserRls of(Long groupId, Long userId, GroupRole role) {
        BreedingGroupUserRls rls = new BreedingGroupUserRls();
        rls.id       = new BreedingGroupUserRlsId(groupId, userId);
        rls.role     = role;
        rls.joinedAt = Instant.now();
        return rls;
    }

    public Long getGroupId() { return id.getGroupId(); }
    public Long getUserId()  { return id.getUserId(); }
}

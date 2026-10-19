package io.bitpet.pet.domain;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * 개체-사육자 연결. 개체 접근 권한 판정의 단일 소스.
 * role = OWNER(소유자, 개체당 1명) / KEEPER(공유받은 사육자)
 */
@Entity
@Getter
@Table(
        name = "pet_keeper_rls",
        indexes = {
                @Index(name = "idx_pet_keeper_user", columnList = "user_id")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PetKeeperRls {

    @EmbeddedId
    private PetKeeperRlsId id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PetKeeperRole role;

    @Column(name = "joined_at", nullable = false, updatable = false)
    private Instant joinedAt;

    /** 이 사람의 목록에서의 순서 — 작을수록 위. 사람마다 따로라 공유받은 쪽이 바꿔도 소유자 목록은 그대로. */
    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    public static PetKeeperRls of(Long petId, Long userId, PetKeeperRole role, int sortOrder) {
        PetKeeperRls rls = of(petId, userId, role);
        rls.sortOrder = sortOrder;
        return rls;
    }

    public static PetKeeperRls of(Long petId, Long userId, PetKeeperRole role) {
        PetKeeperRls rls = new PetKeeperRls();
        rls.id       = new PetKeeperRlsId(petId, userId);
        rls.role     = role;
        rls.joinedAt = Instant.now();
        return rls;
    }

    public Long getPetId()  { return id.getPetId(); }
    public Long getUserId() { return id.getUserId(); }

    public void promoteToOwner() { this.role = PetKeeperRole.OWNER; }

    public void changeSortOrder(int sortOrder) { this.sortOrder = sortOrder; }

    public boolean isOwner() { return role == PetKeeperRole.OWNER; }
}

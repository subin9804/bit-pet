package io.bitpet.group.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.SQLRestriction;

import java.time.Instant;

@Entity
@Getter
@Table(
        name = "breeding_group_mst",
        indexes = {
                @Index(name = "idx_breeding_group_owner", columnList = "owner_id")
        }
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class BreedingGroupMst extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(name = "owner_id", nullable = false)
    private Long ownerId;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private BreedingGroupMst(String name, Long ownerId) {
        this.name    = name;
        this.ownerId = ownerId;
    }

    public void updateName(String name) { this.name = name; }

    public void softDelete() { this.deletedAt = Instant.now(); }
}

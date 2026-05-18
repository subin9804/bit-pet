package io.bitpet.pet.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(
        name = "pet_relation_rls",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_pet_relation",
                        columnNames = {"parent_pet_id", "child_pet_id", "relation_type"})
        },
        indexes = {
                @Index(name = "idx_pet_relation_child", columnList = "child_pet_id")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PetRelationRls extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "parent_pet_id", nullable = false,
            foreignKey = @jakarta.persistence.ForeignKey(name = "fk_pet_relation_parent"))
    private PetMst parentPet;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "child_pet_id", nullable = false,
            foreignKey = @jakarta.persistence.ForeignKey(name = "fk_pet_relation_child"))
    private PetMst childPet;

    @Enumerated(EnumType.STRING)
    @Column(name = "relation_type", nullable = false, length = 10)
    private RelationType relationType;

    @Builder
    private PetRelationRls(PetMst parentPet, PetMst childPet, RelationType relationType) {
        this.parentPet = parentPet;
        this.childPet = childPet;
        this.relationType = relationType;
    }
}

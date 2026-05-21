package io.bitpet.routine.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(
        name = "routine_pet_rls",
        uniqueConstraints = @UniqueConstraint(name = "uq_routine_pet_rls", columnNames = {"routine_id", "pet_id"}),
        indexes = {
                @Index(name = "idx_routine_pet_rls_routine", columnList = "routine_id"),
                @Index(name = "idx_routine_pet_rls_pet",     columnList = "pet_id")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RoutinePetRls extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "routine_id", nullable = false)
    private Long routineId;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Builder
    private RoutinePetRls(Long routineId, Long petId) {
        this.routineId = routineId;
        this.petId     = petId;
    }
}

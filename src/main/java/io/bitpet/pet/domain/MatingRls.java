package io.bitpet.pet.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Entity
@Getter
@Table(
        name = "mating_rls",
        indexes = {
                @Index(name = "idx_mating_rls_male",      columnList = "male_pet_id"),
                @Index(name = "idx_mating_rls_female",    columnList = "female_pet_id"),
                @Index(name = "idx_mating_rls_date_desc", columnList = "mating_date")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MatingRls extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "male_pet_id", nullable = false,
            foreignKey = @jakarta.persistence.ForeignKey(name = "fk_mating_rls_male"))
    private PetMst malePet;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "female_pet_id", nullable = false,
            foreignKey = @jakarta.persistence.ForeignKey(name = "fk_mating_rls_female"))
    private PetMst femalePet;

    @Column(name = "mating_date", nullable = false)
    private LocalDate matingDate;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Builder
    private MatingRls(PetMst malePet, PetMst femalePet, LocalDate matingDate, String memo) {
        this.malePet = malePet;
        this.femalePet = femalePet;
        this.matingDate = matingDate;
        this.memo = memo;
    }
}

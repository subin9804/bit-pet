package io.bitpet.pet.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.Getter;

@Entity
@Getter
@Table(
        name = "morph_cd",
        indexes = @Index(name = "idx_morph_cd_species", columnList = "species_id")
)
public class MorphCd extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "species_id", nullable = false)
    private Long speciesId;

    @Column(name = "name_ko", nullable = false, length = 50)
    private String nameKo;

    @Column(name = "name_en", length = 50)
    private String nameEn;

    @Column(name = "display_order", nullable = false)
    private Short displayOrder;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive;
}

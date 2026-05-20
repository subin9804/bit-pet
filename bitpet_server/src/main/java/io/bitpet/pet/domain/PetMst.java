package io.bitpet.pet.domain;

import io.bitpet.common.entity.BaseSyncEntity;
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
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.SQLRestriction;

import java.time.Instant;
import java.time.LocalDate;

@Entity
@Getter
@Table(
        name = "pet_mst",
        indexes = {
                @Index(name = "idx_pet_mst_user_id",    columnList = "user_id, deleted_at"),
                @Index(name = "idx_pet_mst_species_id", columnList = "species_id")
        }
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PetMst extends BaseSyncEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "serial_no", nullable = false, length = 8, updatable = false)
    private String serialNo;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "species_id",
            foreignKey = @jakarta.persistence.ForeignKey(name = "fk_pet_mst_species"))
    private SpeciesCd species;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "morph_id",
            foreignKey = @jakarta.persistence.ForeignKey(name = "fk_pet_mst_morph"))
    private MorphCd morph;

    @Column(nullable = false, length = 50)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private PetGender gender;

    @Column(name = "color_code", length = 7)
    private String colorCode;

    @Column(name = "environment_memo", columnDefinition = "TEXT")
    private String environmentMemo;

    @Column(name = "breeding_date")
    private LocalDate breedingDate;

    @Column(name = "hatching_date")
    private LocalDate hatchingDate;

    @Column(name = "adoption_date")
    private LocalDate adoptionDate;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "profile_photo_id")
    private Long profilePhotoId;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private PetMst(String serialNo, Long userId, SpeciesCd species, MorphCd morph,
                   String name, PetGender gender, String colorCode, String environmentMemo,
                   String description, LocalDate breedingDate, LocalDate hatchingDate,
                   LocalDate adoptionDate) {
        this.serialNo = serialNo;
        this.userId = userId;
        this.species = species;
        this.morph = morph;
        this.name = name;
        this.gender = gender != null ? gender : PetGender.UNKNOWN;
        this.colorCode = colorCode;
        this.environmentMemo = environmentMemo;
        this.description = description;
        this.breedingDate = breedingDate;
        this.hatchingDate = hatchingDate;
        this.adoptionDate = adoptionDate;
    }

    public void updateProfile(String name, SpeciesCd species, MorphCd morph, PetGender gender,
                              String colorCode, String environmentMemo, String description,
                              LocalDate breedingDate, LocalDate hatchingDate, LocalDate adoptionDate) {
        if (name != null) this.name = name;
        if (species != null) this.species = species;
        if (morph != null) this.morph = morph;
        if (gender != null) this.gender = gender;
        if (colorCode != null) this.colorCode = colorCode;
        if (environmentMemo != null) this.environmentMemo = environmentMemo;
        if (description != null) this.description = description;
        if (breedingDate != null) this.breedingDate = breedingDate;
        if (hatchingDate != null) this.hatchingDate = hatchingDate;
        if (adoptionDate != null) this.adoptionDate = adoptionDate;
    }

    public void setProfilePhoto(Long photoId) {
        this.profilePhotoId = photoId;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}

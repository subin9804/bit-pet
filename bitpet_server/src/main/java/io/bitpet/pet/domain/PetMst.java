package io.bitpet.pet.domain;

import io.bitpet.common.entity.BaseSyncEntity;
import jakarta.persistence.CascadeType;
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
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.SQLRestriction;

import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

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

    /**
     * 소유자 — <b>표시용 비정규화 값</b>이고, 권한 판정은 pet_keeper_rls(PetKeeperService)가 한다.
     * NULL 은 탈퇴 익명화 개체다(V53). 남의 가계도에 부모로 박혀 있는 개체는 주인이 탈퇴해도
     * 지울 수 없어서(자식 쪽 가계도가 끊긴다) 소유자만 떼어내고 개체는 남긴다.
     */
    @Column(name = "user_id")
    private Long userId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "species_id",
            foreignKey = @jakarta.persistence.ForeignKey(name = "fk_pet_mst_species"))
    private SpeciesCd species;

    @OneToMany(mappedBy = "pet", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<PetMorphRls> morphs = new ArrayList<>();

    @Column(nullable = false, length = 50)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private PetGender gender;

    @Column(name = "color_code", length = 7)
    private String colorCode;

    @Column(name = "breeding_date")
    private LocalDate breedingDate;

    @Column(name = "hatching_date")
    private LocalDate hatchingDate;

    @Column(name = "hatching_date_precision", length = 5)
    private String hatchingDatePrecision = "DAY";

    @Column(name = "hatching_date_approximate", nullable = false)
    private Boolean hatchingDateApproximate = false;

    @Column(name = "adoption_date")
    private LocalDate adoptionDate;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "profile_photo_id")
    private Long profilePhotoId;

    @Column(name = "private_yn", nullable = false, length = 1)
    private String privateYn = "Y";

    // NULL = 생존, 값 있으면 폐사일 (이별하기)
    @Column(name = "deceased_at")
    private LocalDate deceasedAt;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private PetMst(String serialNo, Long userId, SpeciesCd species,
                   String name, PetGender gender, String colorCode,
                   String description, LocalDate breedingDate, LocalDate hatchingDate,
                   String hatchingDatePrecision, Boolean hatchingDateApproximate,
                   LocalDate adoptionDate) {
        this.serialNo = serialNo;
        this.userId = userId;
        this.species = species;
        this.name = name;
        this.gender = gender != null ? gender : PetGender.UNKNOWN;
        this.colorCode = colorCode;
        this.description = description;
        this.breedingDate = breedingDate;
        this.hatchingDate = hatchingDate;
        this.hatchingDatePrecision = hatchingDatePrecision != null ? hatchingDatePrecision : "DAY";
        this.hatchingDateApproximate = hatchingDateApproximate != null ? hatchingDateApproximate : false;
        this.adoptionDate = adoptionDate;
        this.privateYn = "Y";
    }

    public void updateProfile(String name, SpeciesCd species, PetGender gender,
                              String colorCode, String description,
                              LocalDate breedingDate, LocalDate hatchingDate,
                              String hatchingDatePrecision, Boolean hatchingDateApproximate,
                              LocalDate adoptionDate) {
        if (name != null) this.name = name;
        if (species != null) this.species = species;
        if (gender != null) this.gender = gender;
        if (colorCode != null) this.colorCode = colorCode;
        if (description != null) this.description = description;
        if (breedingDate != null) this.breedingDate = breedingDate;
        if (hatchingDate != null) this.hatchingDate = hatchingDate;
        if (hatchingDatePrecision != null) this.hatchingDatePrecision = hatchingDatePrecision;
        if (hatchingDateApproximate != null) this.hatchingDateApproximate = hatchingDateApproximate;
        if (adoptionDate != null) this.adoptionDate = adoptionDate;
    }

    public void updatePrivacy(String privateYn) {
        if (privateYn != null) this.privateYn = privateYn;
    }

    public void setProfilePhoto(Long photoId) {
        this.profilePhotoId = photoId;
    }

    /** 입분양 — 소유자 이전 시 pet_mst.user_id 동기화 (권한 판정은 pet_keeper_rls) */
    public void transferOwnerTo(Long newOwnerUserId) { this.userId = newOwnerUserId; }

    public void markDeceased(LocalDate date) {
        this.deceasedAt = date != null ? date : LocalDate.now();
    }

    public void revertDeceased() {
        this.deceasedAt = null;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}

package io.bitpet.record.mating.domain;

import io.bitpet.common.entity.BaseSyncEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.SQLRestriction;

import java.time.Instant;

@Entity
@Getter
@Table(
        name = "mating_dtl",
        indexes = {
                @Index(name = "idx_mating_dtl_male",   columnList = "male_pet_id, tried_at"),
                @Index(name = "idx_mating_dtl_female", columnList = "female_pet_id, tried_at"),
                @Index(name = "idx_mating_dtl_season", columnList = "season_label")
        }
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MatingDtl extends BaseSyncEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "male_pet_id")
    private Long malePetId;

    @Column(name = "female_pet_id")
    private Long femalePetId;

    @Column(name = "external_partner_text", length = 255)
    private String externalPartnerText;

    @Column(name = "tried_at", nullable = false)
    private Instant triedAt;

    @Column(name = "duration_minutes")
    private Integer durationMinutes;

    @Column(name = "is_successful")
    private Boolean isSuccessful;

    @Column(name = "season_label", nullable = false, length = 20)
    private String seasonLabel;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private MatingDtl(Long malePetId, Long femalePetId, String externalPartnerText,
                      Instant triedAt, Integer durationMinutes, Boolean isSuccessful,
                      String seasonLabel, String memo) {
        this.malePetId = malePetId;
        this.femalePetId = femalePetId;
        this.externalPartnerText = externalPartnerText;
        this.triedAt = triedAt;
        this.durationMinutes = durationMinutes;
        this.isSuccessful = isSuccessful;
        this.seasonLabel = seasonLabel;
        this.memo = memo;
    }

    public void update(Long malePetId, Long femalePetId, String externalPartnerText,
                       Instant triedAt, Integer durationMinutes, Boolean isSuccessful,
                       String seasonLabel, String memo) {
        this.malePetId = malePetId;
        this.femalePetId = femalePetId;
        this.externalPartnerText = externalPartnerText;
        if (triedAt != null)     this.triedAt = triedAt;
        this.durationMinutes = durationMinutes;
        this.isSuccessful = isSuccessful;
        if (seasonLabel != null) this.seasonLabel = seasonLabel;
        this.memo = memo;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}

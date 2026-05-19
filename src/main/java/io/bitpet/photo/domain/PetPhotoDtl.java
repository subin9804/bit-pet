package io.bitpet.photo.domain;

import io.bitpet.common.entity.BaseTimeEntity;
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

import java.time.Instant;

@Entity
@Getter
@Table(
        name = "pet_photo_dtl",
        indexes = @Index(name = "idx_pet_photo_dtl_pet_time", columnList = "pet_id, taken_at")
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PetPhotoDtl extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Column(name = "s3_key", nullable = false, length = 255)
    private String s3Key;

    @Column(name = "file_size")
    private Integer fileSize;

    @Column(name = "mime_type", length = 50)
    private String mimeType;

    @Column
    private Integer width;

    @Column
    private Integer height;

    @Column(name = "taken_at")
    private Instant takenAt;

    @Column(columnDefinition = "TEXT")
    private String caption;

    @Builder
    private PetPhotoDtl(Long petId, String s3Key, Integer fileSize, String mimeType,
                        Integer width, Integer height, Instant takenAt, String caption) {
        this.petId    = petId;
        this.s3Key    = s3Key;
        this.fileSize = fileSize;
        this.mimeType = mimeType;
        this.width    = width;
        this.height   = height;
        this.takenAt  = takenAt;
        this.caption  = caption;
    }
}

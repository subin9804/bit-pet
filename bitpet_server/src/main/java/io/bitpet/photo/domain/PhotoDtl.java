package io.bitpet.photo.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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

/**
 * 폴리모픽 사진 테이블 — PET / MEMO / MATING / LAYING
 * V20 마이그레이션에서 pet_photo_dtl → photo_dtl 전환 (ID 보존)
 */
@Entity
@Getter
@Table(
        name = "photo_dtl",
        indexes = {
                @Index(name = "idx_photo_entity",      columnList = "entity_type, entity_id, display_order"),
                @Index(name = "idx_photo_entity_time", columnList = "entity_type, entity_id, taken_at")
        }
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PhotoDtl extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    @Column(name = "entity_type", nullable = false, length = 20)
    private EntityType entityType;

    @Column(name = "entity_id", nullable = false)
    private Long entityId;

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

    @Column(name = "display_order", nullable = false)
    private int displayOrder;

    @Column(name = "taken_at")
    private Instant takenAt;

    @Column(columnDefinition = "TEXT")
    private String caption;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private PhotoDtl(EntityType entityType, Long entityId, String s3Key,
                     Integer fileSize, String mimeType, Integer width, Integer height,
                     int displayOrder, Instant takenAt, String caption) {
        this.entityType = entityType;
        this.entityId = entityId;
        this.s3Key = s3Key;
        this.fileSize = fileSize;
        this.mimeType = mimeType;
        this.width = width;
        this.height = height;
        this.displayOrder = displayOrder;
        this.takenAt = takenAt;
        this.caption = caption;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}

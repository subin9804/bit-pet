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

    /**
     * 썸네일 키(짧은 변 512px 기준 JPEG). <b>NULL 이면 썸네일이 없다</b> — 기존 사진을 백필하지
     * 않았고, 썸네일은 앱이 업로드 시점에 만들어 같이 올리므로 구버전 앱이 올린 사진에도 없다.
     * 응답은 이 경우 {@code thumbnailUrl} 을 비워 내리고 앱이 원본으로 폴백한다.
     */
    @Column(name = "thumb_s3_key", length = 255)
    private String thumbS3Key;

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
    private PhotoDtl(EntityType entityType, Long entityId, String s3Key, String thumbS3Key,
                     Integer fileSize, String mimeType, Integer width, Integer height,
                     int displayOrder, Instant takenAt, String caption) {
        this.entityType = entityType;
        this.entityId = entityId;
        this.s3Key = s3Key;
        this.thumbS3Key = thumbS3Key;
        this.fileSize = fileSize;
        this.mimeType = mimeType;
        this.width = width;
        this.height = height;
        this.displayOrder = displayOrder;
        this.takenAt = takenAt;
        this.caption = caption;
    }

    /**
     * 목록·아바타처럼 <b>작게 그려지는 자리</b>에 쓸 키. 썸네일이 있으면 썸네일, 없으면 원본.
     *
     * <p>갤러리 그리드와 34px 아바타가 3MB 원본을 받아 디코딩하던 게 스크롤이 버벅이던
     * 원인이다. 512px 급이면 화면 폭(≈400dp)을 채우는 개체 상세 상단까지도 충분하다 —
     * 원본이 필요한 자리는 확대 뷰어뿐이고, 거기는 {@code s3Key} 를 그대로 쓴다.
     */
    public String displayKey() {
        return thumbS3Key != null ? thumbS3Key : s3Key;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}

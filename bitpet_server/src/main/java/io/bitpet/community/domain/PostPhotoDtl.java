package io.bitpet.community.domain;

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

@Entity
@Getter
@Table(
        name = "post_photo_dtl",
        indexes = @Index(name = "idx_post_photo_dtl_post", columnList = "post_id, display_order")
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PostPhotoDtl extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "post_id", nullable = false)
    private Long postId;

    @Column(name = "s3_key", nullable = false, length = 255)
    private String s3Key;

    @Column(name = "display_order", nullable = false)
    private int displayOrder;

    @Column
    private Integer width;

    @Column
    private Integer height;

    @Builder
    private PostPhotoDtl(Long postId, String s3Key, int displayOrder, Integer width, Integer height) {
        this.postId       = postId;
        this.s3Key        = s3Key;
        this.displayOrder = displayOrder;
        this.width        = width;
        this.height       = height;
    }
}

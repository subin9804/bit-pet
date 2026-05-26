package io.bitpet.record.memo.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(
        name = "memo_tag_cd",
        indexes = @Index(name = "idx_memo_tag_cd_active_order", columnList = "is_active, display_order")
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MemoTagCd extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 30, unique = true)
    private String code;

    @Column(name = "label_ko", nullable = false, length = 50)
    private String labelKo;

    @Column(name = "label_en", length = 50)
    private String labelEn;

    @Column(name = "color_code", length = 7)
    private String colorCode;

    @Column(name = "display_order", nullable = false)
    private int displayOrder;

    @Column(name = "is_system", nullable = false)
    private boolean isSystem;

    @Column(name = "is_active", nullable = false)
    private boolean isActive;
}

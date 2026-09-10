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

    @Column(name = "name_ko", nullable = false, length = 100)
    private String nameKo;

    @Column(name = "name_en", length = 100)
    private String nameEn;

    @Column(name = "alias_list", length = 300)
    private String aliasList;

    @Column(name = "has_health_concern", nullable = false)
    private Boolean hasHealthConcern;

    @Column(name = "display_order", nullable = false)
    private Short displayOrder;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive;

    /** 사용자가 직접 입력한 모프 여부 (false = 공식 카탈로그). V7 참고. */
    @Column(name = "is_user_defined", nullable = false)
    private Boolean isUserDefined;

    /** 커스텀 모프 생성자. 공식 카탈로그는 null. */
    @Column(name = "created_by")
    private Long createdBy;

    /**
     * 카탈로그에 없는 조합 모프를 사용자가 직접 만든 경우.
     * displayOrder 를 공식 카탈로그(최대 ~9000 미만)보다 크게 잡아 목록 맨 뒤로 보낸다.
     */
    public static MorphCd ofCustom(Long speciesId, String nameKo, Long userId) {
        MorphCd m = new MorphCd();
        m.speciesId = speciesId;
        m.nameKo = nameKo;
        m.nameEn = null;
        m.aliasList = null;
        m.hasHealthConcern = false;
        m.displayOrder = CUSTOM_DISPLAY_ORDER;
        m.isActive = true;
        m.isUserDefined = true;
        m.createdBy = userId;
        return m;
    }

    private static final short CUSTOM_DISPLAY_ORDER = 30000;
}

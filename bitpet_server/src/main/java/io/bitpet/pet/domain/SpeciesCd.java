package io.bitpet.pet.domain;

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
import org.hibernate.annotations.JdbcTypeCode;

import java.sql.Types;

@Entity
@Getter
@Table(
        name = "species_cd",
        indexes = {
                @Index(name = "idx_species_cd_category", columnList = "category, subcategory"),
                @Index(name = "idx_species_cd_display_order", columnList = "display_order")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class SpeciesCd extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50, unique = true)
    private String code;

    @JdbcTypeCode(Types.CHAR)
    @Column(nullable = false, columnDefinition = "CHAR(2)")
    private String category;

    @Column(length = 20)
    private String subcategory;

    @Column(name = "name_ko", nullable = false, length = 100)
    private String nameKo;

    @Column(name = "name_en", length = 100)
    private String nameEn;

    @Column(name = "scientific_name", length = 150)
    private String scientificName;

    @Column(name = "display_order", nullable = false)
    private int displayOrder;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    /** 종 대분류 — R=파충류 / A=양서류 / M=포유류 (V8). */
    public static final String CATEGORY_REPTILE   = "R";
    public static final String CATEGORY_AMPHIBIAN = "A";
    public static final String CATEGORY_MAMMAL    = "M";

    /**
     * 포유류인가 — 산란·해칭이 성립하지 않는 종이다(새끼를 낳는다).
     *
     * <p>⚠️ {@code category} 컬럼은 {@code character(2)} 라서 PostgreSQL 이
     * <b>공백으로 채워 돌려준다</b>({@code "M "}). 그래서 {@code "M".equals(getCategory())}
     * 는 항상 false 다 — SQL 안에서는 bpchar 비교가 꼬리 공백을 무시해 드러나지 않으므로
     * <b>Java 쪽에서만 터지는 종류의 함정</b>이다. 카테고리 판정은 반드시 이 메서드를 쓸 것.
     */
    public boolean isMammal() {
        return CATEGORY_MAMMAL.equals(normalizedCategory());
    }

    /**
     * 꼬리 공백을 떼어낸 대분류 코드.
     *
     * <p>응답 DTO 도 {@link #getCategory()} 가 아니라 이 값을 내린다 — 앱이 {@code 'M'} 과
     * 비교해 용어(산란/출산)를 고르므로 공백이 섞이면 같은 함정이 앱으로 넘어간다.
     */
    public String normalizedCategory() {
        return category != null ? category.trim() : null;
    }
}

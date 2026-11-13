package io.bitpet.inquiry.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 개발자에게 문의하기 (V3).
 *
 * <p>답장 없는 일방향 건의함이라 상태·답변 컬럼이 없다. 운영자는 DB 를 직접 본다.
 */
@Entity
@Getter
@Table(name = "inquiry_dtl")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class InquiryDtl extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private InquiryCategory category;

    @Column(nullable = false, length = 2000)
    private String content;

    @Column(name = "app_version", length = 30)
    private String appVersion;

    @Column(length = 10)
    private String platform;

    @Column(name = "os_version", length = 100)
    private String osVersion;

    @Builder
    private InquiryDtl(Long userId, InquiryCategory category, String content,
                       String appVersion, String platform, String osVersion) {
        this.userId = userId;
        this.category = category;
        this.content = content;
        this.appVersion = appVersion;
        this.platform = platform;
        this.osVersion = osVersion;
    }
}

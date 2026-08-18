package io.bitpet.auth.domain;

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
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * 약관 동의 이력 한 건.
 *
 * <p>⛔ 수정자(setter)가 없는 것은 의도다. 이 테이블은 append-only 이고,
 * 철회는 {@code agreed = false} 인 새 행으로 남긴다. 기존 행을 고치면 언제 동의했다가
 * 언제 철회했는지가 사라져 기록의 목적 자체가 없어진다.
 */
@Entity
@Table(name = "user_agreement_dtl")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserAgreementDtl extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "agreement_cd", nullable = false, length = 20)
    private AgreementType agreementType;

    @Column(name = "version", nullable = false, length = 20)
    private String version;

    @Column(name = "agreed", nullable = false)
    private boolean agreed;

    @Enumerated(EnumType.STRING)
    @Column(name = "source_cd", nullable = false, length = 20)
    private AgreementSource source;

    @Column(name = "agreed_at", nullable = false)
    private Instant agreedAt;

    private UserAgreementDtl(Long userId, AgreementType type, boolean agreed,
                             AgreementSource source, Instant agreedAt) {
        this.userId = userId;
        this.agreementType = type;
        this.version = type.currentVersion();
        this.agreed = agreed;
        this.source = source;
        this.agreedAt = agreedAt;
    }

    public static UserAgreementDtl record(Long userId, AgreementType type, boolean agreed,
                                          AgreementSource source) {
        return new UserAgreementDtl(userId, type, agreed, source, Instant.now());
    }
}

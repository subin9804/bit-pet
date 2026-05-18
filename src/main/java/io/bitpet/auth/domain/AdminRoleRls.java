package io.bitpet.auth.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Entity
@Getter
@Table(
        name = "admin_role_rls",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_admin_role_rls", columnNames = {"user_id", "role"})
        },
        indexes = {
                @Index(name = "idx_admin_role_rls_user", columnList = "user_id")
        }
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class AdminRoleRls extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false,
            foreignKey = @jakarta.persistence.ForeignKey(name = "fk_admin_role_user"))
    private UserMst user;

    @Column(nullable = false, length = 20)
    private String role;

    @Column(name = "granted_at", nullable = false)
    private Instant grantedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "granted_by",
            foreignKey = @jakarta.persistence.ForeignKey(name = "fk_admin_role_granter"))
    private UserMst grantedBy;

    @Builder
    private AdminRoleRls(UserMst user, String role, UserMst grantedBy) {
        this.user = user;
        this.role = role;
        this.grantedAt = Instant.now();
        this.grantedBy = grantedBy;
    }
}

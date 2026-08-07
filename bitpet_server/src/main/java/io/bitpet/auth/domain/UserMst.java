package io.bitpet.auth.domain;

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

@Entity
@Getter
@Table(
        name = "user_mst",
        indexes = {
                @Index(name = "idx_user_mst_email_active", columnList = "email")
        }
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserMst extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 255)
    private String email;

    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    @Column(nullable = false, length = 50)
    private String name;

    @Column(name = "profile_image_url", columnDefinition = "TEXT")
    private String profileImageUrl;

    @Enumerated(EnumType.STRING)
    @Column(name = "user_type", nullable = false, length = 20)
    private UserType userType;

    @Column(name = "last_login_at")
    private Instant lastLoginAt;

    /** 개체 공유/입분양 대상 식별 코드 (전역 유일, 지연 발급) */
    @Column(name = "share_code", length = 8)
    private String shareCode;

    /**
     * 가계도·개체 카드에 닉네임을 노출할지(V54).
     * false 면 '비공개'로 치환하고 userId 도 내리지 않는다 — 프로필로 이동할 수 없다.
     */
    @Column(name = "show_nickname_in_pedigree", nullable = false)
    private boolean showNicknameInPedigree = true;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private UserMst(String email, String passwordHash, String name,
                    String profileImageUrl, UserType userType) {
        this.email = email;
        this.passwordHash = passwordHash;
        this.name = name;
        this.profileImageUrl = profileImageUrl;
        this.userType = userType == null ? UserType.GENERAL : userType;
    }

    public static UserMst createLocal(String email, String passwordHash, String name) {
        return UserMst.builder()
                .email(email)
                .passwordHash(passwordHash)
                .name(name)
                .userType(UserType.GENERAL)
                .build();
    }

    public static UserMst createOAuth(String email, String name, String profileImageUrl, String randomPasswordHash) {
        return UserMst.builder()
                .email(email)
                .passwordHash(randomPasswordHash)
                .name(name)
                .profileImageUrl(profileImageUrl)
                .userType(UserType.GENERAL)
                .build();
    }

    public void changePassword(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public void changeName(String name) {
        this.name = name;
    }

    public void changeProfileImageUrl(String profileImageUrl) {
        this.profileImageUrl = profileImageUrl;
    }

    public void markLoggedIn() {
        this.lastLoginAt = Instant.now();
    }

    public void changeShowNicknameInPedigree(boolean show) {
        this.showNicknameInPedigree = show;
    }

    public void assignShareCode(String shareCode) {
        this.shareCode = shareCode;
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}

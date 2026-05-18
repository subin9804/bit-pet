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

    public void changeName(String name) {
        this.name = name;
    }

    public void changeProfileImageUrl(String profileImageUrl) {
        this.profileImageUrl = profileImageUrl;
    }

    public void markLoggedIn() {
        this.lastLoginAt = Instant.now();
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}

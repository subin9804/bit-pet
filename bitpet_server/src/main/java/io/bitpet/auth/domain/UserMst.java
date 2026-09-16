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

    /**
     * 프로필 아바타 색 팔레트 키 (V10). 사진이 있으면 테두리 색으로 쓰인다.
     *
     * <p>색상 코드가 아니라 <b>팔레트 키</b>를 저장한다 — 테마가 바뀌면 같은 'peach' 라도
     * 실제 색이 달라져야 한다. 모르는 값이 들어와도 앱이 기본색으로 떨어뜨리므로 CHECK 은 걸지 않는다.
     */
    @Column(name = "profile_color", nullable = false, length = 20)
    private String profileColor = DEFAULT_PROFILE_COLOR;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    public static final String DEFAULT_PROFILE_COLOR = "peach";

    @Builder
    private UserMst(String email, String passwordHash, String name,
                    String profileImageUrl, UserType userType, String profileColor) {
        this.email = email;
        this.passwordHash = passwordHash;
        this.name = name;
        this.profileImageUrl = profileImageUrl;
        this.userType = userType == null ? UserType.GENERAL : userType;
        this.profileColor = (profileColor == null || profileColor.isBlank())
                ? DEFAULT_PROFILE_COLOR : profileColor;
    }

    public static UserMst createLocal(String email, String passwordHash, String name) {
        return createLocal(email, passwordHash, name, null);
    }

    public static UserMst createLocal(String email, String passwordHash, String name, String profileColor) {
        return UserMst.builder()
                .email(email)
                .passwordHash(passwordHash)
                .name(name)
                .profileColor(profileColor)
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

    /** 빈 값은 무시한다 — 부분 수정(PATCH)에서 안 보낸 필드가 색을 지워버리면 안 된다 */
    public void changeProfileColor(String profileColor) {
        if (profileColor != null && !profileColor.isBlank()) {
            this.profileColor = profileColor;
        }
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

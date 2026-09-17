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
import java.time.LocalDate;
import java.time.Period;
import java.util.Objects;

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

    /**
     * 생년월일 (V12). 만 14세 미만 판정에만 쓴다.
     *
     * <p>⚠️ <b>NULL 은 '미상'이 아니라 '성인'이다.</b> 기존 사용자는 생년월일을 준 적이 없고
     * 가입 시 {@code AGE_14} 자기신고로 만 14세 이상임을 확인했다. NULL 을 미성년으로 보면
     * 기존 회원 전부가 하루아침에 아동 계정이 된다.
     */
    @Column(name = "birth_date")
    private LocalDate birthDate;

    /**
     * 법정대리인 user_id (V12). 자녀 계정만 값이 있다.
     *
     * <p>연관관계가 아니라 <b>id 만</b> 들고 있는다 — 이 프로젝트의 다른 사용자 참조와 같은 방식이고,
     * 보호자를 타고 자녀를, 자녀를 타고 보호자를 무한히 끌고 오는 일이 없다.
     */
    @Column(name = "guardian_user_id")
    private Long guardianUserId;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    public static final String DEFAULT_PROFILE_COLOR = "peach";

    /** 법정대리인 동의가 필요한 나이 (개인정보 보호법 제22조의2) */
    public static final int GUARDIAN_CONSENT_AGE = 14;

    @Builder
    private UserMst(String email, String passwordHash, String name,
                    String profileImageUrl, UserType userType, String profileColor,
                    LocalDate birthDate, Long guardianUserId) {
        this.email = email;
        this.passwordHash = passwordHash;
        this.name = name;
        this.profileImageUrl = profileImageUrl;
        this.userType = userType == null ? UserType.GENERAL : userType;
        this.profileColor = (profileColor == null || profileColor.isBlank())
                ? DEFAULT_PROFILE_COLOR : profileColor;
        this.birthDate = birthDate;
        this.guardianUserId = guardianUserId;
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

    /**
     * 자녀 계정 (V12). 보호자가 로그인한 상태에서 직접 만든다.
     *
     * <p>{@code guardianUserId} 없이는 만들 수 없다 — 보호자 없는 아동 계정은
     * 법정대리인 동의의 근거가 없는 계정이다.
     */
    public static UserMst createChild(String email, String passwordHash, String name,
                                      String profileColor, LocalDate birthDate,
                                      Long guardianUserId) {
        return UserMst.builder()
                .email(email)
                .passwordHash(passwordHash)
                .name(name)
                .profileColor(profileColor)
                .userType(UserType.GENERAL)
                .birthDate(birthDate)
                .guardianUserId(Objects.requireNonNull(guardianUserId, "guardianUserId"))
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

    /**
     * 만 14세 미만인가 (V12).
     *
     * <p>생년월일이 없으면 <b>false</b> — NULL 은 '성인(자기신고)'이다. 여기를 true 로 뒤집으면
     * 기존 회원 전부가 아동 계정이 되어 커뮤니티에서 쫓겨난다.
     *
     * <p>나이는 매번 계산한다. 가입 시점에 굳혀두면 생일이 지나도 아동인 채로 남는다 —
     * 만 14세가 되면 그날부터 일반 회원처럼 쓸 수 있어야 한다.
     */
    public boolean isChild() {
        return isChildAt(LocalDate.now());
    }

    /** 테스트와 시점 계산을 위해 기준일을 받는 버전 */
    public boolean isChildAt(LocalDate baseDate) {
        if (birthDate == null) return false;
        return Period.between(birthDate, baseDate).getYears() < GUARDIAN_CONSENT_AGE;
    }

    /** 이 계정이 특정 사용자의 자녀인가 */
    public boolean isChildOf(Long guardianUserId) {
        return this.guardianUserId != null && this.guardianUserId.equals(guardianUserId);
    }

    public void softDelete() {
        this.deletedAt = Instant.now();
    }
}

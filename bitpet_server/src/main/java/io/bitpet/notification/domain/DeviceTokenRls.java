package io.bitpet.notification.domain;

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

import java.time.Instant;

/**
 * FCM/APNs 디바이스 토큰 (V9 device_token_rls).
 * device_token 은 UNIQUE — 같은 기기를 다른 계정으로 로그인하면 소유자가 이전된다.
 */
@Entity
@Getter
@Table(
        name = "device_token_rls",
        indexes = @Index(name = "idx_device_token_rls_user_platform", columnList = "user_id, platform")
)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class DeviceTokenRls extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "device_token", nullable = false, length = 255)
    private String deviceToken;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private DevicePlatform platform;

    @Column(name = "device_info", length = 255)
    private String deviceInfo;

    @Column(name = "last_used_at", nullable = false)
    private Instant lastUsedAt;

    @Builder
    private DeviceTokenRls(Long userId, String deviceToken, DevicePlatform platform, String deviceInfo) {
        this.userId      = userId;
        this.deviceToken = deviceToken;
        this.platform    = platform;
        this.deviceInfo  = deviceInfo;
        this.lastUsedAt  = Instant.now();
    }

    /** 재등록(로그인·토큰 갱신) 시 소유자·메타 갱신 */
    public void refresh(Long userId, DevicePlatform platform, String deviceInfo) {
        this.userId     = userId;
        this.platform   = platform;
        this.deviceInfo = deviceInfo != null ? deviceInfo : this.deviceInfo;
        this.lastUsedAt = Instant.now();
    }
}

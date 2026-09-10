package io.bitpet.notification.service;

import io.bitpet.notification.domain.DevicePlatform;
import io.bitpet.notification.domain.DeviceTokenRls;
import io.bitpet.notification.dto.DeviceTokenRegisterRequest;
import io.bitpet.notification.repository.DeviceTokenRlsRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DeviceTokenService {

    private final DeviceTokenRlsRepository deviceTokenRepository;

    /**
     * 디바이스 토큰 등록(upsert).
     * device_token 이 UNIQUE 이므로 이미 있으면 소유자·플랫폼·last_used_at 만 갱신한다.
     * (같은 기기에서 계정을 바꿔 로그인한 경우 이전 계정의 푸시가 새 계정으로 넘어가지 않도록)
     */
    @Transactional
    public void register(Long userId, DeviceTokenRegisterRequest request) {
        DevicePlatform platform = request.platform();
        deviceTokenRepository.findByDeviceToken(request.deviceToken())
                .ifPresentOrElse(
                        token -> token.refresh(userId, platform, request.deviceInfo()),
                        () -> deviceTokenRepository.save(DeviceTokenRls.builder()
                                .userId(userId)
                                .deviceToken(request.deviceToken())
                                .platform(platform)
                                .deviceInfo(request.deviceInfo())
                                .build()));
    }

    /** 로그아웃 등으로 해당 기기 토큰 해제 */
    @Transactional
    public void unregister(String deviceToken) {
        deviceTokenRepository.deleteByDeviceToken(deviceToken);
    }

    public List<String> findTokensByUser(Long userId) {
        return deviceTokenRepository.findByUserId(userId).stream()
                .map(DeviceTokenRls::getDeviceToken)
                .toList();
    }

    /**
     * 이 유저에게 푸시가 닿을 기기가 하나라도 있는지.
     *
     * <p>"앱이 설치되어 있나"에 가장 가까운 신호다. 앱을 지우면 FCM 이 다음 발송에서
     * {@code UNREGISTERED} 를 돌려주고 {@link FcmSender} 가 그 토큰 행을 지우므로,
     * 결국 <b>토큰이 0개</b>가 된다. 마지막 로그인·마지막 활동과 달리 임계값("몇 개월이면
     * 휴면인가")을 추측할 필요가 없다.
     *
     * <p>알림 권한을 거부한 유저도 토큰은 등록된다(앱의 PushService 가 권한과 무관하게
     * 등록한다) — 즉 "권한 거부"와 "앱 삭제"는 여기서 구분된다.
     */
    public boolean hasAnyDevice(Long userId) {
        return deviceTokenRepository.existsByUserId(userId);
    }

    /** FCM이 무효(UNREGISTERED 등)로 응답한 토큰 정리 */
    @Transactional
    public void deleteInvalidTokens(Collection<String> tokens) {
        if (tokens.isEmpty()) {
            return;
        }
        deviceTokenRepository.deleteByDeviceTokenIn(tokens);
        log.info("[FCM] 무효 디바이스 토큰 {}건 삭제", tokens.size());
    }
}

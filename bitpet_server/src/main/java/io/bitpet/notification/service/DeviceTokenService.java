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

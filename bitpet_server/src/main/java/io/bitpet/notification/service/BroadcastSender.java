package io.bitpet.notification.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 전체 푸시의 실제 발송. 사람마다 알림 행 + FCM 이라 수천 명이면 몇 분이 걸린다 —
 * 요청 스레드에서 돌리면 관리 페이지가 그동안 멈추고 nginx 타임아웃에 걸린다.
 *
 * <p>{@code @Async} 가 프록시를 타야 해서 {@link BroadcastService} 와 다른 빈이다.
 * 한 사람 실패가 나머지를 멈추지 않게 사람 단위로 예외를 삼킨다 ({@code createSystemNotification} 은 REQUIRES_NEW).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class BroadcastSender {

    private final NotificationService notificationService;

    @Async
    public void send(Long broadcastId, List<Long> userIds, String title, String body) {
        int failed = 0;
        for (Long userId : userIds) {
            try {
                notificationService.createSystemNotification(userId, title, body);
            } catch (Exception e) {
                failed++;
                log.warn("broadcast {} failed for user {}: {}", broadcastId, userId, e.getMessage());
            }
        }
        log.info("broadcast {} done: targets={}, failed={}", broadcastId, userIds.size(), failed);
    }
}

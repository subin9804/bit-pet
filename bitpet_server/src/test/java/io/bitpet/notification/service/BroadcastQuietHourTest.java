package io.bitpet.notification.service;

import org.junit.jupiter.api.Test;

import java.time.ZoneId;
import java.time.ZonedDateTime;

import static org.assertj.core.api.Assertions.assertThat;

/** 광고성 푸시 야간 금지 — 21:00 부터 다음 날 07:59 까지 (정보통신망법 제50조) */
class BroadcastQuietHourTest {

    private static final ZoneId KST = ZoneId.of("Asia/Seoul");

    @Test
    void 밤_9시부터_아침_8시_전까지는_막힌다() {
        assertThat(BroadcastService.isQuietHour(at(20, 59))).isFalse();
        assertThat(BroadcastService.isQuietHour(at(21, 0))).isTrue();
        assertThat(BroadcastService.isQuietHour(at(0, 0))).isTrue();
        assertThat(BroadcastService.isQuietHour(at(7, 59))).isTrue();
        assertThat(BroadcastService.isQuietHour(at(8, 0))).isFalse();
    }

    private static ZonedDateTime at(int h, int m) {
        return ZonedDateTime.of(2026, 11, 24, h, m, 0, 0, KST);
    }
}

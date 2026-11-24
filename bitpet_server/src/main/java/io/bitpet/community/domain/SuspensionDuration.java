package io.bitpet.community.domain;

import java.time.Duration;
import java.time.Instant;

/** 정지 기간 선택지. 관리 페이지에서 이 넷 중 하나만 고른다. */
public enum SuspensionDuration {
    DAY_1(Duration.ofDays(1)),
    DAY_7(Duration.ofDays(7)),
    DAY_30(Duration.ofDays(30)),
    PERMANENT(null);

    private final Duration length;

    SuspensionDuration(Duration length) {
        this.length = length;
    }

    /** 정지 끝 시각. 영구면 null. */
    public Instant endsAtFrom(Instant start) {
        return length == null ? null : start.plus(length);
    }
}

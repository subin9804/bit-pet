package io.bitpet.record.service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;

/** 기록 시각 계산. 날짜 경계는 캘린더와 같은 한국시간 기준이다. */
public final class RecordDates {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    private RecordDates() {}

    /** {@code at} 의 한국시간 시각은 그대로 두고 날짜만 {@code date} 로 바꾼다. */
    public static Instant onDate(Instant at, LocalDate date) {
        return at.atZone(SEOUL).with(date).toInstant();
    }

    public static int yearOf(Instant at) {
        return at.atZone(SEOUL).getYear();
    }
}

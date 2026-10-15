package io.bitpet.routine;

import io.bitpet.routine.domain.IntSetCsvConverter;
import io.bitpet.routine.domain.RoutineCycleMode;
import io.bitpet.routine.domain.RoutineMst;
import io.bitpet.routine.domain.RoutineType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import java.util.SortedSet;
import java.util.TreeSet;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * 반복 방식(요일·날짜 지정). 예전엔 서버에 받을 칸이 없어 월·수·금이 '매일'로,
 * 매월 N일이 '월 1회'로 뭉개졌다.
 */
class RoutineCycleModeTest {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    private static SortedSet<Integer> set(Integer... v) {
        return new TreeSet<>(List.of(v));
    }

    private static LocalDate next(RoutineCycleMode mode, SortedSet<Integer> dow, SortedSet<Integer> dom, LocalDate from) {
        return RoutineMst.nextOccurrenceOnOrAfter(mode, dow, dom, from);
    }

    private static RoutineMst routine(LocalDate start) {
        return RoutineMst.builder()
                .userId(1L).routineType(RoutineType.FEEDING).title("사료")
                .cycleDays(1).alarmTime(LocalTime.of(9, 0)).alarmEnabled(true)
                .startDate(start).nextDueAt(start)
                .build();
    }

    private static LocalDate today() {
        return LocalDate.now(SEOUL);
    }

    // ── 순수 함수 ──────────────────────────────────────────────────────────

    @Test
    @DisplayName("요일 — 월·수·금이면 목요일 다음은 금요일, 토요일 다음은 월요일")
    void weekdayNext() {
        SortedSet<Integer> mwf = set(1, 3, 5);
        LocalDate thu = LocalDate.of(2026, 10, 15);  // 목
        assertThat(next(RoutineCycleMode.WEEKDAY, mwf, null, thu)).isEqualTo(LocalDate.of(2026, 10, 16));
        assertThat(next(RoutineCycleMode.WEEKDAY, mwf, null, LocalDate.of(2026, 10, 17)))
                .isEqualTo(LocalDate.of(2026, 10, 19));
        // 그 날 자체가 해당 요일이면 그 날
        assertThat(next(RoutineCycleMode.WEEKDAY, mwf, null, LocalDate.of(2026, 10, 14)))
                .isEqualTo(LocalDate.of(2026, 10, 14));
    }

    @Test
    @DisplayName("날짜 — 그 달에 없는 31일은 건너뛰고, 32(말일)는 그 달 마지막 날")
    void monthdayNext() {
        assertThat(next(RoutineCycleMode.MONTHDAY, null, set(31), LocalDate.of(2026, 11, 1)))
                .isEqualTo(LocalDate.of(2026, 12, 31));
        assertThat(next(RoutineCycleMode.MONTHDAY, null, set(32), LocalDate.of(2027, 2, 1)))
                .isEqualTo(LocalDate.of(2027, 2, 28));
        assertThat(next(RoutineCycleMode.MONTHDAY, null, set(1, 15), LocalDate.of(2026, 10, 16)))
                .isEqualTo(LocalDate.of(2026, 11, 1));
    }

    @Test
    @DisplayName("선택이 비어 있으면 from 그대로 — 일정이 멈추지 않는다")
    void emptySelection() {
        LocalDate d = LocalDate.of(2026, 10, 16);
        assertThat(next(RoutineCycleMode.WEEKDAY, set(), null, d)).isEqualTo(d);
        assertThat(next(RoutineCycleMode.MONTHDAY, null, set(), d)).isEqualTo(d);
        assertThat(next(RoutineCycleMode.INTERVAL, null, null, d)).isEqualTo(d);
    }

    // ── 엔티티 동작 ───────────────────────────────────────────────────────

    @Test
    @DisplayName("요일로 바꾸면 값이 그대로 남는다 (예전: cycleDays=1 → '매일')")
    void changeCycleKeepsSelection() {
        RoutineMst r = routine(today());
        r.changeCycle(RoutineCycleMode.WEEKDAY, 7, List.of(5, 1, 3), null);

        assertThat(r.getCycleMode()).isEqualTo(RoutineCycleMode.WEEKDAY);
        assertThat(r.getCycleDaysOfWeek()).containsExactly(1, 3, 5);
        assertThat(r.getCycleDaysOfMonth()).isEmpty();
        assertThat(r.getCycleDays()).isEqualTo(7);
        assertThat(set(1, 3, 5)).contains(r.getNextDueAt().getDayOfWeek().getValue());
        assertThat(r.getNextDueAt()).isAfterOrEqualTo(today());
    }

    @Test
    @DisplayName("모드를 바꾸면 안 쓰는 칸은 비운다 (DB CHECK 규칙)")
    void changeCycleClearsOtherFields() {
        RoutineMst r = routine(today());
        r.changeCycle(RoutineCycleMode.WEEKDAY, 7, List.of(1), null);
        r.changeCycle(RoutineCycleMode.MONTHDAY, 30, List.of(1), List.of(1, 32));
        assertThat(r.getCycleDaysOfWeek()).isEmpty();
        assertThat(r.getCycleDaysOfMonth()).containsExactly(1, 32);

        r.changeCycle(RoutineCycleMode.INTERVAL, 3, List.of(1), List.of(1));
        assertThat(r.getCycleDaysOfWeek()).isEmpty();
        assertThat(r.getCycleDaysOfMonth()).isEmpty();
        assertThat(r.getCycleDays()).isEqualTo(3);
    }

    @Test
    @DisplayName("같은 선택을 다시 보내면 예정일·미룸을 건드리지 않는다 (앱은 폼 전체를 매번 보낸다)")
    void unchangedCycleKeepsPostpone() {
        RoutineMst r = routine(today());
        r.changeCycle(RoutineCycleMode.WEEKDAY, 7, List.of(1, 3, 5), null);
        LocalDate postponed = today().plusDays(10);
        r.postpone(postponed, Instant.now());

        r.changeCycle(RoutineCycleMode.WEEKDAY, 7, List.of(5, 3, 1), null);

        assertThat(r.getNextDueAt()).isEqualTo(postponed);
        assertThat(r.getPostponedAt()).isNotNull();
    }

    @Test
    @DisplayName("오늘 이미 완료했으면 요일을 바꿔도 오늘을 다시 띄우지 않는다")
    void changeAfterCompletionSkipsToday() {
        RoutineMst r = routine(today().minusDays(3));
        r.markExecuted(Instant.now());
        int todayIso = today().getDayOfWeek().getValue();

        r.changeCycle(RoutineCycleMode.WEEKDAY, 7, List.of(todayIso), null);

        assertThat(r.getNextDueAt()).isEqualTo(today().plusDays(7));
    }

    @Test
    @DisplayName("시작일이 미래면 시작일 이후 첫 해당일")
    void futureStart() {
        LocalDate start = LocalDate.of(2099, 1, 1);  // 목
        RoutineMst r = routine(start);
        r.changeCycle(RoutineCycleMode.WEEKDAY, 7, List.of(1), null);
        assertThat(r.getNextDueAt()).isEqualTo(LocalDate.of(2099, 1, 5));
        assertThat(r.getStartDate()).isEqualTo(start);
    }

    @Test
    @DisplayName("완료하면 다음 해당일로, 같은 날 두 번 완료해도 같은 결과")
    void markExecutedWeekday() {
        RoutineMst r = routine(today());
        r.changeCycle(RoutineCycleMode.WEEKDAY, 7, List.of(1, 3, 5), null);
        Instant now = Instant.now();
        r.markExecuted(now);
        LocalDate first = r.getNextDueAt();
        r.markExecuted(now);

        assertThat(r.getNextDueAt()).isEqualTo(first).isAfter(today());
        assertThat(set(1, 3, 5)).contains(first.getDayOfWeek().getValue());
    }

    @Test
    @DisplayName("놓친 예정일은 오늘 이후 첫 해당일로 넘어간다")
    void advanceSkipsMissed() {
        RoutineMst r = routine(today().minusDays(30));
        r.changeCycle(RoutineCycleMode.MONTHDAY, 30, null, List.of(today().getDayOfMonth()));
        // 지난 날짜로 미뤄 둔 상태를 흉내 낸다
        r.postpone(today().minusDays(5), Instant.now());

        r.advanceDueDate();

        assertThat(r.getNextDueAt()).isEqualTo(today());
    }

    @Test
    @DisplayName("시작일 재설정 — 요일 모드면 시작일 이후 첫 해당 요일이 예정일")
    void rescheduleSnapsToWeekday() {
        RoutineMst r = routine(today());
        r.changeCycle(RoutineCycleMode.WEEKDAY, 7, List.of(1), null);
        r.reschedule(LocalDate.of(2099, 1, 1));  // 목
        assertThat(r.getStartDate()).isEqualTo(LocalDate.of(2099, 1, 1));
        assertThat(r.getNextDueAt()).isEqualTo(LocalDate.of(2099, 1, 5));
    }

    @Test
    @DisplayName("CSV 컨버터 — 정렬된 CSV, 비면 NULL")
    void converter() {
        IntSetCsvConverter c = new IntSetCsvConverter();
        assertThat(c.convertToDatabaseColumn(set(5, 1, 3))).isEqualTo("1,3,5");
        assertThat(c.convertToDatabaseColumn(set())).isNull();
        assertThat(c.convertToEntityAttribute("1,15,32")).containsExactly(1, 15, 32);
        assertThat(c.convertToEntityAttribute(null)).isEmpty();
    }
}

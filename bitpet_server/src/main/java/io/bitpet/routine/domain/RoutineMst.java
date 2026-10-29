package io.bitpet.routine.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
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
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.Collection;
import java.util.Collections;
import java.util.Objects;
import java.util.SortedSet;
import java.util.TreeSet;

@Entity
@Getter
@Table(
        name = "routine_mst",
        indexes = {
                @Index(name = "idx_routine_mst_user_active",  columnList = "user_id, is_active"),
                @Index(name = "idx_routine_mst_next_due",     columnList = "next_due_at")
        }
)
@SQLRestriction("deleted_at IS NULL")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RoutineMst extends BaseTimeEntity {

    private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

    /** 날짜 지정 모드에서 '말일'을 나타내는 값 */
    public static final int LAST_DAY_OF_MONTH = 32;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "routine_type", nullable = false, length = 20)
    private RoutineType routineType;

    @Column(nullable = false, length = 100)
    private String title;

    /** INTERVAL 모드의 간격. 요일·날짜 모드에서는 미루기 프리셋의 '한 주기' 길이(7/30)로만 쓰인다 */
    @Column(name = "cycle_days", nullable = false)
    private int cycleDays;

    @Enumerated(EnumType.STRING)
    @Column(name = "cycle_mode", nullable = false, length = 10)
    private RoutineCycleMode cycleMode = RoutineCycleMode.INTERVAL;

    /** WEEKDAY 전용 — ISO 요일 (1=월 … 7=일) */
    @Convert(converter = IntSetCsvConverter.class)
    @Column(name = "cycle_days_of_week", length = 20)
    private SortedSet<Integer> cycleDaysOfWeek = new TreeSet<>();

    /** MONTHDAY 전용 — 1~31, {@link #LAST_DAY_OF_MONTH} = 말일 */
    @Convert(converter = IntSetCsvConverter.class)
    @Column(name = "cycle_days_of_month", length = 100)
    private SortedSet<Integer> cycleDaysOfMonth = new TreeSet<>();

    @Column(name = "alarm_time", columnDefinition = "TIME")
    private LocalTime alarmTime;

    @Column(name = "is_alarm_enabled", nullable = false)
    private boolean alarmEnabled;

    /** 루틴 시작일 (고정). 완료해도 불변 — 캘린더 표시 하한 */
    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "last_executed_at")
    private LocalDate lastExecutedAt;

    @Column(name = "next_due_at")
    private LocalDate nextDueAt;

    @Column(name = "is_active", nullable = false)
    private boolean active;

    @Column(columnDefinition = "TEXT")
    private String memo;

    @Column(name = "last_notified_at")
    private Instant lastNotifiedAt;

    /** 마지막으로 미룬 시각 (없으면 미룬 적 없음) */
    @Column(name = "postponed_at")
    private Instant postponedAt;

    /** 미루기 직전의 nextDueAt — "9/16에서 미룸" 표시용 */
    @Column(name = "postponed_from")
    private LocalDate postponedFrom;

    @Column(name = "deleted_at")
    private Instant deletedAt;

    @Builder
    private RoutineMst(Long userId, RoutineType routineType, String title,
                       int cycleDays, LocalTime alarmTime, boolean alarmEnabled,
                       LocalDate startDate, LocalDate nextDueAt, String memo) {
        this.userId       = userId;
        this.routineType  = routineType;
        this.title        = title;
        this.cycleDays    = cycleDays;
        this.alarmTime    = alarmTime;
        this.alarmEnabled = alarmEnabled;
        this.startDate    = startDate;
        this.nextDueAt    = nextDueAt;
        this.active       = true;
        this.memo         = memo;
    }

    public void update(RoutineType routineType, String title, int cycleDays,
                       LocalTime alarmTime, boolean alarmEnabled,
                       Boolean active, String memo) {
        boolean alarmMoved = !Objects.equals(this.alarmTime, alarmTime);
        this.routineType  = routineType;
        this.title        = title;
        this.cycleDays    = cycleDays;
        this.alarmTime    = alarmTime;
        this.alarmEnabled = alarmEnabled;
        if (active != null) this.active = active;
        this.memo         = memo;
        if (alarmMoved) forgetTodaysNotification();
    }

    /**
     * 시작일 재설정 — 시작일과 다음 예정일을 함께 옮긴다. 수정 화면에서 "오늘부터 시작"을
     * 다시 고를 수 있게 하는 유일한 경로다.
     *
     * <p>⚠️ <b>값이 실제로 바뀔 때만 움직인다.</b> 앱은 수정 시 폼 전체를 보내므로 바뀌지 않은
     * 시작일도 매번 함께 온다. 무조건 대입하면 몇 주째 돌던 루틴의 {@code nextDueAt}이
     * 편집 한 번에 시작일로 <b>되감긴다.</b>
     *
     * <p>미룸 표시도 지운다 — 되돌릴 기준이 되는 옛 일정이 사라졌으므로, 남겨두면
     * "9/16에서 미룸"이 새 일정과 아무 관계 없는 날짜를 가리킨다.
     */
    public void reschedule(LocalDate newStartDate) {
        if (newStartDate == null || newStartDate.equals(this.startDate)) return;
        this.startDate = newStartDate;
        // 요일·날짜 모드에서는 시작일이 해당 요일이 아닐 수 있다 (목요일 시작 + 월·수·금).
        // 시작일을 그대로 예정일로 박으면 목요일에 알림이 간다.
        this.nextDueAt = firstDueOnOrAfter(newStartDate);
        clearPostponed();
        forgetTodaysNotification();
    }

    /**
     * '오늘 알림 보냈음' 표시 해제 — 바뀐 시각에 다시 울릴 수 있게 한다.
     *
     * <p>스케줄러 조회 조건이 {@code lastNotifiedAt < 오늘 0시}라서, 이 표시가 남아 있으면
     * 알람을 몇 시로 옮기든 <b>오늘은 다시 오지 않는다.</b> 루틴을 고쳤는데 알림이 안 오는
     * 증상의 원인이 이것이다.
     *
     * <p>⚠️ 새 알람 시각이 <b>이미 지났으면 지우지 않는다.</b> 지우면 저장하는 순간 알림이
     * 튀어나온다 — 18시에 알람을 9시로 바꾼 사람이 기대하는 건 '내일 9시'이지 지금 당장이 아니다.
     */
    private void forgetTodaysNotification() {
        if (shouldForgetTodaysNotification(alarmTime, LocalTime.now(SEOUL))) {
            this.lastNotifiedAt = null;
        }
    }

    /**
     * 위 판단만 떼어낸 순수 함수 — 시계를 넣을 수 있어야 양쪽 분기를 테스트할 수 있다.
     * ({@code LocalTime.now()} 를 직접 읽으면 테스트가 실행 시각에 따라 흔들린다.)
     */
    public static boolean shouldForgetTodaysNotification(LocalTime newAlarmTime, LocalTime now) {
        return newAlarmTime == null || !newAlarmTime.isBefore(now);
    }

    /** 루틴 완료 시 — lastExecutedAt 기록, nextDueAt을 다음 주기 날짜로 전진 */
    public void markExecuted(Instant at) {
        LocalDate completionDate = at.atZone(SEOUL).toLocalDate();
        this.lastExecutedAt = completionDate;
        // 요일·날짜 모드는 '완료한 다음 날부터 첫 해당일'. 같은 날 두 번 완료해도 결과가 같다.
        this.nextDueAt      = cycleMode == RoutineCycleMode.INTERVAL
                ? completionDate.plusDays(cycleDays)
                : nextOccurrenceOnOrAfter(completionDate.plusDays(1));
        clearPostponed();   // 실제로 실행했으므로 미룸 표시는 해제
    }

    /**
     * 미루기 — 다음 예정일을 사용자가 고른 날짜로 옮긴다. <b>루틴 단위</b>라 연결된 모든 개체가 함께 밀린다.
     * 그 다음 예정일은 현행대로 완료 시점(markExecuted) 또는 자정 롤오버(advanceDueDate)가 정한다.
     */
    public void postpone(LocalDate newDueDate, Instant at) {
        this.postponedFrom = this.nextDueAt;
        this.postponedAt   = at;
        this.nextDueAt     = newDueDate;
    }

    /**
     * 미루기 취소 — 직전 예정일({@code postponedFrom})로 되돌린다. <b>되돌릴 수 있는 건 마지막 미루기 1회뿐</b>이다
     * ({@link #postpone}이 매번 {@code postponedFrom}을 덮어쓰므로 그 앞 이력은 남아 있지 않다).
     *
     * <p>⚠️ 되돌릴 날짜가 이미 지났으면 <b>오늘로 당긴다.</b> 그대로 과거 날짜를 넣으면
     * {@link #advanceDueDate}(자정 롤오버·조회 시 캐치업)가 주기만큼 <b>앞으로</b> 밀어버려서,
     * 취소했는데 오히려 더 미뤄지는 정반대 결과가 된다. 되돌리기의 뜻은 "다시 내 할 일로 돌려놔라"이므로
     * 오늘 할 일로 띄우는 쪽이 맞다.
     *
     * <p>⛔ <b>미룬 날짜가 되면 되돌릴 수 없다</b> (2026-10-30 사용자 결정, {@link #isPostponeExpired}).
     * 루틴은 알림 도구라 이미 지나간 날짜로 돌려봐야 의미가 없다.
     *
     * @return 되돌릴 게 있어서 실제로 되돌렸으면 true
     */
    public boolean cancelPostpone() {
        if (postponedAt == null || postponedFrom == null) return false;
        if (isPostponeExpired()) return false;
        LocalDate today = LocalDate.now(SEOUL);
        this.nextDueAt = postponedFrom.isBefore(today) ? today : postponedFrom;
        clearPostponed();
        return true;
    }

    /** 미룬 날짜(지금 예정일)가 오늘이 됐거나 지났다 — 더는 되돌릴 수 없다. 미룬 적 없으면 false. */
    public boolean isPostponeExpired() {
        if (postponedAt == null || nextDueAt == null) return false;
        return !nextDueAt.isAfter(LocalDate.now(SEOUL));
    }

    private void clearPostponed() {
        this.postponedAt   = null;
        this.postponedFrom = null;
    }

    /** 알림 발송 기록 — nextDueAt은 변경하지 않음 */
    public void markNotified(Instant at) {
        this.lastNotifiedAt = at;
    }

    /** 연결된 '내' 개체 수 변화에 따른 활성 토글 (0개 → 비활성, 1개 이상 → 활성) */
    public void setActiveState(boolean active) {
        this.active = active;
    }

    /** soft delete — 루틴만 숨기고 실행 기록(routine_log_dtl 등)은 보존 */
    public void softDelete() {
        this.deletedAt = Instant.now();
    }

    /** 예정일이 지난 미완료 루틴 — 오늘 이상이 될 때까지 주기만큼 전진 */
    public void advanceDueDate() {
        if (nextDueAt == null) return;
        LocalDate today = LocalDate.now(SEOUL);
        if (!nextDueAt.isBefore(today)) return;
        // 미룬 날짜까지 놓치고 넘어갔다 — 미룸 표시는 옛 일정 기준이라 지운다
        clearPostponed();
        if (cycleMode != RoutineCycleMode.INTERVAL) {
            // 요일·날짜는 달력에 고정된 일정이라 놓친 날은 건너뛰고 오늘 이후 첫 해당일로 간다
            nextDueAt = nextOccurrenceOnOrAfter(today);
            return;
        }
        while (nextDueAt.isBefore(today)) {
            nextDueAt = nextDueAt.plusDays(cycleDays);
        }
    }

    // ── 반복 방식 ────────────────────────────────────────────────────────────

    /**
     * 반복 방식 변경. 요일·날짜는 해당 모드일 때만 남기고 나머지 칸은 비운다
     * (DB CHECK {@code ck_routine_mst_cycle_fields_by_mode} 와 같은 규칙).
     *
     * <p>⚠️ <b>방식이나 요일·날짜가 실제로 바뀌었을 때만</b> 다음 예정일을 다시 잡는다.
     * 앱은 수정 시 폼 전체를 보내므로 그대로인 값도 매번 온다 — 무조건 다시 잡으면
     * 미뤄 둔 일정이 편집 한 번에 풀린다. INTERVAL 로 바꿀 때는 지금 예정일을 그대로 둔다
     * (간격만 바꿀 때와 같은 동작 — 다음 완료부터 새 간격을 따른다).
     *
     * <p>새로 잡는 기준은 <b>오늘·시작일·마지막 완료 다음 날 중 가장 늦은 날</b>이다.
     * 오늘 이미 완료했는데 오늘이 새 요일에 해당한다고 다시 '오늘 할 일'로 띄우면 안 된다.
     */
    public void changeCycle(RoutineCycleMode mode, int cycleDays,
                            Collection<Integer> daysOfWeek, Collection<Integer> daysOfMonth) {
        RoutineCycleMode newMode = mode != null ? mode : RoutineCycleMode.INTERVAL;
        SortedSet<Integer> newWeek  = newMode == RoutineCycleMode.WEEKDAY  ? toSet(daysOfWeek)  : new TreeSet<>();
        SortedSet<Integer> newMonth = newMode == RoutineCycleMode.MONTHDAY ? toSet(daysOfMonth) : new TreeSet<>();

        boolean scheduleChanged = newMode != this.cycleMode
                || !newWeek.equals(nonNull(this.cycleDaysOfWeek))
                || !newMonth.equals(nonNull(this.cycleDaysOfMonth));

        this.cycleMode        = newMode;
        this.cycleDays        = cycleDays;
        this.cycleDaysOfWeek  = newWeek;
        this.cycleDaysOfMonth = newMonth;

        if (scheduleChanged && newMode != RoutineCycleMode.INTERVAL) {
            LocalDate from = LocalDate.now(SEOUL);
            if (startDate != null && startDate.isAfter(from)) from = startDate;
            if (lastExecutedAt != null && !lastExecutedAt.isBefore(from)) from = lastExecutedAt.plusDays(1);
            this.nextDueAt = nextOccurrenceOnOrAfter(from);
            clearPostponed();   // 미루기 직전 날짜는 옛 일정 기준이라 되돌릴 근거가 사라졌다
        }
    }

    /** NULL 컬럼이면 Hibernate 가 컨버터를 거치지 않고 null 을 넣을 수 있어 빈 집합으로 받는다 */
    public SortedSet<Integer> getCycleDaysOfWeek() {
        return nonNull(cycleDaysOfWeek);
    }

    public SortedSet<Integer> getCycleDaysOfMonth() {
        return nonNull(cycleDaysOfMonth);
    }

    /** 첫 예정일 — INTERVAL 은 그 날 그대로, 요일·날짜 모드는 그 날 이후 첫 해당일 */
    public LocalDate firstDueOnOrAfter(LocalDate date) {
        return cycleMode == RoutineCycleMode.INTERVAL ? date : nextOccurrenceOnOrAfter(date);
    }

    /** {@code from} 을 포함해 그 이후 첫 해당일. INTERVAL 은 {@code from} 그대로 */
    public LocalDate nextOccurrenceOnOrAfter(LocalDate from) {
        return nextOccurrenceOnOrAfter(cycleMode, cycleDaysOfWeek, cycleDaysOfMonth, from);
    }

    /**
     * 순수 함수 — 상태 없이 부를 수 있게 떼어 냈다.
     *
     * <p>날짜 모드에서 그 달에 없는 날(2월 30일 등)은 <b>건너뛴다</b>. 말일로 당겨 맞추지 않는
     * 이유: 폼에 '말일'이 따로 있어서, 31일을 고른 사람은 '31일이 있는 달'을 고른 것이다.
     * 선택이 비어 있으면(정상 경로에선 서비스가 막는다) {@code from} 을 돌려 일정이 멈추지 않게 한다.
     */
    public static LocalDate nextOccurrenceOnOrAfter(RoutineCycleMode mode,
                                                    SortedSet<Integer> daysOfWeek,
                                                    SortedSet<Integer> daysOfMonth,
                                                    LocalDate from) {
        if (mode == null || mode == RoutineCycleMode.INTERVAL) return from;
        if (mode == RoutineCycleMode.WEEKDAY) {
            if (daysOfWeek == null || daysOfWeek.isEmpty()) return from;
            for (int i = 0; i < 7; i++) {
                LocalDate d = from.plusDays(i);
                if (daysOfWeek.contains(d.getDayOfWeek().getValue())) return d;
            }
            return from;
        }
        if (daysOfMonth == null || daysOfMonth.isEmpty()) return from;
        // 31일만 골라도 두 달 안에 나온다. 넉넉히 1년.
        for (int i = 0; i < 366; i++) {
            LocalDate d = from.plusDays(i);
            boolean lastDay = d.getDayOfMonth() == d.lengthOfMonth();
            if (daysOfMonth.contains(d.getDayOfMonth())
                    || (lastDay && daysOfMonth.contains(LAST_DAY_OF_MONTH))) {
                return d;
            }
        }
        return from;
    }

    private static SortedSet<Integer> toSet(Collection<Integer> values) {
        return values == null ? new TreeSet<>() : new TreeSet<>(values);
    }

    private static SortedSet<Integer> nonNull(SortedSet<Integer> s) {
        return s == null ? Collections.emptySortedSet() : s;
    }
}

package io.bitpet.routine.domain;

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
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.Objects;

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

    @Column(name = "cycle_days", nullable = false)
    private int cycleDays;

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
        this.nextDueAt = newStartDate;
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
        this.nextDueAt      = completionDate.plusDays(cycleDays);
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
     * @return 되돌릴 게 있어서 실제로 되돌렸으면 true
     */
    public boolean cancelPostpone() {
        if (postponedAt == null || postponedFrom == null) return false;
        LocalDate today = LocalDate.now(SEOUL);
        this.nextDueAt = postponedFrom.isBefore(today) ? today : postponedFrom;
        clearPostponed();
        return true;
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
        while (nextDueAt.isBefore(today)) {
            nextDueAt = nextDueAt.plusDays(cycleDays);
        }
    }
}

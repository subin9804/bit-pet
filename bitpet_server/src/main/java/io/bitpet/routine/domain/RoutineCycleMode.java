package io.bitpet.routine.domain;

/**
 * 루틴 반복 방식.
 *
 * <ul>
 *   <li>{@code INTERVAL} — {@code cycleDays} 일마다 (완료한 날 기준으로 다음 예정일을 민다)</li>
 *   <li>{@code WEEKDAY}  — 지정한 요일마다 (ISO 1=월 … 7=일)</li>
 *   <li>{@code MONTHDAY} — 매월 지정한 날짜마다 (1~31, 32=말일)</li>
 * </ul>
 */
public enum RoutineCycleMode {
    INTERVAL, WEEKDAY, MONTHDAY
}

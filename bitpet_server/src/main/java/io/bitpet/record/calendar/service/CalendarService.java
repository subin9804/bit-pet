package io.bitpet.record.calendar.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.record.calendar.dto.CalendarDayDto;
import io.bitpet.record.calendar.dto.CalendarResponse;
import io.bitpet.record.calendar.dto.RecordCategory;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CalendarService {

    private static final Pattern YEAR_MONTH_PATTERN = Pattern.compile("^\\d{4}-\\d{2}$");

    private final JdbcTemplate jdbc;
    private final PetMstRepository petRepo;

    // ── 전체 개체 월별 캘린더 (홈 대시보드용) ─────────────────────
    public CalendarResponse getUserCalendar(Long userId, String yearMonthStr) {
        if (yearMonthStr == null || !YEAR_MONTH_PATTERN.matcher(yearMonthStr).matches()) {
            throw new BusinessException(ErrorCode.CALENDAR_MONTH_INVALID);
        }

        YearMonth yearMonth = YearMonth.parse(yearMonthStr);
        LocalDate start = yearMonth.atDay(1);
        LocalDate end   = yearMonth.atEndOfMonth();

        Map<LocalDate, Map<String, Integer>> dayMap = new LinkedHashMap<>();

        for (RecordCategory cat : List.of(
                RecordCategory.FEEDING, RecordCategory.WEIGHT,
                RecordCategory.CLEANING, RecordCategory.MEMO)) {
            if (cat == RecordCategory.MEMO) {
                jdbc.query(buildUserMemoSql(),
                        ps -> {
                            ps.setLong(1, userId);
                            ps.setObject(2, start);
                            ps.setObject(3, end);
                        },
                        rs -> {
                            LocalDate date = rs.getDate("day").toLocalDate();
                            int cnt = rs.getInt("cnt");
                            dayMap.computeIfAbsent(date, k -> new HashMap<>()).put("MEMO", cnt);
                        });
            } else {
                String sql = buildUserSql(cat);
                jdbc.query(sql,
                        ps -> {
                            ps.setLong(1, userId);
                            ps.setObject(2, start);
                            ps.setObject(3, end);
                        },
                        rs -> {
                            LocalDate date = rs.getDate("day").toLocalDate();
                            int cnt = rs.getInt("cnt");
                            dayMap.computeIfAbsent(date, k -> new HashMap<>())
                                    .put(cat.name(), cnt);
                        });
            }
        }

        // dtl 없는 루틴 완료(먹이 정보 없는 FEEDING, 메모 없는 CUSTOM)도 캘린더에 합산
        mergeRoutineOnlyCounts(dayMap, null, userId, "FEEDING", "feeding_dtl", "fed_at", "FEEDING", start, end);
        mergeRoutineOnlyCounts(dayMap, null, userId, "CUSTOM", "memo_dtl", "logged_at", "MEMO", start, end);

        List<CalendarDayDto> days = dayMap.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .map(e -> new CalendarDayDto(
                        e.getKey(),
                        new ArrayList<>(e.getValue().keySet()),
                        e.getValue()))
                .toList();

        return new CalendarResponse(null, yearMonthStr, days);
    }

    private String buildUserSql(RecordCategory cat) {
        String table, timeCol;
        switch (cat) {
            case WEIGHT   -> { table = "weight_dtl";   timeCol = "measured_at"; }
            case FEEDING  -> { table = "feeding_dtl";  timeCol = "fed_at"; }
            case CLEANING -> { table = "cleaning_dtl"; timeCol = "cleaned_at"; }
            case MEMO     -> { table = "memo_dtl";     timeCol = "logged_at"; }
            default -> throw new IllegalArgumentException("Unsupported: " + cat);
        }
        return String.format("""
                SELECT DATE(t.%s AT TIME ZONE 'UTC') AS day, COUNT(*) AS cnt
                FROM %s t
                JOIN pet_mst p ON p.id = t.pet_id
                WHERE p.user_id = ?
                  AND DATE(t.%s AT TIME ZONE 'UTC') BETWEEN ? AND ?
                  AND t.deleted_at IS NULL
                  AND p.deleted_at IS NULL
                GROUP BY day
                """, timeCol, table, timeCol);
    }

    // ── 개체별 월별 캘린더 ─────────────────────────────────────
    public CalendarResponse getCalendar(Long petId, Long userId,
                                         String yearMonthStr,
                                         List<RecordCategory> categories) {
        // 형식 검증
        if (yearMonthStr == null || !YEAR_MONTH_PATTERN.matcher(yearMonthStr).matches()) {
            throw new BusinessException(ErrorCode.CALENDAR_MONTH_INVALID);
        }

        loadOwnedPet(userId, petId);

        YearMonth yearMonth = YearMonth.parse(yearMonthStr);
        LocalDate start = yearMonth.atDay(1);
        LocalDate end   = yearMonth.atEndOfMonth();

        List<RecordCategory> targets = (categories == null || categories.isEmpty())
                ? List.of(RecordCategory.values()) : categories;

        // 날짜별 카테고리→카운트 맵
        Map<LocalDate, Map<String, Integer>> dayMap = new LinkedHashMap<>();

        for (RecordCategory cat : targets) {
            if (cat == RecordCategory.MEMO) {
                jdbc.query(buildPetMemoSql(),
                        ps -> {
                            ps.setLong(1, petId);
                            ps.setObject(2, start);
                            ps.setObject(3, end);
                        },
                        rs -> {
                            LocalDate date = rs.getDate("day").toLocalDate();
                            int cnt = rs.getInt("cnt");
                            dayMap.computeIfAbsent(date, k -> new HashMap<>()).put("MEMO", cnt);
                        });
            } else {
                String sql = buildSql(cat);
                final boolean isMating = cat == RecordCategory.MATING;
                jdbc.query(sql,
                        ps -> {
                            ps.setLong(1, petId);
                            if (isMating) {
                                ps.setLong(2, petId);
                                ps.setObject(3, start);
                                ps.setObject(4, end);
                            } else {
                                ps.setObject(2, start);
                                ps.setObject(3, end);
                            }
                        },
                        rs -> {
                            LocalDate date = rs.getDate("day").toLocalDate();
                            int cnt = rs.getInt("cnt");
                            dayMap.computeIfAbsent(date, k -> new HashMap<>())
                                    .put(cat.name(), cnt);
                        });
            }
        }

        // dtl 없는 루틴 완료(먹이 정보 없는 FEEDING, 메모 없는 CUSTOM)도 캘린더에 합산
        if (targets.contains(RecordCategory.FEEDING)) {
            mergeRoutineOnlyCounts(dayMap, petId, null, "FEEDING", "feeding_dtl", "fed_at", "FEEDING", start, end);
        }
        if (targets.contains(RecordCategory.MEMO)) {
            mergeRoutineOnlyCounts(dayMap, petId, null, "CUSTOM", "memo_dtl", "logged_at", "MEMO", start, end);
        }

        List<CalendarDayDto> days = dayMap.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .map(e -> new CalendarDayDto(
                        e.getKey(),
                        new ArrayList<>(e.getValue().keySet()),
                        e.getValue()))
                .toList();

        return new CalendarResponse(petId, yearMonthStr, days);
    }

    /**
     * dtl 기록 없이 완료만 된 루틴 로그 수를 날짜별로 dayMap에 합산.
     * petId 지정 시 개체별, userId 지정 시 유저 전체 집계.
     * dtl과 동시 저장된 로그는 NOT EXISTS로 제외해 이중 카운트를 막는다.
     */
    private void mergeRoutineOnlyCounts(Map<LocalDate, Map<String, Integer>> dayMap,
                                        Long petId, Long userId,
                                        String routineType, String dtlTable, String dtlTimeCol,
                                        String categoryKey, LocalDate start, LocalDate end) {
        StringBuilder sb = new StringBuilder();
        sb.append("SELECT DATE(l.executed_at AT TIME ZONE 'UTC') AS day, COUNT(*) AS cnt ")
          .append("FROM routine_log_dtl l ")
          .append("JOIN routine_mst r ON r.id = l.routine_id ");
        if (userId != null) {
            sb.append("JOIN pet_mst p ON p.id = l.pet_id ");
        }
        sb.append("WHERE l.status = 'COMPLETED' AND l.deleted_at IS NULL ")
          .append("AND r.routine_type = '").append(routineType).append("' ")
          .append(userId != null
                  ? "AND p.user_id = ? AND p.deleted_at IS NULL "
                  : "AND l.pet_id = ? ")
          .append("AND NOT EXISTS (SELECT 1 FROM ").append(dtlTable).append(" d ")
          .append("WHERE d.routine_id = l.routine_id AND d.pet_id = l.pet_id ")
          .append("AND d.").append(dtlTimeCol).append(" = l.executed_at AND d.deleted_at IS NULL) ")
          .append("AND DATE(l.executed_at AT TIME ZONE 'UTC') BETWEEN ? AND ? ")
          .append("GROUP BY day");

        jdbc.query(sb.toString(),
                ps -> {
                    ps.setLong(1, userId != null ? userId : petId);
                    ps.setObject(2, start);
                    ps.setObject(3, end);
                },
                rs -> {
                    LocalDate date = rs.getDate("day").toLocalDate();
                    int cnt = rs.getInt("cnt");
                    dayMap.computeIfAbsent(date, k -> new HashMap<>())
                            .merge(categoryKey, cnt, Integer::sum);
                });
    }

    private String buildSql(RecordCategory cat) {
        if (cat == RecordCategory.MATING) {
            return """
                    SELECT DATE(tried_at AT TIME ZONE 'UTC') AS day, COUNT(*) AS cnt
                    FROM mating_dtl
                    WHERE (male_pet_id = ? OR female_pet_id = ?)
                      AND DATE(tried_at AT TIME ZONE 'UTC') BETWEEN ? AND ?
                      AND deleted_at IS NULL
                    GROUP BY day
                    """;
        }
        String table;
        String timeCol;
        switch (cat) {
            case WEIGHT   -> { table = "weight_dtl";   timeCol = "measured_at"; }
            case FEEDING  -> { table = "feeding_dtl";  timeCol = "fed_at"; }
            case CLEANING -> { table = "cleaning_dtl"; timeCol = "cleaned_at"; }
            case MEMO     -> { table = "memo_dtl";     timeCol = "logged_at"; }
            case LAYING   -> { table = "laying_dtl";   timeCol = "laid_at"; }
            default -> throw new IllegalArgumentException("Unknown category: " + cat);
        }
        return String.format("""
                SELECT DATE(%s AT TIME ZONE 'UTC') AS day, COUNT(*) AS cnt
                FROM %s
                WHERE pet_id = ?
                  AND DATE(%s AT TIME ZONE 'UTC') BETWEEN ? AND ?
                  AND deleted_at IS NULL
                GROUP BY day
                """, timeCol, table, timeCol);
    }

    private String buildUserMemoSql() {
        return """
                SELECT DATE(t.logged_at AT TIME ZONE 'UTC') AS day, COUNT(*) AS cnt
                FROM memo_dtl t
                JOIN pet_mst p ON p.id = t.pet_id
                WHERE p.user_id = ?
                  AND DATE(t.logged_at AT TIME ZONE 'UTC') BETWEEN ? AND ?
                  AND t.deleted_at IS NULL AND p.deleted_at IS NULL
                GROUP BY day
                """;
    }

    private String buildPetMemoSql() {
        return """
                SELECT DATE(logged_at AT TIME ZONE 'UTC') AS day, COUNT(*) AS cnt
                FROM memo_dtl
                WHERE pet_id = ?
                  AND DATE(logged_at AT TIME ZONE 'UTC') BETWEEN ? AND ?
                  AND deleted_at IS NULL
                GROUP BY day
                """;
    }

    private PetMst loadOwnedPet(Long userId, Long petId) {
        PetMst pet = petRepo.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!pet.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
        }
        return pet;
    }
}

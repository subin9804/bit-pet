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
            String sql = buildSql(cat);
            jdbc.query(sql,
                    ps -> {
                        ps.setLong(1, petId);
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

        List<CalendarDayDto> days = dayMap.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .map(e -> new CalendarDayDto(
                        e.getKey(),
                        new ArrayList<>(e.getValue().keySet()),
                        e.getValue()))
                .toList();

        return new CalendarResponse(petId, yearMonthStr, days);
    }

    private String buildSql(RecordCategory cat) {
        String table;
        String timeCol;
        switch (cat) {
            case WEIGHT   -> { table = "weight_dtl";   timeCol = "measured_at"; }
            case FEEDING  -> { table = "feeding_dtl";  timeCol = "fed_at"; }
            case CLEANING -> { table = "cleaning_dtl"; timeCol = "cleaned_at"; }
            case MEMO     -> { table = "memo_dtl";     timeCol = "logged_at"; }
            case MATING   -> { table = "mating_dtl";   timeCol = "tried_at"; }
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

    private PetMst loadOwnedPet(Long userId, Long petId) {
        PetMst pet = petRepo.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!pet.getUserId().equals(userId)) {
            throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
        }
        return pet;
    }
}

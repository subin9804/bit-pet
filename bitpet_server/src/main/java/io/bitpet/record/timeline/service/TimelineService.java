package io.bitpet.record.timeline.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.record.calendar.dto.RecordCategory;
import io.bitpet.record.timeline.dto.RecordTimelineItem;
import io.bitpet.record.timeline.dto.TimelineResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TimelineService {

    private static final int DEFAULT_LIMIT = 20;
    private static final int MAX_LIMIT      = 100;

    private final JdbcTemplate jdbc;
    private final PetMstRepository petRepo;

    public TimelineResponse getTimeline(Long petId, Long userId,
                                         LocalDate date,
                                         LocalDate from, LocalDate to,
                                         List<RecordCategory> categories,
                                         Integer limit) {
        loadOwnedPet(userId, petId);

        int effectiveLimit = (limit == null || limit <= 0) ? DEFAULT_LIMIT
                           : Math.min(limit, MAX_LIMIT);

        List<RecordCategory> targets = (categories == null || categories.isEmpty())
                ? List.of(RecordCategory.values()) : categories;

        Instant fromInst = null;
        Instant toInst   = null;

        if (date != null) {
            fromInst = date.atStartOfDay().toInstant(ZoneOffset.UTC);
            toInst   = date.atTime(23, 59, 59).toInstant(ZoneOffset.UTC);
        } else {
            if (from != null) fromInst = from.atStartOfDay().toInstant(ZoneOffset.UTC);
            if (to   != null) toInst   = to.atTime(23, 59, 59).toInstant(ZoneOffset.UTC);
        }

        List<RecordTimelineItem> items = new ArrayList<>();

        for (RecordCategory cat : targets) {
            String sql = buildSql(cat, fromInst, toInst, effectiveLimit);
            final Instant finalFromInst = fromInst;
            final Instant finalToInst   = toInst;

            jdbc.query(sql,
                    ps -> {
                        int idx = 1;
                        ps.setLong(idx++, petId);
                        if (finalFromInst != null) ps.setTimestamp(idx++, Timestamp.from(finalFromInst));
                        if (finalToInst   != null) ps.setTimestamp(idx++, Timestamp.from(finalToInst));
                    },
                    rs -> {
                        long id = rs.getLong("id");
                        Instant loggedAt = rs.getTimestamp("logged_at").toInstant();
                        String summary = rs.getString("summary");

                        items.add(new RecordTimelineItem(
                                cat,
                                id,
                                loggedAt,
                                summary,
                                null,
                                buildDetailUrl(cat, id)
                        ));
                    });
        }

        // 전체 시간 역순 정렬 후 limit 적용
        List<RecordTimelineItem> sorted = items.stream()
                .sorted((a, b) -> b.loggedAt().compareTo(a.loggedAt()))
                .limit(effectiveLimit)
                .toList();

        return new TimelineResponse(sorted, sorted.size());
    }

    private String buildSql(RecordCategory cat, Instant from, Instant to, int limit) {
        String table, timeCol, summaryExpr;
        switch (cat) {
            case WEIGHT -> {
                table = "weight_dtl"; timeCol = "measured_at";
                summaryExpr = "CONCAT(weight_g, 'g')";
            }
            case FEEDING -> {
                table = "feeding_dtl"; timeCol = "fed_at";
                summaryExpr = "COALESCE(prey_type, '급여')";
            }
            case CLEANING -> {
                table = "cleaning_dtl"; timeCol = "cleaned_at";
                summaryExpr = "CASE cleaning_type WHEN 'FULL' THEN '전체 청소' WHEN 'PARTIAL' THEN '부분 청소' ELSE '물갈이' END";
            }
            case MEMO -> {
                table = "memo_dtl"; timeCol = "logged_at";
                summaryExpr = "SUBSTRING(content, 1, 20)";
            }
            case MATING -> {
                table = "mating_dtl"; timeCol = "tried_at";
                summaryExpr = "CONCAT('합사', CASE WHEN duration_minutes IS NOT NULL THEN CONCAT(' — ', duration_minutes, '분') ELSE '' END)";
            }
            case LAYING -> {
                table = "laying_dtl"; timeCol = "laid_at";
                summaryExpr = "CONCAT('총 ', egg_count_total, '개', CASE WHEN egg_count_fertile IS NOT NULL THEN CONCAT(' (유정 ', egg_count_fertile, ')') ELSE '' END)";
            }
            default -> throw new IllegalArgumentException("Unknown category: " + cat);
        }

        StringBuilder sb = new StringBuilder();
        sb.append("SELECT id, ").append(timeCol).append(" AS logged_at, ")
          .append(summaryExpr).append(" AS summary ")
          .append("FROM ").append(table)
          .append(" WHERE pet_id = ? AND deleted_at IS NULL");

        if (from != null) sb.append(" AND ").append(timeCol).append(" >= ?");
        if (to   != null) sb.append(" AND ").append(timeCol).append(" <= ?");

        sb.append(" ORDER BY logged_at DESC LIMIT ").append(limit);
        return sb.toString();
    }

    private String buildDetailUrl(RecordCategory cat, long id) {
        return switch (cat) {
            case WEIGHT   -> "/api/v1/weights/"  + id;
            case FEEDING  -> "/api/v1/feedings/" + id;
            case CLEANING -> "/api/v1/cleanings/"+ id;
            case MEMO     -> "/api/v1/memos/"    + id;
            case MATING   -> "/api/v1/matings/"  + id;
            case LAYING   -> "/api/v1/layings/"  + id;
        };
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

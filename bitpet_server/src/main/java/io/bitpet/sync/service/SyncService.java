package io.bitpet.sync.service;

import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.record.domain.CleaningDtl;
import io.bitpet.record.domain.CleaningType;
import io.bitpet.record.domain.FeedingDtl;
import io.bitpet.record.domain.HealthMemoDtl;
import io.bitpet.record.domain.WeightDtl;
import io.bitpet.record.domain.WeightSource;
import io.bitpet.record.repository.CleaningDtlRepository;
import io.bitpet.record.repository.FeedingDtlRepository;
import io.bitpet.record.repository.HealthMemoDtlRepository;
import io.bitpet.record.repository.WeightDtlRepository;
import io.bitpet.sync.dto.PushOperation;
import io.bitpet.sync.dto.PushResult;
import io.bitpet.sync.dto.SyncChangesResponse;
import io.bitpet.sync.dto.SyncPushRequest;
import io.bitpet.sync.dto.SyncPushResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SyncService {

    private static final Set<String> ALL_RESOURCES = Set.of(
            "pet", "weight", "feeding", "cleaning", "health_memo",
            "post", "comment", "like"
    );
    private static final int DEFAULT_LIMIT = 200;
    private static final int MAX_LIMIT = 1000;

    private final JdbcTemplate jdbc;
    private final PetMstRepository petRepo;
    private final WeightDtlRepository weightRepo;
    private final FeedingDtlRepository feedingRepo;
    private final CleaningDtlRepository cleaningRepo;
    private final HealthMemoDtlRepository healthMemoRepo;

    // -------------------------------------------------------------------------
    // Pull
    // -------------------------------------------------------------------------

    public SyncChangesResponse pull(Long userId, String clientId,
                                    String since, List<String> resources, int limit) {
        limit = Math.min(limit, MAX_LIMIT);
        SyncCursor cursor = SyncCursor.parse(since);
        Timestamp sinceTs = Timestamp.from(cursor.updatedAt());
        long sinceVersion = cursor.syncVersion();

        Set<String> requested = (resources == null || resources.isEmpty())
                ? ALL_RESOURCES : Set.copyOf(resources);

        Map<String, List<Map<String, Object>>> changes = new LinkedHashMap<>();
        long maxUpdatedMs = cursor.updatedAt().toEpochMilli();
        long maxVersion = sinceVersion;
        boolean hasMore = false;

        for (String resource : ALL_RESOURCES) {
            if (!requested.contains(resource)) continue;

            List<Map<String, Object>> rows = queryResource(resource, userId, clientId, sinceTs, sinceVersion, limit);
            if (rows.size() == limit) hasMore = true;
            if (!rows.isEmpty()) {
                changes.put(resource, rows);
                for (Map<String, Object> row : rows) {
                    Instant ua = toInstant(row.get("updated_at"));
                    long sv = toLong(row.get("sync_version"));
                    if (ua != null && ua.toEpochMilli() > maxUpdatedMs) maxUpdatedMs = ua.toEpochMilli();
                    if (sv > maxVersion) maxVersion = sv;
                }
            }
        }

        String nextCursor = new SyncCursor(Instant.ofEpochMilli(maxUpdatedMs), maxVersion).encode();
        return new SyncChangesResponse(nextCursor, hasMore, changes.isEmpty() ? null : changes);
    }

    private List<Map<String, Object>> queryResource(String resource, Long userId, String clientId,
                                                     Timestamp sinceTs, long sinceVersion, int limit) {
        String sql = buildPullSql(resource);
        return jdbc.queryForList(sql, userId, clientId, sinceTs, sinceTs, sinceVersion, limit);
    }

    private String buildPullSql(String resource) {
        String table;
        String ownerCondition;
        switch (resource) {
            case "pet" -> {
                table = "pet_mst";
                ownerCondition = "t.user_id = ?";
            }
            case "weight" -> {
                table = "weight_dtl";
                ownerCondition = "EXISTS (SELECT 1 FROM pet_mst p WHERE p.id = t.pet_id AND p.user_id = ?)";
            }
            case "feeding" -> {
                table = "feeding_dtl";
                ownerCondition = "EXISTS (SELECT 1 FROM pet_mst p WHERE p.id = t.pet_id AND p.user_id = ?)";
            }
            case "cleaning" -> {
                table = "cleaning_dtl";
                ownerCondition = "EXISTS (SELECT 1 FROM pet_mst p WHERE p.id = t.pet_id AND p.user_id = ?)";
            }
            case "health_memo" -> {
                table = "health_memo_dtl";
                ownerCondition = "EXISTS (SELECT 1 FROM pet_mst p WHERE p.id = t.pet_id AND p.user_id = ?)";
            }
            case "post" -> {
                table = "post_mst";
                ownerCondition = "t.user_id = ?";
            }
            case "comment" -> {
                table = "post_comment_dtl";
                ownerCondition = "t.user_id = ?";
            }
            case "like" -> {
                table = "post_like_rls";
                ownerCondition = "t.user_id = ?";
            }
            default -> throw new IllegalArgumentException("Unknown resource: " + resource);
        }
        // params: userId, clientId, sinceTs, sinceTs, sinceVersion, limit
        return "SELECT t.* FROM " + table + " t"
                + " WHERE " + ownerCondition
                + "   AND (t.client_id IS NULL OR t.client_id != ?)"
                + "   AND (t.updated_at > ? OR (t.updated_at = ? AND t.sync_version > ?))"
                + " ORDER BY t.updated_at ASC, t.sync_version ASC"
                + " LIMIT ?";
    }

    // -------------------------------------------------------------------------
    // Push
    // -------------------------------------------------------------------------

    @Transactional
    public SyncPushResponse push(Long userId, SyncPushRequest request) {
        String clientId = request.clientId();
        List<PushResult> results = new ArrayList<>();

        for (PushOperation op : request.operations()) {
            try {
                PushResult result = handleOperation(userId, clientId, op);
                results.add(result);
            } catch (Exception e) {
                results.add(PushResult.rejected(op.clientChangeId(), e.getMessage()));
            }
        }
        return new SyncPushResponse(results);
    }

    private PushResult handleOperation(Long userId, String clientId, PushOperation op) {
        return switch (op.resource()) {
            case "pet"          -> handlePet(userId, clientId, op);
            case "weight"       -> handleWeight(userId, clientId, op);
            case "feeding"      -> handleFeeding(userId, clientId, op);
            case "cleaning"     -> handleCleaning(userId, clientId, op);
            case "health_memo"  -> handleHealthMemo(userId, clientId, op);
            default -> PushResult.rejected(op.clientChangeId(), "unsupported_resource: " + op.resource());
        };
    }

    // -------------------------------------------------------------------------
    // Pet push handlers
    // -------------------------------------------------------------------------

    private PushResult handlePet(Long userId, String clientId, PushOperation op) {
        Map<String, Object> data = op.data();
        UUID changeId = op.clientChangeId();

        // idempotency: already processed?
        if (changeId != null) {
            var existing = petRepo.findByClientIdAndClientChangeId(clientId, changeId);
            if (existing.isPresent()) {
                PetMst p = existing.get();
                return PushResult.applied(changeId, p.getId(), p.getUpdatedAt(), p.getSyncVersion());
            }
        }

        if ("delete".equals(op.op())) {
            Long id = toLong(data.get("id"));
            PetMst pet = petRepo.findById(id)
                    .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
            if (!pet.getUserId().equals(userId)) throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
            pet.softDelete();
            petRepo.save(pet);
            return PushResult.applied(changeId, id, pet.getUpdatedAt(), pet.getSyncVersion());
        }

        // upsert — update only (pet create goes through normal API for serial number generation)
        Long id = toLong(data.get("id"));
        if (id == null) return PushResult.rejected(changeId, "pet_create_not_supported_via_sync");

        PetMst pet = petRepo.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!pet.getUserId().equals(userId)) throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);

        Instant localUpdatedAt = toInstant(data.get("localUpdatedAt"));
        if (localUpdatedAt != null && !pet.getUpdatedAt().isBefore(localUpdatedAt)) {
            return PushResult.conflict(changeId, petToMap(pet));
        }

        pet.updateProfile(
                str(data.get("name")), null, null,
                null, str(data.get("colorCode")),
                str(data.get("environmentMemo")), str(data.get("description")),
                null, null, null
        );
        if (changeId != null) pet.stampClientChange(clientId, changeId);
        petRepo.save(pet);
        return PushResult.applied(changeId, pet.getId(), pet.getUpdatedAt(), pet.getSyncVersion());
    }

    // -------------------------------------------------------------------------
    // Weight push handlers
    // -------------------------------------------------------------------------

    private PushResult handleWeight(Long userId, String clientId, PushOperation op) {
        Map<String, Object> data = op.data();
        UUID changeId = op.clientChangeId();

        if (changeId != null) {
            var existing = weightRepo.findByClientIdAndClientChangeId(clientId, changeId);
            if (existing.isPresent()) {
                WeightDtl w = existing.get();
                return PushResult.applied(changeId, w.getId(), w.getUpdatedAt(), w.getSyncVersion());
            }
        }

        if ("delete".equals(op.op())) {
            Long id = toLong(data.get("id"));
            WeightDtl w = weightRepo.findById(id)
                    .orElseThrow(() -> new BusinessException(ErrorCode.WEIGHT_NOT_FOUND));
            verifyPetOwner(w.getPetId(), userId);
            w.softDelete();
            weightRepo.save(w);
            return PushResult.applied(changeId, id, w.getUpdatedAt(), w.getSyncVersion());
        }

        Long id = toLong(data.get("id"));
        if (id == null) {
            Long petId = toLong(data.get("petId"));
            verifyPetOwner(petId, userId);
            WeightDtl w = WeightDtl.builder()
                    .petId(petId)
                    .weightG(toBigDecimal(data.get("weightG")))
                    .measuredAt(toInstant(data.get("measuredAt")))
                    .source(toEnum(data.get("source"), WeightSource.class, WeightSource.MANUAL))
                    .memo(str(data.get("memo")))
                    .build();
            if (changeId != null) w.stampClientChange(clientId, changeId);
            w = weightRepo.save(w);
            return PushResult.applied(changeId, w.getId(), w.getUpdatedAt(), w.getSyncVersion());
        }

        WeightDtl w = weightRepo.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.WEIGHT_NOT_FOUND));
        verifyPetOwner(w.getPetId(), userId);

        Instant localUpdatedAt = toInstant(data.get("localUpdatedAt"));
        if (localUpdatedAt != null && !w.getUpdatedAt().isBefore(localUpdatedAt)) {
            return PushResult.conflict(changeId, Map.of("id", w.getId(), "weightG", w.getWeightG(), "updatedAt", w.getUpdatedAt()));
        }

        w.update(toBigDecimal(data.get("weightG")), toInstant(data.get("measuredAt")),
                toEnum(data.get("source"), WeightSource.class, null), str(data.get("memo")));
        if (changeId != null) w.stampClientChange(clientId, changeId);
        weightRepo.save(w);
        return PushResult.applied(changeId, w.getId(), w.getUpdatedAt(), w.getSyncVersion());
    }

    // -------------------------------------------------------------------------
    // Feeding push handlers
    // -------------------------------------------------------------------------

    private PushResult handleFeeding(Long userId, String clientId, PushOperation op) {
        Map<String, Object> data = op.data();
        UUID changeId = op.clientChangeId();

        if (changeId != null) {
            var existing = feedingRepo.findByClientIdAndClientChangeId(clientId, changeId);
            if (existing.isPresent()) {
                FeedingDtl f = existing.get();
                return PushResult.applied(changeId, f.getId(), f.getUpdatedAt(), f.getSyncVersion());
            }
        }

        if ("delete".equals(op.op())) {
            Long id = toLong(data.get("id"));
            FeedingDtl f = feedingRepo.findById(id)
                    .orElseThrow(() -> new BusinessException(ErrorCode.FEEDING_NOT_FOUND));
            verifyPetOwner(f.getPetId(), userId);
            f.softDelete();
            feedingRepo.save(f);
            return PushResult.applied(changeId, id, f.getUpdatedAt(), f.getSyncVersion());
        }

        Long id = toLong(data.get("id"));
        if (id == null) {
            Long petId = toLong(data.get("petId"));
            verifyPetOwner(petId, userId);
            FeedingDtl f = FeedingDtl.builder()
                    .petId(petId)
                    .foodType(str(data.get("foodType")))
                    .amount(toBigDecimal(data.get("amount")))
                    .unit(str(data.get("unit")))
                    .fedAt(toInstant(data.get("fedAt")))
                    .memo(str(data.get("memo")))
                    .build();
            if (changeId != null) f.stampClientChange(clientId, changeId);
            f = feedingRepo.save(f);
            return PushResult.applied(changeId, f.getId(), f.getUpdatedAt(), f.getSyncVersion());
        }

        FeedingDtl f = feedingRepo.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.FEEDING_NOT_FOUND));
        verifyPetOwner(f.getPetId(), userId);

        Instant localUpdatedAt = toInstant(data.get("localUpdatedAt"));
        if (localUpdatedAt != null && !f.getUpdatedAt().isBefore(localUpdatedAt)) {
            return PushResult.conflict(changeId, Map.of("id", f.getId(), "updatedAt", f.getUpdatedAt()));
        }

        f.update(str(data.get("foodType")), toBigDecimal(data.get("amount")),
                str(data.get("unit")), toInstant(data.get("fedAt")), str(data.get("memo")));
        if (changeId != null) f.stampClientChange(clientId, changeId);
        feedingRepo.save(f);
        return PushResult.applied(changeId, f.getId(), f.getUpdatedAt(), f.getSyncVersion());
    }

    // -------------------------------------------------------------------------
    // Cleaning push handlers
    // -------------------------------------------------------------------------

    private PushResult handleCleaning(Long userId, String clientId, PushOperation op) {
        Map<String, Object> data = op.data();
        UUID changeId = op.clientChangeId();

        if (changeId != null) {
            var existing = cleaningRepo.findByClientIdAndClientChangeId(clientId, changeId);
            if (existing.isPresent()) {
                CleaningDtl c = existing.get();
                return PushResult.applied(changeId, c.getId(), c.getUpdatedAt(), c.getSyncVersion());
            }
        }

        if ("delete".equals(op.op())) {
            Long id = toLong(data.get("id"));
            CleaningDtl c = cleaningRepo.findById(id)
                    .orElseThrow(() -> new BusinessException(ErrorCode.CLEANING_NOT_FOUND));
            verifyPetOwner(c.getPetId(), userId);
            c.softDelete();
            cleaningRepo.save(c);
            return PushResult.applied(changeId, id, c.getUpdatedAt(), c.getSyncVersion());
        }

        Long id = toLong(data.get("id"));
        if (id == null) {
            Long petId = toLong(data.get("petId"));
            verifyPetOwner(petId, userId);
            CleaningDtl c = CleaningDtl.builder()
                    .petId(petId)
                    .cleaningType(toEnum(data.get("cleaningType"), CleaningType.class, CleaningType.FULL))
                    .cleanedAt(toInstant(data.get("cleanedAt")))
                    .memo(str(data.get("memo")))
                    .build();
            if (changeId != null) c.stampClientChange(clientId, changeId);
            c = cleaningRepo.save(c);
            return PushResult.applied(changeId, c.getId(), c.getUpdatedAt(), c.getSyncVersion());
        }

        CleaningDtl c = cleaningRepo.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.CLEANING_NOT_FOUND));
        verifyPetOwner(c.getPetId(), userId);

        Instant localUpdatedAt = toInstant(data.get("localUpdatedAt"));
        if (localUpdatedAt != null && !c.getUpdatedAt().isBefore(localUpdatedAt)) {
            return PushResult.conflict(changeId, Map.of("id", c.getId(), "updatedAt", c.getUpdatedAt()));
        }

        c.update(toEnum(data.get("cleaningType"), CleaningType.class, null),
                toInstant(data.get("cleanedAt")), str(data.get("memo")));
        if (changeId != null) c.stampClientChange(clientId, changeId);
        cleaningRepo.save(c);
        return PushResult.applied(changeId, c.getId(), c.getUpdatedAt(), c.getSyncVersion());
    }

    // -------------------------------------------------------------------------
    // HealthMemo push handlers
    // -------------------------------------------------------------------------

    private PushResult handleHealthMemo(Long userId, String clientId, PushOperation op) {
        Map<String, Object> data = op.data();
        UUID changeId = op.clientChangeId();

        if (changeId != null) {
            var existing = healthMemoRepo.findByClientIdAndClientChangeId(clientId, changeId);
            if (existing.isPresent()) {
                HealthMemoDtl h = existing.get();
                return PushResult.applied(changeId, h.getId(), h.getUpdatedAt(), h.getSyncVersion());
            }
        }

        if ("delete".equals(op.op())) {
            Long id = toLong(data.get("id"));
            HealthMemoDtl h = healthMemoRepo.findById(id)
                    .orElseThrow(() -> new BusinessException(ErrorCode.HEALTH_LOG_NOT_FOUND));
            verifyPetOwner(h.getPetId(), userId);
            h.softDelete();
            healthMemoRepo.save(h);
            return PushResult.applied(changeId, id, h.getUpdatedAt(), h.getSyncVersion());
        }

        Long id = toLong(data.get("id"));
        if (id == null) {
            Long petId = toLong(data.get("petId"));
            verifyPetOwner(petId, userId);
            HealthMemoDtl h = HealthMemoDtl.builder()
                    .petId(petId)
                    .symptom(str(data.get("symptom")))
                    .treatment(str(data.get("treatment")))
                    .memo(str(data.get("memo")))
                    .recordedAt(toInstant(data.get("recordedAt")))
                    .build();
            if (changeId != null) h.stampClientChange(clientId, changeId);
            h = healthMemoRepo.save(h);
            return PushResult.applied(changeId, h.getId(), h.getUpdatedAt(), h.getSyncVersion());
        }

        HealthMemoDtl h = healthMemoRepo.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.HEALTH_LOG_NOT_FOUND));
        verifyPetOwner(h.getPetId(), userId);

        Instant localUpdatedAt = toInstant(data.get("localUpdatedAt"));
        if (localUpdatedAt != null && !h.getUpdatedAt().isBefore(localUpdatedAt)) {
            return PushResult.conflict(changeId, Map.of("id", h.getId(), "updatedAt", h.getUpdatedAt()));
        }

        h.update(str(data.get("symptom")), str(data.get("treatment")),
                str(data.get("memo")), toInstant(data.get("recordedAt")));
        if (changeId != null) h.stampClientChange(clientId, changeId);
        healthMemoRepo.save(h);
        return PushResult.applied(changeId, h.getId(), h.getUpdatedAt(), h.getSyncVersion());
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private void verifyPetOwner(Long petId, Long userId) {
        PetMst pet = petRepo.findById(petId)
                .orElseThrow(() -> new BusinessException(ErrorCode.PET_NOT_FOUND));
        if (!pet.getUserId().equals(userId)) throw new BusinessException(ErrorCode.PET_ACCESS_DENIED);
    }

    private Map<String, Object> petToMap(PetMst pet) {
        Map<String, Object> m = new HashMap<>();
        m.put("id", pet.getId());
        m.put("name", pet.getName());
        m.put("updatedAt", pet.getUpdatedAt());
        m.put("syncVersion", pet.getSyncVersion());
        return m;
    }

    private static String str(Object v) { return v == null ? null : v.toString(); }

    private static Long toLong(Object v) {
        if (v == null) return null;
        if (v instanceof Number n) return n.longValue();
        try { return Long.parseLong(v.toString()); } catch (Exception e) { return null; }
    }

    private static BigDecimal toBigDecimal(Object v) {
        if (v == null) return null;
        if (v instanceof BigDecimal bd) return bd;
        if (v instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        try { return new BigDecimal(v.toString()); } catch (Exception e) { return null; }
    }

    private static Instant toInstant(Object v) {
        if (v == null) return null;
        if (v instanceof Instant i) return i;
        if (v instanceof java.sql.Timestamp ts) return ts.toInstant();
        if (v instanceof java.util.Date d) return d.toInstant();
        try { return Instant.parse(v.toString()); } catch (Exception e) { return null; }
    }

    @SuppressWarnings("unchecked")
    private static <E extends Enum<E>> E toEnum(Object v, Class<E> cls, E def) {
        if (v == null) return def;
        try { return Enum.valueOf(cls, v.toString()); } catch (Exception e) { return def; }
    }

    // -------------------------------------------------------------------------
    // Cursor
    // -------------------------------------------------------------------------

    record SyncCursor(Instant updatedAt, long syncVersion) {
        static SyncCursor parse(String s) {
            if (s == null || s.isBlank() || "0".equals(s)) {
                return new SyncCursor(Instant.EPOCH, 0L);
            }
            try {
                int sep = s.lastIndexOf('_');
                long ms = Long.parseLong(s.substring(0, sep));
                long sv = Long.parseLong(s.substring(sep + 1));
                return new SyncCursor(Instant.ofEpochMilli(ms), sv);
            } catch (Exception e) {
                return new SyncCursor(Instant.EPOCH, 0L);
            }
        }

        String encode() {
            return updatedAt.toEpochMilli() + "_" + syncVersion;
        }
    }
}

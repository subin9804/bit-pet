package io.bitpet.sync.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record PushResult(
        UUID clientChangeId,
        String status,
        Long serverId,
        Instant serverUpdatedAt,
        Long syncVersion,
        String reason,
        Map<String, Object> serverState
) {
    public static PushResult applied(UUID changeId, Long id, Instant updatedAt, long version) {
        return new PushResult(changeId, "APPLIED", id, updatedAt, version, null, null);
    }

    public static PushResult conflict(UUID changeId, Map<String, Object> state) {
        return new PushResult(changeId, "CONFLICT", null, null, null, "stale_update", state);
    }

    public static PushResult rejected(UUID changeId, String reason) {
        return new PushResult(changeId, "REJECTED", null, null, null, reason, null);
    }
}

package io.bitpet.record.memo.dto;

import jakarta.validation.constraints.NotNull;

import java.time.OffsetDateTime;
import java.util.List;

public record MemoUpdateRequest(
        // 빈 내용을 허용한다 — 메모 없이 완료한 루틴 기록의 **날짜만** 고치는 경우가 있고,
        // 기록은 전부 수정 가능해야 한다. 새로 만들 때(Create)는 여전히 내용이 필요하다.
        @NotNull String content,
        @NotNull OffsetDateTime loggedAt,
        List<String> tags,
        VetExtRequest vetExt
) {}

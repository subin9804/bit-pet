package io.bitpet.record.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;
import java.util.List;

/**
 * 홈 캘린더 날짜 시트의 일괄 작업 요청.
 *
 * <p>{@code recordType} 은 날짜별 조회({@link RecentRecordResponse})가 내리는 값 그대로다 —
 * FEEDING · WEIGHT · CLEANING · MEMO · MATING · LAYING.
 */
public final class RecordBulkRequest {

    private RecordBulkRequest() {}

    public record Item(@NotBlank String recordType, @NotNull Long id) {}

    public record Delete(@NotEmpty @Size(max = 200) List<@Valid Item> items) {}

    /** {@code date} 로 옮긴다. 시각은 그대로 둔다. */
    public record Move(@NotEmpty @Size(max = 200) List<@Valid Item> items,
                       @NotNull LocalDate date) {}
}

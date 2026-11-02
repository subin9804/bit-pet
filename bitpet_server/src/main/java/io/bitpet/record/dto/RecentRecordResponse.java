package io.bitpet.record.dto;

import java.time.Instant;
import java.util.List;

/**
 * @param tags 메모 분류 코드(`memo_tag_cd.code` — VET/SHED/POOP/…). 메모가 아니거나 분류가
 *             없으면 빈 목록. 홈 하루 목록이 병원·탈피 같은 분류를 바로 보여 주려고 싣는다.
 */
public record RecentRecordResponse(
        String recordType,
        Long id,
        Long petId,
        String petName,
        String colorCode,
        Instant createdAt,
        String summary,
        String memo,
        List<String> tags
) {
    public static RecentRecordResponse of(String recordType, Long id, Long petId,
                                          String petName, String colorCode,
                                          Instant createdAt, String summary, String memo) {
        return of(recordType, id, petId, petName, colorCode, createdAt, summary, memo, List.of());
    }

    public static RecentRecordResponse of(String recordType, Long id, Long petId,
                                          String petName, String colorCode,
                                          Instant createdAt, String summary, String memo,
                                          List<String> tags) {
        return new RecentRecordResponse(recordType, id, petId, petName, colorCode,
                createdAt, summary, memo, tags);
    }
}

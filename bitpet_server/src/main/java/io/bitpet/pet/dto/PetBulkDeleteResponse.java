package io.bitpet.pet.dto;

import java.util.List;

/**
 * 개체 일괄 삭제 결과.
 *
 * <p>일괄 삭제는 <b>전부 성공 아니면 전부 실패</b>다 (벌크 공유 초대와 동일한 규약).
 * 따라서 실패 목록은 없고, 실제로 지워진 id만 돌려준다 —
 * 요청에 중복이 있었다면 {@code deletedCount} 는 요청 개수보다 작을 수 있다.
 */
public record PetBulkDeleteResponse(
        int deletedCount,
        List<Long> deletedIds
) {
    public static PetBulkDeleteResponse of(List<Long> ids) {
        return new PetBulkDeleteResponse(ids.size(), ids);
    }
}

package io.bitpet.record.memo.dto;

import io.bitpet.record.memo.domain.MemoDtl;
import io.bitpet.record.memo.domain.MemoTagCd;
import io.bitpet.record.memo.domain.MemoVetExtDtl;

import java.time.Instant;
import java.util.List;

public record MemoResponse(
        Long memoId,
        Long petId,
        String content,
        Instant loggedAt,
        List<String> tags,
        VetExtResponse vetExt,
        String routineTitle, // 루틴 완료로 생성된 메모면 해당 루틴 제목 (수동 메모는 null)
        boolean editable,    // false면 루틴 완료 합성 항목 → 실제 memo_dtl 없음, 수정/삭제 불가
        Instant createdAt,
        Instant updatedAt
) {
    public static MemoResponse of(MemoDtl memo, List<MemoTagCd> tags, MemoVetExtDtl vetExt) {
        return of(memo, tags, vetExt, null);
    }

    public static MemoResponse of(MemoDtl memo, List<MemoTagCd> tags, MemoVetExtDtl vetExt,
                                  String routineTitle) {
        return new MemoResponse(
                memo.getId(),
                memo.getPetId(),
                memo.getContent(),
                memo.getLoggedAt(),
                tags.stream().map(MemoTagCd::getCode).toList(),
                VetExtResponse.from(vetExt),
                routineTitle,
                true, // 실제 memo_dtl 기반 → 수정/삭제 가능
                memo.getCreatedAt(),
                memo.getUpdatedAt()
        );
    }
}

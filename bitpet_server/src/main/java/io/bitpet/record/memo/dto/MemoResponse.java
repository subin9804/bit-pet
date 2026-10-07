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
        String routineTitle, // 메모를 만든 계기가 루틴이면 그 제목. **표시에는 쓰지 않는다**
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
                memo.getCreatedAt(),
                memo.getUpdatedAt()
        );
    }
}

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
        Instant createdAt,
        Instant updatedAt
) {
    public static MemoResponse of(MemoDtl memo, List<MemoTagCd> tags, MemoVetExtDtl vetExt) {
        return new MemoResponse(
                memo.getId(),
                memo.getPetId(),
                memo.getContent(),
                memo.getLoggedAt(),
                tags.stream().map(MemoTagCd::getCode).toList(),
                VetExtResponse.from(vetExt),
                memo.getCreatedAt(),
                memo.getUpdatedAt()
        );
    }
}

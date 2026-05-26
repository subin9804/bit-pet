package io.bitpet.record.memo.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(
        name = "memo_tag_rls",
        indexes = @Index(name = "idx_memo_tag_rls_tag", columnList = "tag_id, memo_id")
)
@IdClass(MemoTagRlsId.class)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class MemoTagRls {

    @Id
    @Column(name = "memo_id", nullable = false)
    private Long memoId;

    @Id
    @Column(name = "tag_id", nullable = false)
    private Long tagId;

    @Builder
    private MemoTagRls(Long memoId, Long tagId) {
        this.memoId = memoId;
        this.tagId = tagId;
    }
}

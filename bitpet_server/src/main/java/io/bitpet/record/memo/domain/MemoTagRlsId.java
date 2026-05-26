package io.bitpet.record.memo.domain;

import java.io.Serializable;
import java.util.Objects;

public class MemoTagRlsId implements Serializable {

    private Long memoId;
    private Long tagId;

    public MemoTagRlsId() {}

    public MemoTagRlsId(Long memoId, Long tagId) {
        this.memoId = memoId;
        this.tagId = tagId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof MemoTagRlsId that)) return false;
        return Objects.equals(memoId, that.memoId) && Objects.equals(tagId, that.tagId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(memoId, tagId);
    }
}

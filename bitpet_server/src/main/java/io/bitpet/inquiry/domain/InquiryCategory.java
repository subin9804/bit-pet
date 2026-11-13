package io.bitpet.inquiry.domain;

/** 문의 종류. DB CHECK {@code ck_inquiry_dtl_category} 와 같은 집합이어야 한다. */
public enum InquiryCategory {
    BUG,
    SUGGESTION,
    ACCOUNT,
    ETC
}

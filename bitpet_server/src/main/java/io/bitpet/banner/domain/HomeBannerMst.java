package io.bitpet.banner.domain;

import io.bitpet.common.entity.BaseTimeEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;

/** 홈 상단 배너 (V4). 등록·수정은 웹 관리 페이지에서만 한다. */
@Entity
@Getter
@Table(name = "home_banner_mst")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class HomeBannerMst extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 40)
    private String title;

    @Column(length = 60)
    private String body;

    @Column(length = 10)
    private String badge;

    @Column(name = "image_key", length = 300)
    private String imageKey;

    @Enumerated(EnumType.STRING)
    @Column(name = "link_type", nullable = false, length = 10)
    private BannerLinkType linkType;

    @Column(name = "link_value", length = 500)
    private String linkValue;

    @Column(name = "start_at")
    private Instant startAt;

    @Column(name = "end_at")
    private Instant endAt;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @Column(name = "active_yn", nullable = false, length = 1)
    private String activeYn;

    public static HomeBannerMst create() {
        return new HomeBannerMst();
    }

    /** 폼 전체를 덮어쓴다 — 관리 페이지는 항상 모든 칸을 보낸다. 검증은 서비스가 끝낸 뒤다. */
    public void apply(String title, String body, String badge, String imageKey,
                      BannerLinkType linkType, String linkValue,
                      Instant startAt, Instant endAt, int sortOrder, boolean active) {
        this.title = title;
        this.body = body;
        this.badge = badge;
        this.imageKey = imageKey;
        this.linkType = linkType;
        this.linkValue = linkValue;
        this.startAt = startAt;
        this.endAt = endAt;
        this.sortOrder = sortOrder;
        this.activeYn = active ? "Y" : "N";
    }

    public boolean isActive() {
        return "Y".equals(activeYn);
    }

    /** 지금 앱에 보이는가 — 켜져 있고 기간 안. */
    public boolean isLiveAt(Instant now) {
        return isActive()
                && (startAt == null || !now.isBefore(startAt))
                && (endAt == null || now.isBefore(endAt));
    }
}

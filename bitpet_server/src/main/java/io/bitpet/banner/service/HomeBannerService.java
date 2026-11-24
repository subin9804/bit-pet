package io.bitpet.banner.service;

import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.banner.domain.BannerLinkType;
import io.bitpet.banner.domain.HomeBannerMst;
import io.bitpet.banner.dto.BannerImageResponse;
import io.bitpet.banner.dto.HomeBannerAdminResponse;
import io.bitpet.banner.dto.HomeBannerRequest;
import io.bitpet.banner.dto.HomeBannerResponse;
import io.bitpet.banner.repository.HomeBannerMstRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.storage.S3Service;
import io.bitpet.storage.service.S3DeleteQueueService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

/**
 * 홈 상단 배너.
 *
 * <p>앱은 지금 노출 중인 것만 받는다({@link #listLive}). 관리 페이지는 전부 받는다.
 * 어드민 판정은 컨트롤러가 {@code AdminGuard} 로 한다.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class HomeBannerService {

    /** 배너 이미지는 가로로 긴 한 장이라 5MB 면 충분하다 (nginx 상한 20MB 보다 작게) */
    private static final long MAX_IMAGE_BYTES = 5L * 1024 * 1024;
    private static final Map<String, String> IMAGE_EXT = Map.of(
            "image/png", "png", "image/jpeg", "jpg", "image/webp", "webp", "image/gif", "gif");

    private final HomeBannerMstRepository bannerRepository;
    private final UserMstRepository userRepository;
    private final S3Service s3Service;
    private final S3DeleteQueueService s3DeleteQueue;

    /** 앱 홈 — 켜져 있고 기간 안인 배너. 자녀 계정에는 외부 링크 배너를 뺀다. */
    public List<HomeBannerResponse> listLive(Long userId) {
        boolean child = userRepository.findById(userId).map(u -> u.isChild()).orElse(false);
        Instant now = Instant.now();
        return bannerRepository.findAllByOrderBySortOrderAscIdAsc().stream()
                .filter(b -> b.isLiveAt(now))
                .filter(b -> !(child && b.getLinkType() == BannerLinkType.URL))
                .map(b -> new HomeBannerResponse(b.getId(), b.getTitle(), b.getBody(), b.getBadge(),
                        s3Service.resolveUrl(b.getImageKey()), b.getLinkType(), b.getLinkValue()))
                .toList();
    }

    public List<HomeBannerAdminResponse> listAll() {
        Instant now = Instant.now();
        return bannerRepository.findAllByOrderBySortOrderAscIdAsc().stream()
                .map(b -> toAdmin(b, now))
                .toList();
    }

    @Transactional
    public HomeBannerAdminResponse create(HomeBannerRequest req) {
        HomeBannerMst banner = HomeBannerMst.create();
        apply(banner, req);
        return toAdmin(bannerRepository.save(banner), Instant.now());
    }

    @Transactional
    public HomeBannerAdminResponse update(Long id, HomeBannerRequest req) {
        HomeBannerMst banner = find(id);
        String oldKey = banner.getImageKey();
        apply(banner, req);
        // 이미지를 갈았으면 옛 파일은 지운다 (커밋 후 삭제 큐)
        if (oldKey != null && !oldKey.equals(banner.getImageKey())) {
            s3DeleteQueue.enqueue(List.of(oldKey));
        }
        return toAdmin(banner, Instant.now());
    }

    @Transactional
    public void delete(Long id) {
        HomeBannerMst banner = find(id);
        if (banner.getImageKey() != null) s3DeleteQueue.enqueue(List.of(banner.getImageKey()));
        bannerRepository.delete(banner);
    }

    /**
     * 이미지 업로드 — 아직 어느 배너에도 붙지 않은 파일이다. 폼에서 저장하지 않고 나가면
     * S3 에 고아로 남지만, 관리자 한 명이 가끔 쓰는 화면이라 정리 배치를 따로 두지 않는다.
     */
    public BannerImageResponse uploadImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException(ErrorCode.INVALID_INPUT, "이미지 파일을 골라 주세요");
        }
        String ext = IMAGE_EXT.get(Objects.requireNonNullElse(file.getContentType(), ""));
        if (ext == null) {
            throw new BusinessException(ErrorCode.INVALID_INPUT, "PNG·JPG·WEBP·GIF 이미지만 올릴 수 있어요");
        }
        if (file.getSize() > MAX_IMAGE_BYTES) {
            throw new BusinessException(ErrorCode.INVALID_INPUT, "이미지는 5MB 까지 올릴 수 있어요");
        }
        String key = "banners/" + UUID.randomUUID() + "." + ext;
        try {
            s3Service.putObject(key, file.getBytes(), file.getContentType());
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
        return new BannerImageResponse(key, s3Service.resolveUrl(key));
    }

    private HomeBannerMst find(Long id) {
        return bannerRepository.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.NOT_FOUND));
    }

    /** 링크·기간 검증 후 반영. DB CHECK 와 같은 규칙을 먼저 걸러 400 으로 돌려준다. */
    private void apply(HomeBannerMst banner, HomeBannerRequest req) {
        String linkValue = blankToNull(req.linkValue());
        switch (req.linkType()) {
            case NONE -> linkValue = null;
            case ROUTE -> {
                if (linkValue == null || !linkValue.startsWith("/")) {
                    throw new BusinessException(ErrorCode.INVALID_INPUT, "앱 경로는 / 로 시작해야 해요 (예: /community)");
                }
            }
            case URL -> {
                if (linkValue == null || !linkValue.startsWith("https://")) {
                    throw new BusinessException(ErrorCode.INVALID_INPUT, "외부 링크는 https:// 로 시작해야 해요");
                }
            }
        }
        if (req.startAt() != null && req.endAt() != null && !req.startAt().isBefore(req.endAt())) {
            throw new BusinessException(ErrorCode.INVALID_INPUT, "노출 끝이 시작보다 뒤여야 해요");
        }
        String imageKey = blankToNull(req.imageKey());
        if (imageKey != null && !imageKey.startsWith("banners/")) {
            // 다른 개체 사진 키를 끌어다 쓰지 못하게 — 배너 삭제 때 그 사진까지 지워진다
            throw new BusinessException(ErrorCode.INVALID_INPUT, "배너 이미지는 이 페이지에서 올린 것만 쓸 수 있어요");
        }
        banner.apply(req.title().trim(), blankToNull(req.body()), blankToNull(req.badge()), imageKey,
                req.linkType(), linkValue, req.startAt(), req.endAt(), req.sortOrder(), req.active());
    }

    private HomeBannerAdminResponse toAdmin(HomeBannerMst b, Instant now) {
        return new HomeBannerAdminResponse(b.getId(), b.getTitle(), b.getBody(), b.getBadge(),
                b.getImageKey(), s3Service.resolveUrl(b.getImageKey()), b.getLinkType(), b.getLinkValue(),
                b.getStartAt(), b.getEndAt(), b.getSortOrder(), b.isActive(), b.isLiveAt(now));
    }

    private static String blankToNull(String s) {
        return s == null || s.isBlank() ? null : s.trim();
    }
}

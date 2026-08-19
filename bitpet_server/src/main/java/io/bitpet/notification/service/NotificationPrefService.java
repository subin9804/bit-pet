package io.bitpet.notification.service;

import io.bitpet.auth.domain.AgreementType;
import io.bitpet.auth.service.AgreementService;
import io.bitpet.notification.domain.NotificationType;
import io.bitpet.notification.domain.UserNotificationPref;
import io.bitpet.notification.dto.NotificationPrefResponse;
import io.bitpet.notification.dto.NotificationPrefUpdateRequest;
import io.bitpet.notification.repository.UserNotificationPrefRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 알림 종류별 수신 설정.
 *
 * <p>마케팅만 저장 위치가 다르다. 화면에서는 같은 목록의 토글 하나지만, 마케팅 수신은
 * 사용자 취향이 아니라 <b>법이 요구하는 동의</b>라서 {@link AgreementService}의 이력에
 * 남겨야 한다. 여기서 boolean 하나를 더 들고 있으면 동의 기록과 어긋나는 날이 온다.
 */
@Service
@RequiredArgsConstructor
public class NotificationPrefService {

    private final UserNotificationPrefRepository prefRepository;
    private final AgreementService agreementService;

    @Transactional(readOnly = true)
    public NotificationPrefResponse getPref(Long userId) {
        return NotificationPrefResponse.of(
                prefRepository.findById(userId).orElseGet(() -> UserNotificationPref.defaultsFor(userId)),
                agreementService.canSendMarketing(userId));
    }

    @Transactional
    public NotificationPrefResponse updatePref(Long userId, NotificationPrefUpdateRequest req) {
        // 처음 끄는 순간에 행이 생긴다. 기본값(전부 켜짐)과 행 없음이 같은 상태라
        // 기존 유저를 백필할 필요가 없다.
        UserNotificationPref pref = prefRepository.findById(userId)
                .orElseGet(() -> prefRepository.save(UserNotificationPref.defaultsFor(userId)));
        pref.update(req.routine(), req.comment(), req.postLike());

        if (req.marketing() != null) {
            agreementService.changeOptionalAgreement(
                    userId, AgreementType.MARKETING, req.marketing());
        }
        return NotificationPrefResponse.of(pref, agreementService.canSendMarketing(userId));
    }

    /**
     * 이 유저에게 이 종류의 푸시를 보내도 되는지. 알림을 보낼 때마다 도는 조회다.
     *
     * <p>설정을 한 번도 건드리지 않은 유저는 행이 없고, 그건 전부 켜짐을 뜻한다.
     */
    @Transactional(readOnly = true)
    public boolean allowsPush(Long userId, NotificationType type) {
        return prefRepository.findById(userId)
                .map(p -> p.allows(type))
                .orElse(true);
    }
}

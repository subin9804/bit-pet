package io.bitpet.auth.service;

import io.bitpet.auth.domain.AgreementSource;
import io.bitpet.auth.domain.AgreementType;
import io.bitpet.auth.domain.UserAgreementDtl;
import io.bitpet.auth.dto.AgreementStatusResponse;
import io.bitpet.auth.repository.UserAgreementDtlRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

/**
 * 약관 동의 기록.
 *
 * <p>가입 화면에서 체크만 받고 버려지던 동의 사실을 남긴다. 개인정보 처리의 법적 근거이자,
 * 마케팅 발송의 근거이기도 하다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AgreementService {

    private final UserAgreementDtlRepository agreementRepository;

    /**
     * 가입 시점의 동의를 기록한다.
     *
     * <p>필수 항목이 하나라도 false 면 예외 — 가입 트랜잭션을 통째로 되돌린다.
     * 컨트롤러 검증(@AssertTrue)이 이미 걸러내지만, OAuth 나 나중에 생길 다른 가입 경로가
     * 이 메서드만 부르고 검증을 빠뜨릴 수 있어서 여기서도 막는다.
     *
     * <p>선택 항목은 false 여도 <b>행을 남긴다.</b> "동의하지 않음"과 "물어본 적 없음"은
     * 다른 상태이고, 마케팅 발송 분쟁에서 실제로 구별해야 하는 지점이다.
     */
    @Transactional
    public void recordSignupAgreements(Long userId, Map<AgreementType, Boolean> agreements,
                                       AgreementSource source) {
        List<UserAgreementDtl> rows = new ArrayList<>();
        for (AgreementType type : AgreementType.values()) {
            boolean agreed = Boolean.TRUE.equals(agreements.get(type));
            if (type.isRequired() && !agreed) {
                throw new BusinessException(ErrorCode.AUTH_AGREEMENT_REQUIRED,
                        "필수 약관에 동의해야 가입할 수 있습니다: " + type.name());
            }
            rows.add(UserAgreementDtl.record(userId, type, agreed, source));
        }
        agreementRepository.saveAll(rows);
    }

    /**
     * 가입 화면을 거치지 않은 계정의 동의를 뒤늦게 받는다.
     *
     * <p>소셜 로그인은 약관 화면 없이 계정이 만들어진다. 그 자리에서 동의한 것으로
     * 기록해버리면 <b>사용자가 본 적도 없는 약관에 동의했다는 거짓 기록</b>이 남는다.
     * 그래서 소셜 가입 시점에는 아무것도 쓰지 않고, 앱이 로그인 후
     * {@code GET /auth/me/agreements} 의 {@code needsReagreement} 를 보고 동의 화면을
     * 띄운 뒤 여기로 보낸다. 약관이 개정돼 재동의를 받을 때도 같은 경로를 쓴다.
     */
    @Transactional
    public void acceptAgreements(Long userId, Map<AgreementType, Boolean> agreements) {
        boolean first = agreementRepository.findByUserIdOrderByAgreedAtDesc(userId).isEmpty();
        recordSignupAgreements(userId, agreements,
                first ? AgreementSource.OAUTH_SIGNUP : AgreementSource.REAGREEMENT);
    }

    /**
     * 선택 항목(현재는 마케팅 수신) 변경. 동의든 철회든 새 행으로 쌓인다.
     *
     * <p>필수 항목은 이 경로로 바꿀 수 없다. 필수 약관 철회는 "동의 취소"가 아니라
     * 탈퇴이고, 여기서 false 를 받아주면 약관에 동의하지 않은 계정이 살아 있게 된다.
     */
    @Transactional
    public void changeOptionalAgreement(Long userId, AgreementType type, boolean agreed) {
        if (type.isRequired()) {
            throw new BusinessException(ErrorCode.AUTH_AGREEMENT_REQUIRED,
                    "필수 약관은 철회할 수 없습니다. 서비스 이용을 그만두시려면 회원 탈퇴를 이용해 주세요.");
        }
        agreementRepository.save(
                UserAgreementDtl.record(userId, type, agreed, AgreementSource.SETTINGS));
        log.info("agreement changed: userId={}, type={}, agreed={}", userId, type, agreed);
    }

    /** 마케팅 푸시·메일을 보내도 되는지. 기록이 없으면 보내지 않는다(동의 없음이 기본). */
    @Transactional(readOnly = true)
    public boolean canSendMarketing(Long userId) {
        UserAgreementDtl latest = latestByType(userId).get(AgreementType.MARKETING);
        return latest != null && latest.isAgreed();
    }

    @Transactional(readOnly = true)
    public AgreementStatusResponse getStatus(Long userId) {
        Map<AgreementType, UserAgreementDtl> latest = latestByType(userId);

        List<AgreementStatusResponse.Item> items = new ArrayList<>();
        for (AgreementType type : AgreementType.values()) {
            UserAgreementDtl row = latest.get(type);
            items.add(new AgreementStatusResponse.Item(
                    type,
                    type.isRequired(),
                    row != null && row.isAgreed(),
                    row == null ? null : row.getVersion(),
                    type.currentVersion(),
                    row == null ? null : row.getAgreedAt()));
        }
        return AgreementStatusResponse.of(items);
    }

    /**
     * 항목별 최신 행. 조회가 agreedAt DESC 정렬이므로 먼저 만난 것이 최신이다.
     */
    private Map<AgreementType, UserAgreementDtl> latestByType(Long userId) {
        Map<AgreementType, UserAgreementDtl> latest = new EnumMap<>(AgreementType.class);
        for (UserAgreementDtl row : agreementRepository.findByUserIdOrderByAgreedAtDesc(userId)) {
            latest.putIfAbsent(row.getAgreementType(), row);
        }
        return latest;
    }
}

package io.bitpet.auth.service;

import io.bitpet.auth.domain.AgreementSource;
import io.bitpet.auth.domain.AgreementType;
import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.dto.ChildCreateRequest;
import io.bitpet.auth.dto.ChildResponse;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * 만 14세 미만 자녀 계정 (V12).
 *
 * <p>개인정보 보호법 제22조의2 는 만 14세 미만 아동의 개인정보를 처리하려면 법정대리인의
 * 동의를 받으라고 한다. <b>동의 방식은 '보호자가 로그인한 상태에서 자녀 계정을 만든다'</b> 로
 * 정했다 — 보호자 이메일로 링크를 보내는 방식은 아이가 아무 주소나 적어도 통과해서, 동의를
 * 받은 척하는 기록만 쌓인다.
 *
 * <p>⛔ <b>이 서비스에 '자녀 계정으로 로그인' 같은 대리 진입을 만들지 말 것.</b> 자녀 계정의
 * 비밀번호는 자녀의 것이고, 보호자가 아이 계정으로 들어가 글을 쓰면 그 글의 작성자가 누구인지
 * 아무도 답할 수 없게 된다. 감독은 '자녀 활동 보기'라는 별도 읽기 경로로 한다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GuardianService {

    private final UserMstRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AgreementService agreementService;
    private final AuthService authService;

    /**
     * 한 보호자가 만들 수 있는 자녀 계정 수.
     *
     * <p>형제가 여럿인 집을 막지 않을 만큼은 넉넉하되, 무제한으로 두면 이 경로가
     * <b>이메일 인증 없이 계정을 찍어내는 통로</b>가 된다(자녀 계정은 보호자 동의만으로 생긴다).
     */
    public static final int MAX_CHILDREN = 5;

    @Transactional
    public ChildResponse createChild(Long guardianUserId, ChildCreateRequest request) {
        UserMst guardian = userRepository.findById(guardianUserId)
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_USER_NOT_FOUND));

        // 자녀 계정이 또 자녀를 만들면 보호자 사슬이 생긴다. 법정대리인은 성인이어야 한다.
        if (guardian.getGuardianUserId() != null || guardian.isChild()) {
            throw new BusinessException(ErrorCode.GUARDIAN_NOT_ELIGIBLE);
        }

        // 만 14세 이상이면 보호자 동의가 필요 없다 — 본인이 직접 가입하면 되고,
        // 여기로 만들면 성인이 될 때까지 남의 계정에 매달린 계정이 된다.
        if (!isUnderConsentAge(request.birthDate())) {
            throw new BusinessException(ErrorCode.GUARDIAN_CHILD_AGE_INVALID);
        }

        if (userRepository.findByGuardianUserIdOrderByIdAsc(guardianUserId).size() >= MAX_CHILDREN) {
            throw new BusinessException(ErrorCode.GUARDIAN_CHILD_LIMIT,
                    "자녀 계정은 최대 " + MAX_CHILDREN + "개까지 만들 수 있어요.");
        }

        if (userRepository.existsByEmail(request.email())) {
            throw new BusinessException(ErrorCode.AUTH_EMAIL_ALREADY_EXISTS);
        }
        String nickname = authService.requireAvailableNickname(request.nickname(), null);

        UserMst child = UserMst.createChild(
                request.email(),
                passwordEncoder.encode(request.password()),
                nickname,
                request.profileColor(),
                request.birthDate(),
                guardianUserId);
        UserMst saved = userRepository.save(child);

        // 동의 기록은 계정 생성과 같은 트랜잭션이다. 기록이 실패하면 계정도 없던 일이 되어야
        // 한다 — 법정대리인 동의 근거가 없는 아동 계정이 남는 쪽이 훨씬 나쁘다.
        //
        // ⚠️ AGE_14 는 남기지 않는다. '만 14세 이상이다'라는 확인인데 이 계정은 그 반대다.
        //    그 자리를 GUARDIAN 이 대신한다.
        agreementService.recordChildAgreements(saved.getId(), Map.of(
                AgreementType.TOS, true,
                AgreementType.PRIVACY, true,
                AgreementType.GUARDIAN, request.isGuardianAgreed(),
                AgreementType.MARKETING, request.marketingAgreed()
        ));

        log.info("child account created: childId={}, guardianId={}", saved.getId(), guardianUserId);
        return ChildResponse.from(saved);
    }

    @Transactional(readOnly = true)
    public List<ChildResponse> listChildren(Long guardianUserId) {
        return userRepository.findByGuardianUserIdOrderByIdAsc(guardianUserId).stream()
                .map(ChildResponse::from)
                .toList();
    }

    /**
     * 자녀 계정인지, 그리고 그 보호자가 나인지.
     *
     * <p>남의 자녀를 조회하려는 요청은 404 다 — 403 으로 답하면 "그 id 가 누군가의 자녀"라는
     * 사실 자체가 새어 나간다.
     */
    @Transactional(readOnly = true)
    public UserMst getMyChild(Long guardianUserId, Long childId) {
        UserMst child = userRepository.findById(childId)
                .orElseThrow(() -> new BusinessException(ErrorCode.CHILD_NOT_FOUND));
        if (!child.isChildOf(guardianUserId)) {
            throw new BusinessException(ErrorCode.CHILD_NOT_FOUND);
        }
        return child;
    }

    /**
     * 자녀 계정 삭제. 일반 탈퇴와 <b>같은 경로</b>를 탄다 — 개체·기록·사진 정리가 전부
     * {@code AuthService.withdraw} 에 있고, 여기서 따로 지우면 둘이 갈라진다.
     *
     * <p>공유 개체는 넘기는 쪽(기본)으로 고정한다. 아이 계정에 탈퇴 옵션 화면을 다시 만들기보다,
     * 되돌릴 수 없는 삭제를 피하는 쪽이 맞다.
     */
    @Transactional
    public void deleteChild(Long guardianUserId, Long childId) {
        UserMst child = getMyChild(guardianUserId, childId);
        authService.withdraw(child.getId(), true);
        log.info("child account deleted: childId={}, guardianId={}", childId, guardianUserId);
    }

    private static boolean isUnderConsentAge(LocalDate birthDate) {
        return java.time.Period.between(birthDate, LocalDate.now()).getYears()
                < UserMst.GUARDIAN_CONSENT_AGE;
    }
}

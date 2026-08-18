package io.bitpet.auth.service;

import io.bitpet.auth.domain.AgreementSource;
import io.bitpet.auth.domain.AgreementType;
import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.dto.EmailCheckResponse;
import io.bitpet.auth.dto.LoginRequest;
import io.bitpet.auth.dto.NicknameCheckResponse;
import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.dto.TokenResponse;
import io.bitpet.auth.dto.UpdateMeRequest;
import io.bitpet.auth.dto.UserResponse;
import io.bitpet.auth.dto.WithdrawPreviewResponse;
import io.bitpet.auth.jwt.JwtTokenProvider;
import io.bitpet.auth.jwt.RefreshTokenStore;
import io.bitpet.auth.repository.UserMstRepository;
import io.bitpet.common.dto.PresignResponse;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.service.PetWithdrawalService;
import io.bitpet.storage.S3Service;
import io.jsonwebtoken.JwtException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserMstRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final RefreshTokenStore refreshTokenStore;
    private final S3Service s3Service;
    private final PetWithdrawalService petWithdrawalService;
    private final AgreementService agreementService;

    public EmailCheckResponse checkEmail(String email) {
        return new EmailCheckResponse(!userRepository.existsByEmail(email));
    }

    /**
     * 닉네임 중복확인. 형식 규칙과 중복을 한 번에 판정한다.
     *
     * <p>형식까지 여기서 보는 이유: 앱이 길이만 보고 통과시킨 뒤 가입에서 거절당하면
     * 사용자는 이유를 알 수 없다. 판정 기준은 서버 한 곳에만 둔다.
     */
    public NicknameCheckResponse checkNickname(String nickname) {
        String normalized = NicknamePolicy.normalize(nickname);
        String formatError = NicknamePolicy.validateFormat(normalized);
        if (formatError != null) {
            return NicknameCheckResponse.no(formatError);
        }
        if (userRepository.existsByNameIgnoreCase(normalized)) {
            return NicknameCheckResponse.no("이미 사용 중인 닉네임이에요");
        }
        return NicknameCheckResponse.ok();
    }

    @Transactional
    public UserResponse signup(SignupRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new BusinessException(ErrorCode.AUTH_EMAIL_ALREADY_EXISTS);
        }
        // 앱이 중복확인을 거쳤더라도 여기서 다시 본다. 확인 시점과 가입 시점 사이에
        // 남이 선점할 수 있고, API 를 직접 호출하면 확인 자체를 건너뛸 수 있다.
        String nickname = requireAvailableNickname(request.nickname(), null);

        String passwordHash = passwordEncoder.encode(request.password());
        UserMst user = UserMst.createLocal(request.email(), passwordHash, nickname);
        UserMst saved = userRepository.save(user);

        // 동의 기록은 가입과 같은 트랜잭션에 둔다. 기록에 실패하면 가입도 없던 일이 되어야
        // 한다 — 동의 근거 없는 계정이 남는 쪽이 가입 실패보다 나쁘다.
        agreementService.recordSignupAgreements(saved.getId(), Map.of(
                AgreementType.TOS, request.isTosAgreed(),
                AgreementType.PRIVACY, request.isPrivacyAgreed(),
                AgreementType.AGE_14, request.isAgeAgreed(),
                AgreementType.MARKETING, request.marketingAgreed()
        ), AgreementSource.SIGNUP);

        log.info("User signed up: id={}, email={}", saved.getId(), saved.getEmail());
        return UserResponse.from(saved);
    }

    @Transactional
    public TokenResponse login(LoginRequest request) {
        UserMst user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_INVALID_CREDENTIALS));

        if (user.getPasswordHash() == null
                || !passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new BusinessException(ErrorCode.AUTH_INVALID_CREDENTIALS);
        }

        user.markLoggedIn();
        return issueTokens(user);
    }

    public TokenResponse refresh(String refreshToken) {
        Long userId;
        try {
            userId = tokenProvider.extractUserIdFromRefreshToken(refreshToken);
        } catch (JwtException e) {
            throw new BusinessException(ErrorCode.AUTH_INVALID_TOKEN, e.getMessage());
        }

        if (!refreshTokenStore.matches(userId, refreshToken)) {
            throw new BusinessException(ErrorCode.AUTH_REFRESH_TOKEN_NOT_FOUND);
        }

        UserMst user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_USER_NOT_FOUND));

        return issueTokens(user);
    }

    @Transactional(readOnly = true)
    public UserResponse getMe(Long userId) {
        UserMst user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_USER_NOT_FOUND));
        return UserResponse.from(user, s3Service.resolveUrl(user.getProfileImageUrl()));
    }

    /** 프로필 이미지 업로드용 presigned PUT URL 발급 */
    public PresignResponse presignProfileImage(Long userId, String filename) {
        String ext = extractExtension(filename);
        String s3Key = "profiles/user/" + userId + "/" + UUID.randomUUID()
                + (ext.isEmpty() ? "" : "." + ext);
        String url = s3Service.presignPut(s3Key, resolveContentType(ext)).url().toString();
        return new PresignResponse(url, s3Key);
    }

    /** 내 프로필 수정 (닉네임/프로필 이미지) — 전달된 필드만 반영 */
    @Transactional
    public UserResponse updateMe(Long userId, UpdateMeRequest req) {
        UserMst user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_USER_NOT_FOUND));
        if (req.nickname() != null && !req.nickname().isBlank()) {
            // 자기 자신은 중복에서 제외한다. 안 그러면 닉네임을 바꾸지 않고
            // 프로필 사진만 교체하는 저장조차 "이미 사용 중" 으로 막힌다.
            user.changeName(requireAvailableNickname(req.nickname(), userId));
        }
        if (req.profileImageKey() != null) {
            user.changeProfileImageUrl(req.profileImageKey().isBlank() ? null : req.profileImageKey());
        }
        if (req.showNicknameInPedigree() != null) {
            user.changeShowNicknameInPedigree(req.showNicknameInPedigree());
        }
        return UserResponse.from(user, s3Service.resolveUrl(user.getProfileImageUrl()));
    }

    /**
     * 닉네임을 정규화하고 형식·중복을 검사한 뒤 저장할 값을 돌려준다.
     *
     * @param excludeUserId 중복 검사에서 제외할 사용자(프로필 수정 시 본인). 가입이면 null
     * @throws BusinessException 형식 위반(400) 또는 중복(409)
     */
    private String requireAvailableNickname(String raw, Long excludeUserId) {
        String nickname = NicknamePolicy.normalize(raw);

        String formatError = NicknamePolicy.validateFormat(nickname);
        if (formatError != null) {
            throw new BusinessException(ErrorCode.AUTH_NICKNAME_INVALID, formatError);
        }

        boolean taken = excludeUserId == null
                ? userRepository.existsByNameIgnoreCase(nickname)
                : userRepository.existsByNameIgnoreCaseAndIdNot(nickname, excludeUserId);
        if (taken) {
            throw new BusinessException(ErrorCode.AUTH_NICKNAME_ALREADY_EXISTS);
        }
        return nickname;
    }

    private static String extractExtension(String filename) {
        if (filename == null || !filename.contains(".")) return "";
        return filename.substring(filename.lastIndexOf('.') + 1).toLowerCase();
    }

    private static String resolveContentType(String ext) {
        return switch (ext) {
            case "jpg", "jpeg" -> "image/jpeg";
            case "png"         -> "image/png";
            case "webp"        -> "image/webp";
            case "heic"        -> "image/heic";
            default            -> "application/octet-stream";
        };
    }

    public void logout(Long userId) {
        refreshTokenStore.delete(userId);
    }

    /**
     * 탈퇴 전 미리보기 — 공동 사육자가 있는 개체 목록. 탈퇴 화면에서 "넘길지 지울지"를 묻는 근거다.
     * 목록이 비면 앱은 선택지 없이 일반 확인만 띄운다.
     */
    @Transactional(readOnly = true)
    public WithdrawPreviewResponse previewWithdraw(Long userId) {
        List<PetWithdrawalService.SharedPet> shared = petWithdrawalService.findSharedPets(userId);
        if (shared.isEmpty()) return new WithdrawPreviewResponse(List.of());

        Map<Long, String> nicknames = userRepository
                .findAllById(shared.stream().map(PetWithdrawalService.SharedPet::recipientUserId).toList())
                .stream()
                .collect(Collectors.toMap(UserMst::getId, UserMst::getName));

        return new WithdrawPreviewResponse(shared.stream()
                .map(s -> new WithdrawPreviewResponse.SharedPet(
                        s.petId(), s.petName(), s.recipientUserId(),
                        nicknames.get(s.recipientUserId())))
                .toList());
    }

    /**
     * 회원 탈퇴 — 계정 소프트 삭제 + 개체 처리를 <b>한 트랜잭션</b>으로 끝낸다.
     *
     * <p>개체 처리는 {@link PetWithdrawalService}가 맡는다. 참조가 걸린 개체는 익명화해 남고
     * 나머지는 물리 삭제된다. S3 오브젝트 삭제만 커밋 뒤로 미룬다 —
     * 외부 호출이 실패했다고 탈퇴를 롤백할 수는 없다.
     *
     * @param handOverSharedPets 공동 사육자가 있는 개체를 그 사람에게 넘길지. 사용자가 고른다.
     *                           false 면 다른 개체와 똑같이 삭제/익명화된다
     */
    @Transactional
    public void withdraw(Long userId, boolean handOverSharedPets) {
        UserMst user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.AUTH_USER_NOT_FOUND));

        PetWithdrawalService.Result petResult =
                petWithdrawalService.process(userId, handOverSharedPets);

        user.softDelete();
        refreshTokenStore.delete(userId);
        log.info("User withdrew: id={}, deletedAt={}, pets={}", userId, user.getDeletedAt(), petResult);
    }

    private TokenResponse issueTokens(UserMst user) {
        String access = tokenProvider.issueAccessToken(user.getId(), user.getEmail(), user.getUserType().name());
        String refresh = tokenProvider.issueRefreshToken(user.getId());
        refreshTokenStore.save(user.getId(), refresh);
        return TokenResponse.bearer(access, refresh);
    }
}

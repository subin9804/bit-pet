package io.bitpet.auth.service;

import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.dto.EmailCheckResponse;
import io.bitpet.auth.dto.LoginRequest;
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

    public EmailCheckResponse checkEmail(String email) {
        return new EmailCheckResponse(!userRepository.existsByEmail(email));
    }

    @Transactional
    public UserResponse signup(SignupRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new BusinessException(ErrorCode.AUTH_EMAIL_ALREADY_EXISTS);
        }
        String passwordHash = passwordEncoder.encode(request.password());
        UserMst user = UserMst.createLocal(request.email(), passwordHash, request.nickname());
        UserMst saved = userRepository.save(user);
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
            user.changeName(req.nickname().trim());
        }
        if (req.profileImageKey() != null) {
            user.changeProfileImageUrl(req.profileImageKey().isBlank() ? null : req.profileImageKey());
        }
        if (req.showNicknameInPedigree() != null) {
            user.changeShowNicknameInPedigree(req.showNicknameInPedigree());
        }
        return UserResponse.from(user, s3Service.resolveUrl(user.getProfileImageUrl()));
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

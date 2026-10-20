package io.bitpet.auth.oauth;

import io.bitpet.auth.domain.UserMst;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationSuccessHandler;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

import java.io.IOException;

/**
 * 소셜 로그인 성공 → 앱으로 **일회용 코드**만 돌려준다. 토큰은 앱이
 * {@code POST /auth/oauth/exchange} 로 바꿔 간다 ({@link OAuthLoginCodeStore} 참고).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OAuth2SuccessHandler extends SimpleUrlAuthenticationSuccessHandler {

    private final OAuthLoginCodeStore codeStore;
    private final OAuth2Properties oAuth2Properties;

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request,
                                         HttpServletResponse response,
                                         Authentication authentication) throws IOException {

        OAuth2UserPrincipal principal = (OAuth2UserPrincipal) authentication.getPrincipal();
        UserMst user = principal.getUser();

        // 로그인 왕복에만 쓴 세션이다. 여기서 끝낸다 — API 는 JWT 로만 인증한다.
        HttpSession session = request.getSession(false);
        String challenge = session == null ? null
                : (String) session.getAttribute(AppChallengeAuthorizationRequestResolver.SESSION_ATTR);
        if (session != null) session.invalidate();

        String redirect;
        if (challenge == null) {
            // 앱을 거치지 않고 주소를 직접 연 경우. 코드를 내줘도 교환할 수 없으니 실패로 돌린다.
            log.warn("OAuth login without app_challenge: userId={}", user.getId());
            redirect = UriComponentsBuilder.fromUriString(oAuth2Properties.failureRedirectUri())
                    .queryParam("error", "missing_challenge")
                    .build().toUriString();
        } else {
            redirect = UriComponentsBuilder.fromUriString(oAuth2Properties.successRedirectUri())
                    .queryParam("code", codeStore.issue(user.getId(), challenge))
                    .build().toUriString();
            log.info("OAuth login success: userId={}", user.getId());
        }

        clearAuthenticationAttributes(request);
        getRedirectStrategy().sendRedirect(request, response, redirect);
    }
}

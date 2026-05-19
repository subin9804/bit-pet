package io.bitpet.auth.oauth;

import io.bitpet.auth.domain.UserMst;
import io.bitpet.auth.jwt.JwtTokenProvider;
import io.bitpet.auth.jwt.RefreshTokenStore;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationSuccessHandler;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

import java.io.IOException;

@Slf4j
@Component
@RequiredArgsConstructor
public class OAuth2SuccessHandler extends SimpleUrlAuthenticationSuccessHandler {

    private final JwtTokenProvider tokenProvider;
    private final RefreshTokenStore refreshTokenStore;
    private final OAuth2Properties oAuth2Properties;

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request,
                                         HttpServletResponse response,
                                         Authentication authentication) throws IOException {

        OAuth2UserPrincipal principal = (OAuth2UserPrincipal) authentication.getPrincipal();
        UserMst user = principal.getUser();

        String access = tokenProvider.issueAccessToken(user.getId(), user.getEmail(), user.getUserType().name());
        String refresh = tokenProvider.issueRefreshToken(user.getId());
        refreshTokenStore.save(user.getId(), refresh);

        String redirect = UriComponentsBuilder.fromUriString(oAuth2Properties.successRedirectUri())
                .queryParam("accessToken", access)
                .queryParam("refreshToken", refresh)
                .build()
                .toUriString();

        log.info("OAuth login success: userId={}", user.getId());
        clearAuthenticationAttributes(request);
        getRedirectStrategy().sendRedirect(request, response, redirect);
    }
}

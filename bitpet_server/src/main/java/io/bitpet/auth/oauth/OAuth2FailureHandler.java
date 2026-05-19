package io.bitpet.auth.oauth;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationFailureHandler;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

@Slf4j
@Component
@RequiredArgsConstructor
public class OAuth2FailureHandler extends SimpleUrlAuthenticationFailureHandler {

    private final OAuth2Properties oAuth2Properties;

    @Override
    public void onAuthenticationFailure(HttpServletRequest request,
                                          HttpServletResponse response,
                                          AuthenticationException exception) throws IOException {

        log.warn("OAuth login failed: {}", exception.getMessage());
        String redirect = UriComponentsBuilder.fromUriString(oAuth2Properties.failureRedirectUri())
                .queryParam("error", java.net.URLEncoder.encode(
                        exception.getMessage() != null ? exception.getMessage() : "OAuth login failed",
                        StandardCharsets.UTF_8))
                .build()
                .toUriString();
        getRedirectStrategy().sendRedirect(request, response, redirect);
    }
}

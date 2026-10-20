package io.bitpet.auth.oauth;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.oauth2.client.web.DefaultOAuth2AuthorizationRequestResolver;
import org.springframework.security.oauth2.client.web.OAuth2AuthorizationRequestResolver;
import org.springframework.security.oauth2.core.endpoint.OAuth2AuthorizationRequest;

import java.util.regex.Pattern;

/**
 * 앱이 소셜 로그인을 시작할 때 붙여 보낸 {@code app_challenge} 를 세션에 맡겨둔다.
 *
 * <p>앱은 {@code /oauth2/authorization/{provider}?app_challenge=...} 로 브라우저를 연다.
 * challenge 는 앱만 아는 verifier 의 SHA-256 (base64url) 이다. 로그인이 끝나면
 * {@link OAuth2SuccessHandler} 가 세션에서 꺼내 교환 코드에 묶는다.
 *
 * <p>세션을 쓰는 건 새 부담이 아니다 — Spring 의 기본 인가 요청 저장소가 이미
 * 같은 세션에 state 를 담아 제공자 왕복을 버틴다. challenge 도 그 세션에 얹는다.
 */
public class AppChallengeAuthorizationRequestResolver implements OAuth2AuthorizationRequestResolver {

    public static final String SESSION_ATTR = "bitpet.oauth.appChallenge";
    private static final String PARAM = "app_challenge";

    /** SHA-256 base64url(패딩 없음) 은 43자다. 다른 형태는 받지 않는다. */
    private static final Pattern CHALLENGE = Pattern.compile("^[A-Za-z0-9_-]{43}$");

    private final DefaultOAuth2AuthorizationRequestResolver delegate;

    public AppChallengeAuthorizationRequestResolver(ClientRegistrationRepository repository) {
        this.delegate = new DefaultOAuth2AuthorizationRequestResolver(
                repository, "/oauth2/authorization");
    }

    @Override
    public OAuth2AuthorizationRequest resolve(HttpServletRequest request) {
        return remember(request, delegate.resolve(request));
    }

    @Override
    public OAuth2AuthorizationRequest resolve(HttpServletRequest request, String clientRegistrationId) {
        return remember(request, delegate.resolve(request, clientRegistrationId));
    }

    private OAuth2AuthorizationRequest remember(HttpServletRequest request, OAuth2AuthorizationRequest resolved) {
        if (resolved == null) return null;
        String challenge = request.getParameter(PARAM);
        // 이전 시도의 값이 남아 있으면 다음 로그인에 엉뚱하게 묶이므로 매번 덮어쓴다.
        if (challenge != null && CHALLENGE.matcher(challenge).matches()) {
            request.getSession().setAttribute(SESSION_ATTR, challenge);
        } else if (request.getSession(false) != null) {
            request.getSession(false).removeAttribute(SESSION_ATTR);
        }
        return resolved;
    }
}

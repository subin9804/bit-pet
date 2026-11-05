package io.bitpet.auth.oauth;

import io.bitpet.auth.domain.OAuthProvider;
import io.bitpet.auth.domain.UserMst;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.core.user.OAuth2User;

import java.util.Collection;
import java.util.List;
import java.util.Map;

@Getter
public class OAuth2UserPrincipal implements OAuth2User {

    private final UserMst user;
    private final Map<String, Object> attributes;
    private final String nameAttributeKey;

    /**
     * 이번 로그인에서 <b>기존 계정에 새로 붙은</b> 제공자. 처음 연결된 순간에만 값이 있고
     * (새 가입·이미 연결된 계정은 null) 앱이 "카카오 계정이 연결됐어요" 를 띄우는 데 쓴다.
     */
    private final OAuthProvider linkedProvider;

    public OAuth2UserPrincipal(UserMst user, Map<String, Object> attributes, String nameAttributeKey,
                               OAuthProvider linkedProvider) {
        this.user = user;
        this.attributes = attributes;
        this.nameAttributeKey = nameAttributeKey;
        this.linkedProvider = linkedProvider;
    }

    @Override
    public Map<String, Object> getAttributes() {
        return attributes;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + user.getUserType().name()));
    }

    @Override
    public String getName() {
        Object value = attributes.get(nameAttributeKey);
        return value != null ? value.toString() : String.valueOf(user.getId());
    }
}

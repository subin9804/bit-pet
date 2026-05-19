package io.bitpet.auth.repository;

import io.bitpet.auth.domain.OAuthProvider;
import io.bitpet.auth.domain.UserOAuthRls;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserOAuthRlsRepository extends JpaRepository<UserOAuthRls, Long> {

    Optional<UserOAuthRls> findByProviderAndProviderUserId(OAuthProvider provider, String providerUserId);

    List<UserOAuthRls> findAllByUserId(Long userId);
}

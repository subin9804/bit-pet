package io.bitpet.auth.repository;

import io.bitpet.auth.domain.UserMst;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserMstRepository extends JpaRepository<UserMst, Long> {

    Optional<UserMst> findByEmail(String email);

    boolean existsByEmail(String email);
}

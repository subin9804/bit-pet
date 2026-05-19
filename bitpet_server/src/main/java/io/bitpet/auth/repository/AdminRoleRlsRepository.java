package io.bitpet.auth.repository;

import io.bitpet.auth.domain.AdminRoleRls;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AdminRoleRlsRepository extends JpaRepository<AdminRoleRls, Long> {

    List<AdminRoleRls> findAllByUserId(Long userId);

    boolean existsByUserIdAndRole(Long userId, String role);
}

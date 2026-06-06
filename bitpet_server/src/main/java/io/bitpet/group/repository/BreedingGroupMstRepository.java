package io.bitpet.group.repository;

import io.bitpet.group.domain.BreedingGroupMst;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface BreedingGroupMstRepository extends JpaRepository<BreedingGroupMst, Long> {

    Optional<BreedingGroupMst> findByInviteCode(String inviteCode);

    boolean existsByInviteCode(String inviteCode);
}

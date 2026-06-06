package io.bitpet.group.repository;

import io.bitpet.group.domain.BreedingGroupUserRls;
import io.bitpet.group.domain.BreedingGroupUserRlsId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface BreedingGroupUserRlsRepository
        extends JpaRepository<BreedingGroupUserRls, BreedingGroupUserRlsId> {

    // 유저의 현재 그룹 멤버십
    Optional<BreedingGroupUserRls> findByIdUserId(Long userId);

    // 그룹의 멤버 목록 (user 정보 JOIN)
    @Query("""
            SELECT r FROM BreedingGroupUserRls r
            WHERE r.id.groupId = :groupId
            ORDER BY r.joinedAt
            """)
    List<BreedingGroupUserRls> findAllByGroupId(@Param("groupId") Long groupId);

    void deleteByIdGroupId(Long groupId);
}

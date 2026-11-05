package io.bitpet.photo.repository;

import io.bitpet.photo.domain.EntityType;
import io.bitpet.photo.domain.PhotoDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PhotoDtlRepository extends JpaRepository<PhotoDtl, Long> {

    /**
     * 최근에 올린 사진이 앞(갤러리 왼쪽 위). 예전엔 takenAt 순이었는데 앱이 takenAt 을
     * 보내지 않아 전부 null 이라 사실상 오래된 순으로 나왔다 (2026-11-05 사용자 지적).
     */
    List<PhotoDtl> findAllByEntityTypeAndEntityIdOrderByDisplayOrderAscCreatedAtDescIdDesc(
            EntityType entityType, Long entityId);

    Optional<PhotoDtl> findByIdAndEntityType(Long id, EntityType entityType);
}

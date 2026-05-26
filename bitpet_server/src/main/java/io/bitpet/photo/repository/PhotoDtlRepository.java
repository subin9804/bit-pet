package io.bitpet.photo.repository;

import io.bitpet.photo.domain.EntityType;
import io.bitpet.photo.domain.PhotoDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PhotoDtlRepository extends JpaRepository<PhotoDtl, Long> {

    List<PhotoDtl> findAllByEntityTypeAndEntityIdOrderByDisplayOrderAscTakenAtDesc(
            EntityType entityType, Long entityId);

    Optional<PhotoDtl> findByIdAndEntityType(Long id, EntityType entityType);
}

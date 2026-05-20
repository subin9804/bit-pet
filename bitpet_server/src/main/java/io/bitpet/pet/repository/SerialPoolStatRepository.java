package io.bitpet.pet.repository;

import io.bitpet.pet.domain.SerialPoolStatMst;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SerialPoolStatRepository extends JpaRepository<SerialPoolStatMst, Long> {

    List<SerialPoolStatMst> findAllByOrderBySerialLengthAsc();

    Optional<SerialPoolStatMst> findBySerialLength(int serialLength);

    Optional<SerialPoolStatMst> findByCurrent(boolean current);
}

package io.bitpet.notification.repository;

import io.bitpet.notification.domain.NotificationLogDtl;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NotificationLogDtlRepository extends JpaRepository<NotificationLogDtl, Long> {

    List<NotificationLogDtl> findTop50ByUserIdOrderBySentAtDesc(Long userId);
}

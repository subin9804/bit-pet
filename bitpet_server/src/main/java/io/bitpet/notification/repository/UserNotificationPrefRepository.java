package io.bitpet.notification.repository;

import io.bitpet.notification.domain.UserNotificationPref;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserNotificationPrefRepository extends JpaRepository<UserNotificationPref, Long> {
}

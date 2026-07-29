package io.bitpet.notification.repository;

import io.bitpet.notification.domain.DeviceTokenRls;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface DeviceTokenRlsRepository extends JpaRepository<DeviceTokenRls, Long> {

    Optional<DeviceTokenRls> findByDeviceToken(String deviceToken);

    List<DeviceTokenRls> findByUserId(Long userId);

    void deleteByDeviceToken(String deviceToken);

    void deleteByDeviceTokenIn(Collection<String> deviceTokens);
}

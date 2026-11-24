package io.bitpet.banner.repository;

import io.bitpet.banner.domain.HomeBannerMst;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface HomeBannerMstRepository extends JpaRepository<HomeBannerMst, Long> {

    /** 배너는 많아야 수십 장이라 전부 읽어 메모리에서 거른다 */
    List<HomeBannerMst> findAllByOrderBySortOrderAscIdAsc();
}

package io.bitpet.community.repository;

import io.bitpet.community.domain.PostCategoryCd;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PostCategoryCdRepository extends JpaRepository<PostCategoryCd, Long> {

    List<PostCategoryCd> findAllByOrderByDisplayOrderAsc();
}

package io.bitpet.record.laying.service;

import io.bitpet.record.laying.domain.LayingHatchDtl;
import io.bitpet.record.laying.repository.LayingHatchDtlRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 클러치(알) ↔ 개체 연결 유지보수.
 *
 * <p>개체 삭제는 <b>소프트 삭제</b>(`deleted_at`)라서 FK 의 {@code ON DELETE SET NULL} 도,
 * 물리 삭제 경로({@code PetPurgeRepository})의 링크 해제도 돌지 않는다. 그래서 이게 없으면
 * {@code laying_hatch_dtl.hatched_pet_id} 가 사라진 개체를 계속 가리킨 채로 남는다 —
 * 알 칸은 '등록됨'으로 보이는데 눌러도 없는 개체로 가고, 등록된 알은 순환에서 빠지므로
 * ({@code HATCH_ALREADY_REGISTERED}) 상태를 되돌릴 수도 없다.
 *
 * <p>⛔ 연결만 끊고 <b>개체를 다시 만들지도, 알을 지우지도 않는다.</b> 알은 부화 기록이고
 * 개체는 사육 대상이라 수명이 서로 다르다.
 */
@Service
@RequiredArgsConstructor
public class LayingMaintenanceService {

    private final LayingHatchDtlRepository hatchRepository;

    /** 개체가 삭제됨. 그 개체를 가리키는 알의 연결을 끊는다 (상태는 HATCHED 유지) */
    @Transactional
    public void onPetDeleted(Long petId) {
        for (LayingHatchDtl hatch : hatchRepository.findAllByHatchedPetId(petId)) {
            hatch.unlinkPet();
        }
    }
}

package io.bitpet.pet.service;

import io.bitpet.nfc.domain.NfcTagMst;
import io.bitpet.nfc.repository.NfcTagMstRepository;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.pet.repository.PetPurgeRepository;
import io.bitpet.routine.service.RoutineMaintenanceService;
import io.bitpet.storage.service.S3DeleteQueueService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 개체 물리 삭제 · 익명화 보존 실행부.
 *
 * <p>탈퇴({@link PetWithdrawalService})와 고아 정리 배치가 같은 코드를 쓴다.
 * 두 곳에서 "무엇을 지우고 무엇을 남기는가"가 어긋나면 정리 배치가 탈퇴 때 남긴 것을
 * 다시 살려내거나, 지워야 할 걸 빠뜨린다.
 *
 * <p>항상 호출부의 트랜잭션 안에서 돈다({@code MANDATORY}) — 탈퇴 전체가 한 트랜잭션이어야 한다.
 * S3 삭제만 예외로, 키를 큐에 적재해 커밋 뒤로 미룬다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PetPurgeService {

    private final PetMstRepository petRepository;
    private final PetPurgeRepository purgeRepository;
    private final NfcTagMstRepository tagRepository;
    private final RoutineMaintenanceService routineMaintenance;
    private final S3DeleteQueueService s3DeleteQueue;

    /**
     * 완전 삭제 — 개체와 딸린 기록·사진을 전부 지운다.
     *
     * <p>손으로 지우는 건 사진뿐이다. {@code photo_dtl} 은 폴리모픽이라 {@code pet_mst} FK 가 없어
     * 개체를 지워도 남는다. 나머지(기록·모프·사육자·가계도·루틴 연결)는 전부
     * {@code ON DELETE CASCADE} 로 따라 지워진다.
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public void purge(Long petId) {
        deletePhotos(petId, null);
        releaseTags(petId);
        // 다른 사람 루틴이 이 개체를 물고 있을 수 있다 — 연결을 끊고 활성 상태를 재계산한다.
        // (CASCADE 로도 행은 지워지지만 is_active 는 그대로 남는다)
        routineMaintenance.onPetDeleted(petId);
        purgeRepository.deletePet(petId);
        log.info("Pet purged: id={}", petId);
    }

    /**
     * 익명화 보존 — 소유자만 떼어내고 혈통 식별에 필요한 것만 남긴다.
     *
     * <p>남기는 것: 개체명·종·모프·성별·해칭일·부모 참조, 그리고 대표 사진 한 장.
     * 지우는 것: 사육 기록 전부, 대표 외 사진, 사육자 연결, NFC 태그 연결.
     *
     * @return 익명화했으면 true. 개체가 이미 소프트 삭제 상태라 물리 삭제로 대신했으면 false
     */
    @Transactional(propagation = Propagation.MANDATORY)
    public boolean anonymize(Long petId) {
        PetMst pet = petRepository.findById(petId).orElse(null);
        if (pet == null) {
            // 소유자가 살아 있을 때 이미 지웠던 개체다. 남겨둘 이름조차 화면에 뜨지 않으므로
            // 보존할 의미가 없다 — 이번 기회에 물리 삭제로 정리한다.
            purge(petId);
            return false;
        }

        // 대표 사진이 지정돼 있지 않으면 첫 장을 대표로 승격시켜 남긴다
        Long keepPhotoId = pet.getProfilePhotoId() != null
                ? pet.getProfilePhotoId()
                : purgeRepository.findFirstPhotoIdOfPet(petId);
        deletePhotos(petId, keepPhotoId);
        pet.setProfilePhoto(keepPhotoId);

        routineMaintenance.onPetDeleted(petId);
        releaseTags(petId);

        purgeRepository.deleteWeights(petId);
        purgeRepository.deleteFeedings(petId);
        purgeRepository.deleteCleanings(petId);
        purgeRepository.deleteMemos(petId);
        purgeRepository.deleteLayings(petId);
        purgeRepository.deleteRoutineLogs(petId);
        purgeRepository.deleteRoutineLinks(petId);
        purgeRepository.deleteShareInvitations(petId);
        purgeRepository.deleteKeepers(petId);
        purgeRepository.detachHatchLinks(petId);
        purgeRepository.detachNotificationLogs(petId);

        pet.anonymizeOnWithdrawal();
        log.info("Pet anonymized: id={}", petId);
        return true;
    }

    /**
     * NFC 태그 연결 해제 — 개체 연결과 소유권을 끊되 상태는 SOLD 로 둔다.
     *
     * <p>재고(STOCK)로 되돌리지 않는다. 계정이 사라져도 태그 실물은 그 사람 손에 있고
     * 굽힌 URL 은 락이 걸려 바꿀 수 없다 — 회수해 되팔 수 있는 물건이 아니다.
     */
    private void releaseTags(Long petId) {
        List<NfcTagMst> tags = tagRepository.findAllByPetId(petId);
        tags.forEach(NfcTagMst::unlink);
    }

    /** 사진 행 삭제 + S3 키를 삭제 큐에 적재. keepPhotoId 는 남길 대표 사진(없으면 null) */
    private void deletePhotos(Long petId, Long keepPhotoId) {
        s3DeleteQueue.enqueue(purgeRepository.findPhotoKeysOfPet(petId, keepPhotoId));
        purgeRepository.deletePhotosOfPet(petId, keepPhotoId);
    }
}

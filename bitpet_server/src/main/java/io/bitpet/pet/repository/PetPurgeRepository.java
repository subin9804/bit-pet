package io.bitpet.pet.repository;

import io.bitpet.pet.domain.PetMst;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import java.util.List;

/**
 * 탈퇴·고아 정리 전용 물리 삭제 쿼리 모음.
 *
 * <p>일반 서비스가 쓰는 소프트 삭제와 성격이 완전히 달라 별도 인터페이스로 떼어 뒀다.
 * 전부 네이티브 쿼리다 — {@code @SQLRestriction("deleted_at IS NULL")} 때문에 JPQL 로는
 * 이미 소프트 삭제된 행에 손이 닿지 않는데, 여기서는 그것까지 지워야 한다.
 *
 * <p>연관 테이블 대부분은 {@code pet_mst} FK 가 {@code ON DELETE CASCADE} 라
 * 개체 행만 지우면 따라 지워진다. 손으로 지워야 하는 건 두 가지다 —
 * 폴리모픽이라 FK 가 없는 {@code photo_dtl}, 그리고 개체를 남기는 익명화 경로의 기록들.
 */
public interface PetPurgeRepository extends Repository<PetMst, Long> {

    // -------------------------------------------------------------------------
    // 사진 (폴리모픽 — FK 없음. 개체를 지워도 자동으로 따라 지워지지 않는다)
    // -------------------------------------------------------------------------

    String PHOTO_SCOPE = """
            WHERE ((entity_type = 'PET'    AND entity_id = :petId)
                OR (entity_type = 'MEMO'   AND entity_id IN (SELECT id FROM memo_dtl   WHERE pet_id = :petId))
                OR (entity_type = 'LAYING' AND entity_id IN (SELECT id FROM laying_dtl WHERE pet_id = :petId))
                OR (entity_type = 'MATING' AND entity_id IN (SELECT id FROM mating_dtl
                        WHERE male_pet_id = :petId OR female_pet_id = :petId)))
              AND (CAST(:keepPhotoId AS BIGINT) IS NULL OR id <> CAST(:keepPhotoId AS BIGINT))
            """;

    /** 삭제 대상 사진의 S3 키 — 행을 지우기 전에 먼저 걷는다 */
    @Query(value = "SELECT s3_key FROM photo_dtl " + PHOTO_SCOPE, nativeQuery = true)
    List<String> findPhotoKeysOfPet(@Param("petId") Long petId,
                                    @Param("keepPhotoId") Long keepPhotoId);

    @Modifying
    @Query(value = "DELETE FROM photo_dtl " + PHOTO_SCOPE, nativeQuery = true)
    int deletePhotosOfPet(@Param("petId") Long petId,
                          @Param("keepPhotoId") Long keepPhotoId);

    /** 익명화 시 남길 대표 사진 — 지정된 게 없으면 표시 순서상 첫 장 */
    @Query(value = """
            SELECT id FROM photo_dtl
            WHERE entity_type = 'PET' AND entity_id = :petId AND deleted_at IS NULL
            ORDER BY display_order ASC, id ASC LIMIT 1
            """, nativeQuery = true)
    Long findFirstPhotoIdOfPet(@Param("petId") Long petId);

    // -------------------------------------------------------------------------
    // 익명화 보존 경로 — 개체는 남기고 사육 기록만 전부 지운다
    // -------------------------------------------------------------------------

    @Modifying
    @Query(value = "DELETE FROM weight_dtl WHERE pet_id = :petId", nativeQuery = true)
    int deleteWeights(@Param("petId") Long petId);

    @Modifying
    @Query(value = "DELETE FROM feeding_dtl WHERE pet_id = :petId", nativeQuery = true)
    int deleteFeedings(@Param("petId") Long petId);

    @Modifying
    @Query(value = "DELETE FROM cleaning_dtl WHERE pet_id = :petId", nativeQuery = true)
    int deleteCleanings(@Param("petId") Long petId);

    /** memo_tag_rls · memo_vet_ext_dtl 은 memo_dtl FK CASCADE 로 따라 지워진다 */
    @Modifying
    @Query(value = "DELETE FROM memo_dtl WHERE pet_id = :petId", nativeQuery = true)
    int deleteMemos(@Param("petId") Long petId);

    /** laying_hatch_dtl 은 laying_dtl FK CASCADE 로 따라 지워진다 */
    @Modifying
    @Query(value = "DELETE FROM laying_dtl WHERE pet_id = :petId", nativeQuery = true)
    int deleteLayings(@Param("petId") Long petId);

    @Modifying
    @Query(value = "DELETE FROM routine_log_dtl WHERE pet_id = :petId", nativeQuery = true)
    int deleteRoutineLogs(@Param("petId") Long petId);

    @Modifying
    @Query(value = "DELETE FROM routine_pet_rls WHERE pet_id = :petId", nativeQuery = true)
    int deleteRoutineLinks(@Param("petId") Long petId);

    @Modifying
    @Query(value = "DELETE FROM pet_keeper_rls WHERE pet_id = :petId", nativeQuery = true)
    int deleteKeepers(@Param("petId") Long petId);

    @Modifying
    @Query(value = "DELETE FROM pet_share_invitation WHERE pet_id = :petId", nativeQuery = true)
    int deleteShareInvitations(@Param("petId") Long petId);

    /** 남의 산란 기록이 이 개체를 "부화한 새끼"로 걸어둔 경우 — 기록 자체는 남의 것이라 참조만 끊는다 */
    @Modifying
    @Query(value = "UPDATE laying_hatch_dtl SET hatched_pet_id = NULL WHERE hatched_pet_id = :petId",
            nativeQuery = true)
    int detachHatchLinks(@Param("petId") Long petId);

    @Modifying
    @Query(value = "UPDATE notification_log_dtl SET pet_id = NULL WHERE pet_id = :petId",
            nativeQuery = true)
    int detachNotificationLogs(@Param("petId") Long petId);

    // -------------------------------------------------------------------------
    // 완전 삭제 경로
    // -------------------------------------------------------------------------

    /** 개체 행 물리 삭제. 나머지 연관은 FK CASCADE 가 처리한다(사진 제외 — 먼저 지울 것) */
    @Modifying
    @Query(value = "DELETE FROM pet_mst WHERE id = :petId", nativeQuery = true)
    int deletePet(@Param("petId") Long petId);

    // -------------------------------------------------------------------------
    // 탈퇴 회원 개인 데이터
    // -------------------------------------------------------------------------

    /** 루틴은 개체가 아니라 사람에게 달려 있다. routine_pet_rls · routine_log_dtl 은 CASCADE */
    @Modifying
    @Query(value = "DELETE FROM routine_mst WHERE user_id = :userId", nativeQuery = true)
    int deleteRoutinesOfUser(@Param("userId") Long userId);

    /** 남겨두면 사라진 계정으로 푸시가 계속 나간다 */
    @Modifying
    @Query(value = "DELETE FROM device_token_rls WHERE user_id = :userId", nativeQuery = true)
    int deleteDeviceTokensOfUser(@Param("userId") Long userId);

    @Modifying
    @Query(value = "DELETE FROM notification_log_dtl WHERE user_id = :userId", nativeQuery = true)
    int deleteNotificationLogsOfUser(@Param("userId") Long userId);

    @Modifying
    @Query(value = """
            DELETE FROM pet_share_invitation
            WHERE inviter_user_id = :userId OR invitee_user_id = :userId
            """, nativeQuery = true)
    int deleteShareInvitationsOfUser(@Param("userId") Long userId);

    // -------------------------------------------------------------------------
    // 고아 정리 배치
    // -------------------------------------------------------------------------

    /**
     * 참조가 완전히 끊긴 고아 개체.
     *
     * <p>참조는 두 가지뿐이다 — 남의 자식 개체가 이 개체를 부모로 걸고 있거나
     * ({@code pet_relation_rls.parent_pet_id}), 메이팅 기록이 상대로 걸고 있거나.
     * 이 개체가 <b>자식</b>으로 걸린 행은 참조로 세지 않는다. 그 행은 이 개체가 사라지면
     * 함께 사라지는 "이 개체의 가계도"이지, 남이 이 개체를 붙잡는 이유가 아니다.
     */
    @Query(value = """
            SELECT p.id FROM pet_mst p
            WHERE p.is_orphaned = true
              AND NOT EXISTS (SELECT 1 FROM pet_relation_rls r WHERE r.parent_pet_id = p.id)
              AND NOT EXISTS (SELECT 1 FROM mating_dtl m
                              WHERE (m.male_pet_id = p.id OR m.female_pet_id = p.id)
                                AND m.deleted_at IS NULL)
            ORDER BY p.id
            LIMIT :limit
            """, nativeQuery = true)
    List<Long> findUnreferencedOrphanIds(@Param("limit") int limit);
}

package io.bitpet.photo;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.service.PetService;
import io.bitpet.photo.domain.EntityType;
import io.bitpet.photo.dto.PhotoRegisterRequest;
import io.bitpet.photo.service.PhotoService;
import io.bitpet.record.laying.dto.HatchUpdateRequest;
import io.bitpet.record.laying.dto.LayingCreateRequest;
import io.bitpet.record.laying.dto.LayingResponse;
import io.bitpet.record.laying.service.LayingService;
import io.bitpet.record.mating.dto.MatingCreateRequest;
import io.bitpet.record.mating.dto.MatingUpdateRequest;
import io.bitpet.record.mating.service.MatingService;
import io.bitpet.record.memo.dto.MemoCreateRequest;
import io.bitpet.record.memo.service.MemoService;
import io.bitpet.storage.UploadKeys;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 보안 점검(2026-11-26)에서 나온 업로드·기록 경계 회귀 테스트.
 *
 * <ul>
 *   <li>사진 등록은 서버가 발급한 모양의 키만 받는다 — 남의 경로를 내 사진으로 걸었다가 지우는 통로</li>
 *   <li>MEMO/LAYING/MATING 사진은 그 기록의 개체 사육자만 — entityId 만 바꿔 남의 기록에 붙이던 통로</li>
 *   <li>메이팅 상대는 내 개체이거나 공개 개체 — 수정으로 남의 비공개 개체를 걸던 통로</li>
 *   <li>알 칸에 거는 개체는 내가 키우는 개체 — 남의 개체 계보에 부모가 끼어들던 통로</li>
 *   <li>탈퇴가 남이 만든 메이팅 기록의 사진을 지우지 않는다</li>
 * </ul>
 */
class UploadBoundaryIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();
    private static final OffsetDateTime NOW = OffsetDateTime.now();

    @Autowired private AuthService authService;
    @Autowired private PetService petService;
    @Autowired private PhotoService photoService;
    @Autowired private MemoService memoService;
    @Autowired private MatingService matingService;
    @Autowired private LayingService layingService;
    @Autowired private JdbcTemplate jdbc;

    private Long speciesId;

    @BeforeEach
    void setUp() {
        // 알 칸이 생겨야 하므로 포유류가 아닌 종
        speciesId = jdbc.queryForObject(
                "SELECT id FROM species_cd WHERE category <> 'M' ORDER BY id LIMIT 1", Long.class);
    }

    @Test
    void photo_register_rejects_keys_the_server_did_not_issue() {
        Long alice = signup();
        Long bob = signup();
        Long alicePet = pet(alice, PetGender.FEMALE);
        Long bobPet = pet(bob, PetGender.FEMALE);

        // 남의 개체 경로, 썸네일 키, 아무 경로 — 전부 거절
        for (String forged : List.of(
                "pets/" + bobPet + "/" + java.util.UUID.randomUUID() + ".jpg",
                "pets/" + alicePet + "/" + java.util.UUID.randomUUID() + "_thumb.jpg",
                "pets/" + alicePet + "/../" + bobPet + "/x.jpg",
                "profiles/1/avatar.png")) {
            assertCode(() -> photoService.registerPhoto(alice, register(EntityType.PET, alicePet, forged)),
                    ErrorCode.PHOTO_KEY_INVALID);
        }

        String issued = UploadKeys.newKey("pets/" + alicePet + "/", "jpg");
        assertThat(photoService.registerPhoto(alice, register(EntityType.PET, alicePet, issued))).isNotNull();
    }

    @Test
    void record_photos_follow_the_record_owner() {
        Long alice = signup();
        Long bob = signup();
        Long bobPet = pet(bob, PetGender.FEMALE);
        Long bobMemo = memoService.createMemo(bobPet, bob,
                new MemoCreateRequest("밥의 메모", NOW, null, null)).memoId();

        String key = UploadKeys.newKey("memos/" + bobMemo + "/", "jpg");
        assertCode(() -> photoService.registerPhoto(alice, register(EntityType.MEMO, bobMemo, key)),
                ErrorCode.PET_ACCESS_DENIED);
        // 사육자 본인은 된다
        assertThat(photoService.registerPhoto(bob, register(EntityType.MEMO, bobMemo, key))).isNotNull();
    }

    @Test
    void mating_partner_must_be_mine_or_public_on_create_and_update() {
        Long alice = signup();
        Long bob = signup();
        Long aliceFemale = pet(alice, PetGender.FEMALE);
        Long bobMale = pet(bob, PetGender.MALE);   // 기본 비공개

        assertCode(() -> matingService.createMating(aliceFemale, alice, mating(bobMale, aliceFemale)),
                ErrorCode.PET_NOT_FOUND);

        // 외부 상대로 만든 뒤 수정으로 남의 비공개 개체를 거는 우회도 막힌다
        Long matingId = matingService.createMating(aliceFemale, alice, mating(null, aliceFemale)).matingId();
        assertCode(() -> matingService.updateMating(matingId, alice, matingUpdate(bobMale, aliceFemale)),
                ErrorCode.PET_NOT_FOUND);

        // 공개 개체는 걸 수 있다 (일련번호 검색과 같은 규칙)
        jdbc.update("UPDATE pet_mst SET private_yn = 'N' WHERE id = ?", bobMale);
        assertThat(matingService.updateMating(matingId, alice, matingUpdate(bobMale, aliceFemale))).isNotNull();
    }

    @Test
    void hatch_can_only_link_a_pet_i_keep() {
        Long alice = signup();
        Long bob = signup();
        Long aliceFemale = pet(alice, PetGender.FEMALE);
        Long bobPet = pet(bob, PetGender.MALE);

        LayingResponse laying = layingService.createLaying(aliceFemale, alice,
                new LayingCreateRequest(null, NOW, 2, 2, null, null, null));
        Long hatchId = laying.hatches().get(0).hatchId();

        assertCode(() -> layingService.updateHatch(laying.layingId(), hatchId, alice,
                        new HatchUpdateRequest(NOW, null, bobPet, null)),
                ErrorCode.PET_ACCESS_DENIED);
        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM pet_relation_rls WHERE child_pet_id = ?", Long.class, bobPet)).isZero();
    }

    @Test
    void withdrawal_keeps_photos_of_matings_other_users_made() {
        Long alice = signup();
        Long bob = signup();
        Long aliceFemale = pet(alice, PetGender.FEMALE);
        Long bobMale = pet(bob, PetGender.MALE);
        Long bobFemale = pet(bob, PetGender.FEMALE);
        jdbc.update("UPDATE pet_mst SET private_yn = 'N' WHERE id = ?", bobMale);

        // 앨리스가 만든 메이팅(밥의 수컷 참여) — 밥이 탈퇴해도 앨리스의 기록이다
        Long aliceMating = matingService.createMating(aliceFemale, alice, mating(bobMale, aliceFemale)).matingId();
        photoService.registerPhoto(alice, register(EntityType.MATING, aliceMating,
                UploadKeys.newKey("matings/" + aliceMating + "/", "jpg")));
        // 밥이 만든 메이팅 — 탈퇴와 함께 사진도 지워져야 한다
        Long bobMating = matingService.createMating(bobFemale, bob, mating(bobMale, bobFemale)).matingId();
        photoService.registerPhoto(bob, register(EntityType.MATING, bobMating,
                UploadKeys.newKey("matings/" + bobMating + "/", "jpg")));

        authService.withdraw(bob, false);

        assertThat(matingPhotos(aliceMating)).isEqualTo(1);
        assertThat(matingPhotos(bobMating)).isZero();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM s3_delete_queue_dtl WHERE s3_key LIKE ?",
                Long.class, "matings/" + bobMating + "/%")).isPositive();
    }

    // -------------------------------------------------------------------------

    private long matingPhotos(Long matingId) {
        return jdbc.queryForObject(
                "SELECT count(*) FROM photo_dtl WHERE entity_type = 'MATING' AND entity_id = ?",
                Long.class, matingId);
    }

    private static void assertCode(org.assertj.core.api.ThrowableAssert.ThrowingCallable call, ErrorCode code) {
        assertThatThrownBy(call)
                .isInstanceOf(BusinessException.class)
                .extracting(e -> ((BusinessException) e).getErrorCode())
                .isEqualTo(code);
    }

    private static PhotoRegisterRequest register(EntityType type, Long id, String key) {
        return new PhotoRegisterRequest(type, id, key, null, null, null, null, null, null, null);
    }

    private static MatingCreateRequest mating(Long male, Long female) {
        return new MatingCreateRequest(male, female, male == null ? "외부 수컷" : null, NOW,
                null, null, null, null);
    }

    private static MatingUpdateRequest matingUpdate(Long male, Long female) {
        return new MatingUpdateRequest(male, female, null, NOW, null, null, null, null);
    }

    private Long pet(Long owner, PetGender gender) {
        return petService.create(owner, new PetCreateRequest(
                "개체" + SEQ.incrementAndGet(), speciesId, List.of(), gender, null, null, null, null,
                null, null, null, null, null, null, null, null)).id();
    }

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "upload" + n + "@example.com", "Passw0rd!23", "upload" + n, null,
                true, true, true, null, false, null)).id();
    }
}

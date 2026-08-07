package io.bitpet.pet;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.dto.UpdateMeRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.common.exception.ErrorCode;
import io.bitpet.pet.domain.PetGender;
import io.bitpet.pet.domain.PetMst;
import io.bitpet.pet.domain.RelationType;
import io.bitpet.pet.dto.GenealogyResponse;
import io.bitpet.pet.dto.PetCreateRequest;
import io.bitpet.pet.dto.PetRelationRequest;
import io.bitpet.pet.dto.PetResponse;
import io.bitpet.pet.repository.PetMstRepository;
import io.bitpet.pet.service.PetService;
import io.bitpet.pet.service.PetWithdrawalService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 회원 탈퇴 시 개체 처리 정책 검증.
 *
 * <p>물리 삭제가 섞여 있어 소프트 삭제 전제의 리포지토리 조회만으로는 확인이 안 된다.
 * 행이 정말 사라졌는지는 JdbcTemplate 로 직접 센다.
 */
class WithdrawalPetPolicyIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private AuthService authService;
    @Autowired private PetService petService;
    @Autowired private PetWithdrawalService withdrawalService;
    @Autowired private PetMstRepository petRepository;
    @Autowired private JdbcTemplate jdbc;

    // -------------------------------------------------------------------------

    @Test
    void 참조가_없으면_개체와_기록이_전부_사라진다() {
        Long owner = signup();
        Long father = createPet(owner, "아빠", PetGender.MALE);
        Long child  = createPet(owner, "새끼", PetGender.UNKNOWN);
        // 자기 개체끼리 연결 — 이걸 참조로 세면 개체가 통째로 남아 쓰레기가 된다
        petService.addRelation(owner, new PetRelationRequest(father, child, RelationType.FATHER));

        authService.withdraw(owner);

        assertThat(petRowCount(father)).isZero();
        assertThat(petRowCount(child)).isZero();
        assertThat(count("SELECT COUNT(*) FROM pet_relation_rls WHERE parent_pet_id = ?", father)).isZero();
        assertThat(count("SELECT COUNT(*) FROM weight_dtl WHERE pet_id = ?", father)).isZero();
        assertThat(count("SELECT COUNT(*) FROM pet_keeper_rls WHERE pet_id = ?", father)).isZero();
    }

    @Test
    void 남의_가계도가_참조하면_익명화되어_남는다() {
        Long owner   = signup();
        Long breeder = signup();
        Long father  = createPet(owner, "아빠", PetGender.MALE);
        Long child   = createPet(breeder, "남의새끼", PetGender.UNKNOWN);
        petService.addRelation(breeder, new PetRelationRequest(father, child, RelationType.FATHER));

        authService.withdraw(owner);

        PetMst orphan = petRepository.findById(father).orElseThrow();
        assertThat(orphan.getName()).isEqualTo("아빠");      // 혈통 식별의 핵심 — 반드시 남는다
        assertThat(orphan.getUserId()).isNull();
        assertThat(orphan.isOrphaned()).isTrue();
        // 사육 기록은 전부 지운다
        assertThat(count("SELECT COUNT(*) FROM weight_dtl WHERE pet_id = ?", father)).isZero();
        assertThat(count("SELECT COUNT(*) FROM pet_keeper_rls WHERE pet_id = ?", father)).isZero();
        // 남의 가계도는 그대로
        assertThat(count("SELECT COUNT(*) FROM pet_relation_rls WHERE parent_pet_id = ?", father)).isEqualTo(1);

        GenealogyResponse genealogy = petService.getGenealogy(breeder, child);
        assertThat(genealogy.parents()).hasSize(1);
        assertThat(genealogy.parents().get(0).name()).isEqualTo("아빠");
        assertThat(genealogy.parents().get(0).owner().isOrphaned()).isTrue();
    }

    @Test
    void 고아_개체는_부모로_새로_걸_수_없고_참조가_끊기면_배치가_지운다() {
        Long owner   = signup();
        Long breeder = signup();
        Long father  = createPet(owner, "아빠", PetGender.MALE);
        Long child   = createPet(breeder, "남의새끼", PetGender.UNKNOWN);
        petService.addRelation(breeder, new PetRelationRequest(father, child, RelationType.FATHER));
        authService.withdraw(owner);

        // 신규 참조 차단 — API 레벨에서 막아야 한다
        Long another = createPet(breeder, "다른새끼", PetGender.UNKNOWN);
        assertThatThrownBy(() ->
                petService.addRelation(breeder, new PetRelationRequest(father, another, RelationType.FATHER)))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode").isEqualTo(ErrorCode.PET_ORPHANED);

        // 부모 선택용 일련번호 검색에서도 빠진다
        String serial = jdbc.queryForObject("SELECT serial_no FROM pet_mst WHERE id = ?", String.class, father);
        assertThatThrownBy(() -> petService.findCardBySerial(breeder, serial))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode").isEqualTo(ErrorCode.PET_NOT_FOUND);

        // 참조가 남아 있는 동안은 배치가 손대지 않는다
        withdrawalService.cleanupUnreferencedOrphans(100);
        assertThat(petRowCount(father)).isEqualTo(1);

        // 마지막 참조가 끊기면 자연 소멸
        Long relationId = jdbc.queryForObject(
                "SELECT id FROM pet_relation_rls WHERE parent_pet_id = ?", Long.class, father);
        petService.deleteRelation(breeder, relationId);

        assertThat(withdrawalService.cleanupUnreferencedOrphans(100)).isEqualTo(1);
        assertThat(petRowCount(father)).isZero();
    }

    @Test
    void 닉네임_비공개면_비공개로_치환되고_userId를_내리지_않는다() {
        Long owner   = signup();
        Long breeder = signup();
        authService.updateMe(owner, new UpdateMeRequest(null, null, false));

        Long father = createPet(owner, "아빠", PetGender.MALE);
        Long child  = createPet(breeder, "남의새끼", PetGender.UNKNOWN);
        petService.addRelation(breeder, new PetRelationRequest(father, child, RelationType.FATHER));

        var parent = petService.getGenealogy(breeder, child).parents().get(0);
        assertThat(parent.owner().nickname()).isEqualTo("비공개");
        assertThat(parent.owner().userId()).isNull();
        assertThat(parent.owner().isOrphaned()).isFalse();   // 주인은 있다. 밝히지 않을 뿐이다
        assertThat(parent.name()).isEqualTo("아빠");          // 개체명은 항상 노출

        assertThatThrownBy(() -> petService.getUserProfile(breeder, owner))
                .isInstanceOf(BusinessException.class)
                .extracting("errorCode").isEqualTo(ErrorCode.USER_PROFILE_HIDDEN);
    }

    // -------------------------------------------------------------------------

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "withdraw" + n + "@example.com", "Passw0rd!23", "user" + n)).id();
    }

    private Long createPet(Long userId, String name, PetGender gender) {
        PetResponse res = petService.create(userId, new PetCreateRequest(
                name, null, null, gender, null, null, null, null, null, null, null,
                120.0, null, null));
        return res.id();
    }

    private int petRowCount(Long petId) {
        return count("SELECT COUNT(*) FROM pet_mst WHERE id = ?", petId);
    }

    private int count(String sql, Object arg) {
        Integer n = jdbc.queryForObject(sql, Integer.class, arg);
        return n == null ? 0 : n;
    }
}

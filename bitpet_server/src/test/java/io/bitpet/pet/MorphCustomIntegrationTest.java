package io.bitpet.pet;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.pet.domain.SpeciesCd;
import io.bitpet.pet.dto.MorphCdResponse;
import io.bitpet.pet.repository.SpeciesCdRepository;
import io.bitpet.pet.service.MorphService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 커스텀 모프(V7) — 카탈로그에 없는 조합 모프를 사용자가 직접 등록하는 경로.
 *
 * <p>핵심 불변식은 두 가지다:
 * <ol>
 *   <li>커스텀 모프는 <b>만든 사람에게만</b> 보인다 (공식 카탈로그는 모두에게 보인다)</li>
 *   <li>같은 종에 같은 이름을 또 넣어도 <b>행이 늘지 않는다</b>
 *       — {@code uq_morph_cd_species_name_ko} 가 있어 INSERT 가 실패하므로,
 *       서비스가 기존 행을 찾아 돌려주는 방식이어야 한다</li>
 * </ol>
 */
class MorphCustomIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Autowired private MorphService morphService;
    @Autowired private SpeciesCdRepository speciesRepository;
    @Autowired private AuthService authService;

    private Long speciesId;

    /**
     * 모프가 실제로 붙어 있는 종을 고른다.
     *
     * <p>species_cd 시드(R__01)에는 종이 많지만 morph_cd 시드(R__02)가 모프를 채워준 종은
     * 12종뿐이다. 그냥 첫 번째 종을 쓰면 "공식 카탈로그가 비어 있지 않다"는 전제가 깨진다.
     */
    @BeforeEach
    void setUp() {
        List<SpeciesCd> all = speciesRepository.findAllByIsActiveTrueOrderByDisplayOrderAsc();
        assertThat(all).as("종 시드가 적용되어 있어야 한다").isNotEmpty();

        speciesId = all.stream()
                .map(SpeciesCd::getId)
                .filter(id -> !morphService.listBySpecies(id, null).isEmpty())
                .findFirst()
                .orElseThrow(() -> new AssertionError("모프가 있는 종이 시드에 하나도 없다"));
    }

    @Test
    void custom_morph_is_visible_only_to_its_creator() {
        Long alice = signup();
        Long bob = signup();

        String name = "테스트조합모프" + SEQ.incrementAndGet();
        MorphCdResponse created = morphService.createCustom(speciesId, name, alice);

        assertThat(created.isUserDefined()).isTrue();
        assertThat(created.nameKo()).isEqualTo(name);

        assertThat(morphService.listBySpecies(speciesId, alice))
                .extracting(MorphCdResponse::nameKo)
                .contains(name);

        assertThat(morphService.listBySpecies(speciesId, bob))
                .extracting(MorphCdResponse::nameKo)
                .doesNotContain(name);

        // 비로그인 조회(GET /species/{id}/morphs 는 permitAll)에서도 안 보여야 한다.
        assertThat(morphService.listBySpecies(speciesId, null))
                .extracting(MorphCdResponse::nameKo)
                .doesNotContain(name);
    }

    @Test
    void official_catalog_stays_visible_to_everyone() {
        Long alice = signup();

        List<MorphCdResponse> anonymous = morphService.listBySpecies(speciesId, null);
        assertThat(anonymous).as("공식 카탈로그는 비로그인도 볼 수 있어야 한다").isNotEmpty();
        assertThat(anonymous).allMatch(m -> !m.isUserDefined());

        // 로그인 사용자는 공식 카탈로그를 하나도 잃지 않는다.
        assertThat(morphService.listBySpecies(speciesId, alice))
                .extracting(MorphCdResponse::nameKo)
                .containsAll(anonymous.stream().map(MorphCdResponse::nameKo).toList());
    }

    @Test
    void creating_same_name_twice_reuses_the_existing_morph() {
        Long alice = signup();
        String name = "중복조합모프" + SEQ.incrementAndGet();

        MorphCdResponse first = morphService.createCustom(speciesId, name, alice);
        MorphCdResponse second = morphService.createCustom(speciesId, name, alice);

        assertThat(second.id()).isEqualTo(first.id());
        assertThat(morphService.listBySpecies(speciesId, alice))
                .filteredOn(m -> m.nameKo().equals(name))
                .hasSize(1);
    }

    /**
     * 이름 앞뒤 공백만 다른 입력이 별개 모프로 쌓이면 목록이 순식간에 더러워진다.
     * 서비스가 trim 한 뒤 조회하므로 같은 행으로 합쳐져야 한다.
     */
    @Test
    void name_is_trimmed_before_lookup() {
        Long alice = signup();
        String name = "공백조합모프" + SEQ.incrementAndGet();

        MorphCdResponse first = morphService.createCustom(speciesId, name, alice);
        MorphCdResponse padded = morphService.createCustom(speciesId, "  " + name + "  ", alice);

        assertThat(padded.id()).isEqualTo(first.id());
    }

    /**
     * 공식 카탈로그와 이름이 겹치면 커스텀을 새로 만들지 않고 공식 모프를 그대로 돌려준다.
     * (uq_morph_cd_species_name_ko 때문에 행은 어차피 하나뿐이다)
     */
    @Test
    void name_colliding_with_official_catalog_returns_the_official_morph() {
        Long alice = signup();
        MorphCdResponse official = morphService.listBySpecies(speciesId, null).get(0);

        MorphCdResponse result = morphService.createCustom(speciesId, official.nameKo(), alice);

        assertThat(result.id()).isEqualTo(official.id());
        assertThat(result.isUserDefined()).as("공식 모프가 커스텀으로 바뀌면 안 된다").isFalse();
    }

    @Test
    void blank_name_is_rejected() {
        Long alice = signup();
        assertThatThrownBy(() -> morphService.createCustom(speciesId, "   ", alice))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void unknown_species_is_rejected() {
        Long alice = signup();
        assertThatThrownBy(() -> morphService.createCustom(999_999_999L, "아무모프", alice))
                .isInstanceOf(BusinessException.class);
    }

    @Test
    void autocomplete_matches_alias_list() {
        // 별칭 검색은 앱의 모프 선택 시트가 기대는 동작이다 ('핀스' → 핀스트라이프).
        // 어느 종이 걸릴지는 시드에 달렸으니, 별칭이 있는 모프를 찾아 그 별칭으로 조회한다.
        Long alice = signup();

        MorphCdResponse withAlias = speciesRepository.findAllByIsActiveTrueOrderByDisplayOrderAsc()
                .stream()
                .flatMap(s -> morphService.listBySpecies(s.getId(), null).stream())
                .filter(m -> m.aliasList() != null && !m.aliasList().isBlank())
                .findFirst()
                .orElse(null);

        assertThat(withAlias).as("alias_list 가 채워진 모프가 시드에 있어야 한다").isNotNull();

        String alias = withAlias.aliasList().split(",")[0].trim();
        assertThat(morphService.autocomplete(withAlias.speciesId(), alias, alice))
                .extracting(MorphCdResponse::id)
                .contains(withAlias.id());
    }

    // -------------------------------------------------------------------------

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "morph" + n + "@example.com", "Passw0rd!23", "morphuser" + n,
                true, true, true, false)).id();
    }
}

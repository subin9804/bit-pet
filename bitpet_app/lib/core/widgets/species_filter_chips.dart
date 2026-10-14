import 'package:flutter/material.dart';
import '../../features/pet/data/models/pet_models.dart';
import '../theme/app_dimens.dart';
import 'app_chip.dart';

/// 개체 목록 위에 얹는 **종 필터 칩 바**.
///
/// 칩은 넘겨받은 개체 목록에서 만든다 — 내가 **실제로 가진 종만** 뜨고,
/// 누르면 반드시 결과가 있다.
///
/// ⚠️ 전에는 화면마다 `('gecko','게코')`, `('snake','뱀')`, `('lizard','도마뱀')`
/// 셋을 하드코딩하고 `speciesName.contains('게코')` 로 걸렀다. 문제가 셋이었다:
///  1. 햄스터·크레스티드게코만 키우는 사람에게도 칩 넷이 떠 있고 둘은 빈 목록이었다.
///  2. 종 추가는 서버 코드표에서 일어나는데 앱이 이름 조각으로 알아맞히고 있었다
///     ('볼파이톤' 은 뱀 칩에 걸리지만 '사바나모니터' 는 어디에도 안 걸린다).
///  3. 같은 분류를 루틴 Step2 와 FAB 가 **서로 다른 키워드 목록**으로 판정했다.
/// 지금은 `speciesId` 하나로 판정한다 ('내 개체' 탭과 같은 방식).
class SpeciesFilterChips extends StatelessWidget {
  /// 칩을 뽑아낼 개체 목록 (등장 순서 유지, 중복 제거).
  final List<Pet> pets;

  /// 고른 종의 `speciesId`. null = 전체.
  final int? selectedSpeciesId;
  final ValueChanged<int?> onChanged;

  /// 칩에 마리 수를 같이 적는다.
  final bool showCount;

  const SpeciesFilterChips({
    super.key,
    required this.pets,
    required this.selectedSpeciesId,
    required this.onChanged,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    final species = <int, String>{};
    for (final p in pets) {
      species.putIfAbsent(p.speciesId, () => p.speciesName);
    }

    // 종이 하나뿐이면 칩 바는 '전체' + 그 종 하나가 되어 고를 것이 없다.
    if (species.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: AppChip.barHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          AppChip(
            label: '전체',
            count: showCount ? pets.length : null,
            selected: selectedSpeciesId == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          ...species.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppChip(
                label: e.value,
                count: showCount
                    ? pets.where((p) => p.speciesId == e.key).length
                    : null,
                selected: selectedSpeciesId == e.key,
                onTap: () => onChanged(e.key),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

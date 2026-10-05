import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/pet_models.dart';
import '../../providers/pet_provider.dart';
import 'pedigree_parent_card.dart';
import '../../../../core/theme/app_dimens.dart';

class PetInfoGrid extends ConsumerStatefulWidget {
  final Pet pet;
  final int petId;

  const PetInfoGrid({super.key, required this.pet, required this.petId});

  @override
  ConsumerState<PetInfoGrid> createState() => _PetInfoGridState();
}

class _PetInfoGridState extends ConsumerState<PetInfoGrid> {
  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final hatch = pet.hatchingDate;
    final precision = pet.hatchingDatePrecision;
    final approx = pet.hatchingDateApproximate;
    final adopt = pet.adoptionDate;
    final age   = _ageString(hatch, precision, approx);

    // 부모 카드는 소유자 정보(@닉네임 / 정보 없음)까지 같이 그려야 해서 가계도를 따로 읽는다.
    // Pet 안의 fatherName/motherName 은 이름뿐이라 남의 개체인지 알 수 없다.
    final genealogy = ref.watch(genealogyProvider(widget.petId));
    final father = genealogy.valueOrNull?.father;
    final mother = genealogy.valueOrNull?.mother;
    final hasParents = father != null || mother != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.brLg,
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          // 모프 — **한 줄 전체**를 쓴다. 2열 그리드의 반쪽에 두면 폭이 모자라
          // 모프 이름 하나가 단어 중간에서 잘려 다음 줄로 넘어간다
          // ('슈퍼 마카로니' → '슈퍼 마카로' / '니'). 칩이면 이름 단위로만 접힌다.
          _MorphRow(
            names: pet.morphs.isNotEmpty
                ? pet.morphs.map((m) => m.nameKo).toList()
                : (pet.morphName != null ? [pet.morphName!] : const []),
          ),
          const SizedBox(height: 12),
          // 2열 그리드 — 나이는 해칭일에서 계산되는 값이라 같은 줄에 둔다.
          Row(
            children: [
              _Cell(
                label: '해칭일',
                value: _fmtDate(hatch, precision),
                mono: true,
                chip: approx ? '부정확' : null,
              ),
              const SizedBox(width: 12),
              _Cell(label: '나이', value: age),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Cell(label: '입양일', value: _fmtDate(adopt), mono: true),
              const SizedBox(width: 12),
              // 짝이 없다. 빈 칸을 두어 '입양일' 이 왼쪽 열에 그대로 서 있게 한다 —
              // 없애면 혼자 전체 폭으로 퍼져 위아래 줄과 열이 어긋난다.
              const Expanded(child: SizedBox()),
            ],
          ),
          // 부모 — 등록된 부모가 있을 때만 영역을 그린다. 등록·수정은 전부
          // **개체 수정 폼의 '부모 개체' 단계** 하나로 모았다 (예전엔 여기 '수정' 아이콘과
          // 상단 더보기 '부모 등록'이 따로 있어 같은 일을 하는 입구가 셋이었다).
          // 가계도 로딩 중에도 숨긴다: '없음'을 잠깐 띄웠다 사라지는 것보다 늦게 나타나는 게 덜 거슬린다.
          if (hasParents) ...[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('부모', style: AppTextStyles.paleGridLabel),
                const SizedBox(height: 4),
                // 부·모는 **한 줄에 반씩**. 카드 하나가 썸네일 44 + 이름 한 줄뿐이라
                // 전체 폭을 주면 오른쪽 절반이 통째로 빈다. 한쪽만 등록돼 있어도
                // 빈 칸으로 짝을 채워 카드 폭을 고정한다 — 부모를 추가했을 때
                // 남아 있던 카드가 절반으로 줄어드는 게 더 어색하다.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: father != null
                            ? PedigreeParentCard(card: father)
                            : const SizedBox(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: mother != null
                            ? PedigreeParentCard(card: mother)
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime? d, [String precision = 'DAY']) {
    if (d == null) return '-';
    return precision == 'MONTH'
        ? '${d.year}.${d.month.toString().padLeft(2, '0')}'
        : '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  String _ageString(DateTime? hatch, [String precision = 'DAY', bool approx = false]) {
    if (hatch == null) return '-';
    final effective = precision == 'MONTH'
        ? DateTime(hatch.year, hatch.month, 15)
        : hatch;
    final now = DateTime.now();
    int months = (now.year - effective.year) * 12 + now.month - effective.month;
    if (months < 0) return '-';
    final y = months ~/ 12;
    final m = months % 12;
    final base = y == 0 ? '$m개월' : m == 0 ? '$y년' : '$y년 $m개월';
    return approx ? '약 $base' : base;
  }
}

/// 모프 한 줄. 여러 개여도 **이름 단위로만** 접힌다.
///
/// 칩은 표시 전용이라 테두리를 주지 않는다 — 이 화면에서 테두리 있는 둥근 박스는
/// 부모 카드처럼 누르면 어디론가 가는 것들이고, 모프는 아무 데도 가지 않는다.
class _MorphRow extends StatelessWidget {
  final List<String> names;
  const _MorphRow({required this.names});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('모프', style: AppTextStyles.paleGridLabel),
              const SizedBox(height: 6),
              if (names.isEmpty)
                Text('-', style: AppTextStyles.paleGridValue)
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: names
                      .map((n) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: const BoxDecoration(
                              color: AppColors.paleBgAlt,
                              borderRadius: AppRadius.brPill,
                            ),
                            child: Text(
                              n,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  final String? chip;

  const _Cell({required this.label, required this.value, this.mono = false, this.chip});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.paleGridLabel),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: mono
                      ? AppTextStyles.mono(13, FontWeight.w600)
                      : AppTextStyles.paleGridValue,
                ),
              ),
              if (chip != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.brMd,
                    color: AppColors.petPeach,
                    border: Border.all(color: AppColors.petPeachInk.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    chip!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.petPeachInk,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

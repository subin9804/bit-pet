import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/toast_message.dart';
import '../../data/models/pet_models.dart';
import '../../data/pet_repository.dart';
import '../../providers/pet_provider.dart';
import 'parent_pet_bottom_sheet.dart';
import 'pedigree_parent_card.dart';

class PetInfoGrid extends ConsumerStatefulWidget {
  final Pet pet;
  final int petId;

  const PetInfoGrid({super.key, required this.pet, required this.petId});

  @override
  ConsumerState<PetInfoGrid> createState() => _PetInfoGridState();
}

class _PetInfoGridState extends ConsumerState<PetInfoGrid> {
  void _openParentEdit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ParentEditSheet(
        petId: widget.petId,
        speciesId: widget.pet.speciesId,
        initialFather: widget.pet.fatherId != null
            ? _ParentInfo(
                relationId: widget.pet.fatherRelationId!,
                petId: widget.pet.fatherId!,
                name: widget.pet.fatherName!)
            : null,
        initialMother: widget.pet.motherId != null
            ? _ParentInfo(
                relationId: widget.pet.motherRelationId!,
                petId: widget.pet.motherId!,
                name: widget.pet.motherName!)
            : null,
      ),
    ).then((_) {
      // 시트가 닫히면 상세 데이터 새로 불러옴 (저장 여부 무관)
      ref.invalidate(petDetailProvider(widget.petId));
      ref.invalidate(genealogyProvider(widget.petId));
    });
  }

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
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          // 2열 그리드
          Row(
            children: [
              _Cell(
                label: '모프',
                value: pet.morphs.isNotEmpty
                    ? pet.morphs.map((m) => m.nameKo).join(', ')
                    : (pet.morphName ?? '-'),
              ),
              const SizedBox(width: 12),
              _Cell(
                label: '해칭일',
                value: _fmtDate(hatch, precision),
                mono: true,
                chip: approx ? '부정확' : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Cell(label: '입양일', value: _fmtDate(adopt), mono: true),
              const SizedBox(width: 12),
              _Cell(label: '나이',   value: age),
            ],
          ),
          const SizedBox(height: 12),
          // 부모 (전체폭 + 수정 버튼)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('부모', style: AppTextStyles.paleGridLabel),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openParentEdit,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit_outlined, size: 13, color: AppColors.paleInk3),
                        SizedBox(width: 3),
                        Text('수정',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.paleInk3)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              if (!hasParents)
                Text(
                  // 로딩 중에 '없음'을 띄우면 부모가 있는 개체도 잠깐 미등록처럼 보인다
                  genealogy.isLoading ? '불러오는 중…' : '등록된 부모 개체 없음',
                  style: AppTextStyles.paleGridValue.copyWith(
                      color: AppColors.paleInk2, fontStyle: FontStyle.italic),
                )
              else ...[
                if (father != null) PedigreeParentCard(card: father),
                if (father != null && mother != null) const SizedBox(height: 8),
                if (mother != null) PedigreeParentCard(card: mother),
              ],
            ],
          ),
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
          const SizedBox(height: 3),
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
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
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

// ── 부모 수정 바텀시트 ─────────────────────────────────────────────

class _ParentInfo {
  final int relationId;
  final int petId;
  final String name;
  const _ParentInfo({required this.relationId, required this.petId, required this.name});
}

class _ParentEditSheet extends ConsumerStatefulWidget {
  final int petId;
  final int speciesId;
  final _ParentInfo? initialFather;
  final _ParentInfo? initialMother;

  const _ParentEditSheet({
    required this.petId,
    required this.speciesId,
    required this.initialFather,
    required this.initialMother,
  });

  @override
  ConsumerState<_ParentEditSheet> createState() => _ParentEditSheetState();
}

class _ParentEditSheetState extends ConsumerState<_ParentEditSheet> {
  bool _saving = false;
  PetCard? _newFather;
  bool _clearFather = false;
  PetCard? _newMother;
  bool _clearMother = false;

  Future<void> _pickParent({required bool isFather}) async {
    final result = await showModalBottomSheet<PetCard>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParentPetBottomSheet(
        isFather: isFather,
        initialSelection: null,
        excludePetId: widget.petId,
        filterSpeciesId: widget.speciesId,
      ),
    );
    if (result != null) {
      setState(() {
        if (isFather) { _newFather = result; _clearFather = false; }
        else           { _newMother = result; _clearMother = false; }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(petRepositoryProvider);
    try {
      // 부 처리
      if (_clearFather && widget.initialFather != null) {
        await repo.deleteRelation(widget.initialFather!.relationId);
      } else if (_newFather != null) {
        if (widget.initialFather != null) {
          await repo.deleteRelation(widget.initialFather!.relationId);
        }
        await repo.addRelation(widget.petId, _newFather!.petId, 'FATHER');
      }
      // 모 처리
      if (_clearMother && widget.initialMother != null) {
        await repo.deleteRelation(widget.initialMother!.relationId);
      } else if (_newMother != null) {
        if (widget.initialMother != null) {
          await repo.deleteRelation(widget.initialMother!.relationId);
        }
        await repo.addRelation(widget.petId, _newMother!.petId, 'MOTHER');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ToastMessage.show(context, '저장 실패: $e', type: ToastType.warning);
      }
    }
  }

  String _fatherLabel() {
    if (_clearFather) return '미등록';
    if (_newFather != null) return _newFather!.name;
    return widget.initialFather?.name ?? '미등록';
  }

  String _motherLabel() {
    if (_clearMother) return '미등록';
    if (_newMother != null) return _newMother!.name;
    return widget.initialMother?.name ?? '미등록';
  }

  bool _hasFather() {
    if (_clearFather) return false;
    if (_newFather != null) return true;
    return widget.initialFather != null;
  }

  bool _hasMother() {
    if (_clearMother) return false;
    if (_newMother != null) return true;
    return widget.initialMother != null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paleBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 16),
              decoration: BoxDecoration(
                  color: AppColors.paleLine, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('PARENT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.paleInk2, letterSpacing: 0.4)),
                SizedBox(height: 3),
                Text('부모 개체 수정',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
                        color: AppColors.primary, letterSpacing: -0.4)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
            child: Column(
              children: [
                _ParentRow(
                  isFather: true,
                  label: _fatherLabel(),
                  hasValue: _hasFather(),
                  onPick: () => _pickParent(isFather: true),
                  onClear: _hasFather()
                      ? () => setState(() { _clearFather = true; _newFather = null; })
                      : null,
                ),
                const SizedBox(height: 12),
                _ParentRow(
                  isFather: false,
                  label: _motherLabel(),
                  hasValue: _hasMother(),
                  onPick: () => _pickParent(isFather: false),
                  onClear: _hasMother()
                      ? () => setState(() { _clearMother = true; _newMother = null; })
                      : null,
                ),
              ],
            ),
          ),
          // 버튼 행
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.paleLine),
                    ),
                    child: const Text('취소',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                            color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _saving ? null : _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _saving ? AppColors.paleLine : AppColors.primary,
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.paleBg))
                          : const Text('저장',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                                  color: AppColors.paleBg)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentRow extends StatelessWidget {
  final bool isFather;
  final String label;
  final bool hasValue;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _ParentRow({
    required this.isFather,
    required this.label,
    required this.hasValue,
    required this.onPick,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isFather ? AppColors.petSky : AppColors.petPeach,
            border: Border.all(
              color: (isFather ? AppColors.petSkyInk : AppColors.petCoralInk)
                  .withValues(alpha: 0.25),
            ),
          ),
          child: Center(
            child: Text(
              isFather ? '♂' : '♀',
              style: TextStyle(
                fontSize: 15,
                color: isFather ? AppColors.petSkyInk : AppColors.petCoralInk,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFather ? '부 (수컷)' : '모 (암컷)',
                style: const TextStyle(fontSize: 10, color: AppColors.paleInk3,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: hasValue ? AppColors.primary : AppColors.paleInk3,
                  fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onClear != null)
          GestureDetector(
            onTap: onClear,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.close, size: 16, color: AppColors.paleInk3),
            ),
          ),
        GestureDetector(
          onTap: onPick,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.paleBgAlt,
              border: Border.all(color: AppColors.paleLine),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, size: 13, color: AppColors.paleInk2),
                SizedBox(width: 4),
                Text('변경', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.paleInk2)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

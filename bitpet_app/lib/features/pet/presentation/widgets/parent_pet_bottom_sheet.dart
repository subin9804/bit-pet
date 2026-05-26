import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/pet_models.dart';
import '../../providers/pet_provider.dart';

/// 03d.png — 부모 개체 선택 바텀시트
///
/// [isFather] : true → 부(♂) 선택, false → 모(♀) 선택
/// [initialSelection] : 이미 연결된 개체
/// 팝 결과값: 선택된 [Pet] 또는 null (취소)
class ParentPetBottomSheet extends ConsumerStatefulWidget {
  final bool isFather;
  final Pet? initialSelection;

  const ParentPetBottomSheet({
    super.key,
    required this.isFather,
    this.initialSelection,
  });

  @override
  ConsumerState<ParentPetBottomSheet> createState() =>
      _ParentPetBottomSheetState();
}

class _ParentPetBottomSheetState
    extends ConsumerState<ParentPetBottomSheet> {
  final _searchCtrl = TextEditingController();
  Pet? _selectedPet;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedPet = widget.initialSelection;
    _searchCtrl.text = 'BP-';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _genderCode => widget.isFather ? 'MALE' : 'FEMALE';
  String get _genderLabel => widget.isFather ? '부 (♂)' : '모 (♀)';
  String get _genderKo => widget.isFather ? '수컷' : '암컷';

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petListProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildSearchField(),
          const SizedBox(height: 12),
          Expanded(
            child: petsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('개체 목록을 불러오지 못했어요')),
              data: _buildBody,
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  // ─── Section builders ─────────────────────────────────────────────────────

  Widget _buildHandle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SELECT PARENT', style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text('$_genderLabel 개체 선택', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              '일련번호 BP-YYYY-NNN 또는 이름·종으로 검색할 수 있어요',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );

  Widget _buildSearchField() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search, size: 20),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      );

  Widget _buildBody(List<Pet> allPets) {
    final q = _query.toLowerCase();
    final filtered = allPets.where((p) {
      if (p.gender != _genderCode) return false;
      if (q.isEmpty || q == 'bp-') return true;
      return p.name.toLowerCase().contains(q) ||
          p.serialNo.toLowerCase().contains(q) ||
          p.speciesName.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '등록된 $_genderKo 개체 ${filtered.length}마리',
            style: AppTextStyles.caption,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    '등록된 $_genderKo 개체가 없어요',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textDisabled),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _PetListCard(
                    pet: filtered[i],
                    isSelected:
                        _selectedPet?.id == filtered[i].id,
                    isFather: widget.isFather,
                    onTap: () =>
                        setState(() => _selectedPet = filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              // 취소
              SizedBox(
                width: 72,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              // 연결
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedPet == null
                      ? null
                      : () => Navigator.pop(context, _selectedPet),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    disabledBackgroundColor: AppColors.bg2,
                    disabledForegroundColor: AppColors.textDisabled,
                  ),
                  child: const Text('연결'),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Pet 카드 위젯 ────────────────────────────────────────────────────────────

class _PetListCard extends StatelessWidget {
  final Pet pet;
  final bool isSelected;
  final bool isFather;
  final VoidCallback onTap;

  const _PetListCard({
    required this.pet,
    required this.isSelected,
    required this.isFather,
    required this.onTap,
  });

  Color get _identityColor {
    if (pet.colorCode == null) return AppColors.bg2;
    try {
      return Color(
          int.parse(pet.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.bg2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // 프로필 이미지 (아이덴티티 컬러 배경)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _identityColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('🦎', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            // 개체 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          pet.name,
                          style: AppTextStyles.bodyBold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFather ? '♂' : '♀',
                        style: TextStyle(
                          fontSize: 13,
                          color: isFather
                              ? AppColors.male
                              : AppColors.female,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pet.serialNo,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textDisabled),
                  ),
                  Text(
                    pet.morphName != null
                        ? '${pet.speciesName} · ${pet.morphName}'
                        : pet.speciesName,
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

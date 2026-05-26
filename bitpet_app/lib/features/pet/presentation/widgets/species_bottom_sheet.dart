import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/pet_models.dart';
import '../../providers/pet_provider.dart';

/// 대분류 카테고리 순서 (백엔드 category 필드값 기준)
const _kCategoryOrder = [
  'GECKO',
  'LIZARD',
  'SNAKE',
  'TURTLE',
  'AMPHIBIAN',
  'OTHER',
];

/// 카테고리 → 한글 라벨
const _kCategoryLabels = {
  'GECKO': '게코',
  'LIZARD': '도마뱀',
  'SNAKE': '뱀',
  'TURTLE': '🐢 거북',
  'AMPHIBIAN': '🐸 양서류',
  'OTHER': '👾 기타',
};

/// 03c.png — 종 선택 바텀시트
///
/// [initialSelection] : 이미 선택된 종이 있을 경우 전달
/// 팝 결과값: 선택된 [Species] 또는 null (취소)
class SpeciesBottomSheet extends ConsumerStatefulWidget {
  final Species? initialSelection;
  const SpeciesBottomSheet({super.key, this.initialSelection});

  @override
  ConsumerState<SpeciesBottomSheet> createState() =>
      _SpeciesBottomSheetState();
}

class _SpeciesBottomSheetState extends ConsumerState<SpeciesBottomSheet> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = _kCategoryOrder.first;
  Species? _selectedSpecies;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedSpecies = widget.initialSelection;
    if (_selectedSpecies != null) {
      final cat = _selectedSpecies!.category.toUpperCase();
      if (_kCategoryOrder.contains(cat)) _selectedCategory = cat;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final speciesAsync = ref.watch(speciesListProvider);

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
          const SizedBox(height: 4),
          Expanded(
            child: speciesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('종 목록을 불러오지 못했어요')),
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
            Text('SELECT SPECIES', style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text('종 선택', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
              '카테고리에서 선택하거나 직접 검색하세요',
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
            hintText: '종 이름 검색...',
            prefixIcon: Icon(Icons.search, size: 20),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      );

  Widget _buildBody(List<Species> allSpecies) {
    // 카테고리별 그룹핑
    final Map<String, List<Species>> grouped = {};
    for (final s in allSpecies) {
      (grouped[s.category.toUpperCase()] ??= []).add(s);
    }

    // 검색 모드 → 평면 리스트
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      final filtered = allSpecies
          .where((s) =>
              s.nameKo.contains(_query) ||
              (s.nameEn?.toLowerCase().contains(q) ?? false))
          .toList();

      if (filtered.isEmpty) {
        return Center(
          child: Text('검색 결과가 없어요',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textDisabled)),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _SpeciesItem(
          species: filtered[i],
          isSelected: _selectedSpecies?.id == filtered[i].id,
          onTap: () => setState(() => _selectedSpecies = filtered[i]),
        ),
      );
    }

    // 카테고리 2단 레이아웃
    final categories =
        _kCategoryOrder.where((c) => grouped.containsKey(c)).toList();
    final currentSpecies = grouped[_selectedCategory] ?? [];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 좌측: 카테고리 탭
        SizedBox(
          width: 104,
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              final isSel = cat == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 14),
                  decoration: BoxDecoration(
                    color:
                        isSel ? AppColors.surface : Colors.transparent,
                    border: Border(
                      left: BorderSide(
                        color: isSel
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    _kCategoryLabels[cat] ?? cat,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: isSel
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isSel
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // 구분선
        Container(width: 1, color: AppColors.border),
        // 우측: 종 목록
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: currentSpecies.length,
            itemBuilder: (_, i) => _SpeciesItem(
              species: currentSpecies[i],
              isSelected:
                  _selectedSpecies?.id == currentSpecies[i].id,
              onTap: () =>
                  setState(() => _selectedSpecies = currentSpecies[i]),
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
              // 선택 확인
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedSpecies == null
                      ? null
                      : () =>
                          Navigator.pop(context, _selectedSpecies),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    disabledBackgroundColor: AppColors.bg2,
                    disabledForegroundColor: AppColors.textDisabled,
                  ),
                  child: Text(
                    _selectedSpecies == null
                        ? '선택'
                        : '선택  ${_selectedSpecies!.nameKo}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Private sub-widget ───────────────────────────────────────────────────────

class _SpeciesItem extends StatelessWidget {
  final Species species;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpeciesItem({
    required this.species,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                species.nameKo,
                style: AppTextStyles.body.copyWith(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

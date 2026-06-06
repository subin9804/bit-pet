import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/pet_models.dart';
import '../../providers/pet_provider.dart';

// ── subcategory 코드 → 한글 라벨 (ERD: G/L/C/S/T/F/N)
const _kSubcategoryLabels = <String, String>{
  'G': '게코',
  'L': '도마뱀',
  'C': '카멜레온',
  'S': '뱀',
  'T': '거북',
  'F': '개구리',
  'N': '도롱뇽',
};

// 레일 노출 순서
const _kSubcategoryOrder = ['G', 'L', 'C', 'S', 'T', 'F', 'N'];

/// 03c — 종 선택 바텀시트
///   흐름: subcategory 레일 탭 → 해당 subcategory의 종 목록 → 검색
///   팝 결과: 선택된 [Species] 또는 null(취소)
class SpeciesBottomSheet extends ConsumerStatefulWidget {
  final Species? initialSelection;
  const SpeciesBottomSheet({super.key, this.initialSelection});

  @override
  ConsumerState<SpeciesBottomSheet> createState() => _SpeciesBottomSheetState();
}

class _SpeciesBottomSheetState extends ConsumerState<SpeciesBottomSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _selectedSubcategory;
  Species? _selectedSpecies;

  @override
  void initState() {
    super.initState();
    _selectedSpecies = widget.initialSelection;
    // 이미 선택된 종의 subcategory로 초기 탭 설정
    final initSub = widget.initialSelection?.subcategory?.toUpperCase();
    if (initSub != null && _kSubcategoryLabels.containsKey(initSub)) {
      _selectedSubcategory = initSub;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── 검색 모드 판단
  bool get _isSearching => _query.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.87,
      decoration: const BoxDecoration(
        color: AppColors.paleBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildSearchField(),
          const SizedBox(height: 4),
          Expanded(child: _buildBody()),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── 드래그 핸들
  Widget _buildHandle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.paleLine,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  // ── 헤더
  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SELECT SPECIES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.paleInk3,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '종 선택',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedSpecies != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.paleBgAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.paleLine),
                ),
                child: Text(
                  _selectedSpecies!.nameKo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      );

  // ── 검색 필드
  Widget _buildSearchField() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.paleLine),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontSize: 14, color: AppColors.primary),
            decoration: const InputDecoration(
              hintText: '종 이름 검색…',
              hintStyle: TextStyle(color: AppColors.paleInk3, fontSize: 13),
              prefixIcon: Icon(Icons.search, size: 18, color: AppColors.paleInk2),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: InputBorder.none,
            ),
          ),
        ),
      );

  // ── 본문: 검색 모드 vs 2단 레이아웃
  Widget _buildBody() {
    if (_isSearching) return _buildSearchResults();
    return _buildTwoColumnLayout();
  }

  // ── 검색 결과 (전체 종 flat 리스트)
  Widget _buildSearchResults() {
    final allAsync = ref.watch(speciesListProvider);
    return allAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text('종 목록을 불러오지 못했어요',
            style: TextStyle(color: AppColors.paleInk3)),
      ),
      data: (all) {
        final q = _query.toLowerCase();
        final filtered = all.where((s) =>
            s.nameKo.contains(_query) ||
            (s.nameEn?.toLowerCase().contains(q) ?? false)).toList();
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              '"$_query" 검색 결과가 없어요',
              style: const TextStyle(color: AppColors.paleInk3, fontSize: 13),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _SpeciesRow(
            species: filtered[i],
            isSelected: _selectedSpecies?.id == filtered[i].id,
            onTap: () => setState(() => _selectedSpecies = filtered[i]),
          ),
        );
      },
    );
  }

  // ── 2단 레이아웃: 왼쪽 subcategory 레일 + 오른쪽 종 목록
  Widget _buildTwoColumnLayout() {
    final allAsync = ref.watch(speciesListProvider);

    return allAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(
        child: Text('종 목록을 불러오지 못했어요',
            style: TextStyle(color: AppColors.paleInk3)),
      ),
      data: (all) {
        // 전체 종에서 실제 존재하는 subcategory만 추출 (정해진 순서 유지)
        final presentSubs = _kSubcategoryOrder
            .where((s) => all.any((sp) => sp.subcategory?.toUpperCase() == s))
            .toList();

        // 초기 탭이 없으면 첫 번째로 설정
        final activeSub = (_selectedSubcategory != null &&
                presentSubs.contains(_selectedSubcategory))
            ? _selectedSubcategory!
            : (presentSubs.isNotEmpty ? presentSubs.first : null);

        if (activeSub != null && _selectedSubcategory != activeSub) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedSubcategory = activeSub);
          });
        }

        final currentSpecies = activeSub == null
            ? all
            : all.where((s) => s.subcategory?.toUpperCase() == activeSub).toList();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽: subcategory 레일
            _SubcategoryRail(
              subcategories: presentSubs,
              selected: activeSub,
              speciesCounts: {
                for (final s in presentSubs)
                  s: all.where((sp) => sp.subcategory?.toUpperCase() == s).length
              },
              onSelect: (s) => setState(() => _selectedSubcategory = s),
            ),
            // 구분선
            Container(width: 1, color: AppColors.paleLine),
            // 오른쪽: 종 목록
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: currentSpecies.length,
                itemBuilder: (_, i) => _SpeciesRow(
                  species: currentSpecies[i],
                  isSelected: _selectedSpecies?.id == currentSpecies[i].id,
                  onTap: () => setState(() => _selectedSpecies = currentSpecies[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── 하단 버튼
  Widget _buildFooter() => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.paleLineSoft)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.paleLine),
                    ),
                    child: const Center(
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.paleInk2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _selectedSpecies == null
                      ? null
                      : () => Navigator.pop(context, _selectedSpecies),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _selectedSpecies != null
                          ? AppColors.primary
                          : AppColors.paleLine,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        _selectedSpecies == null
                            ? '종을 선택하세요'
                            : '${_selectedSpecies!.nameKo} 선택',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _selectedSpecies != null
                              ? AppColors.paleBg
                              : AppColors.paleInk3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

// ── subcategory 레일 ────────────────────────────────────────────────────────

class _SubcategoryRail extends StatelessWidget {
  final List<String> subcategories;
  final String? selected;
  final Map<String, int> speciesCounts;
  final void Function(String) onSelect;

  const _SubcategoryRail({
    required this.subcategories,
    required this.selected,
    required this.speciesCounts,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: ListView.builder(
        itemCount: subcategories.length,
        itemBuilder: (_, i) {
          final sub = subcategories[i];
          final isSel = sub == selected;
          final label = _kSubcategoryLabels[sub] ?? sub;
          final count = speciesCounts[sub] ?? 0;

          return GestureDetector(
            onTap: () => onSelect(sub),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              decoration: BoxDecoration(
                color: isSel ? AppColors.surface : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isSel ? AppColors.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? AppColors.primary : AppColors.paleInk2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count종',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.paleInk3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── 종 행 ───────────────────────────────────────────────────────────────────

class _SpeciesRow extends StatelessWidget {
  final Species species;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpeciesRow({
    required this.species,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    species.nameKo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.paleBg : AppColors.primary,
                    ),
                  ),
                  if (species.nameEn != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      species.nameEn!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? AppColors.paleBg.withValues(alpha: 0.7)
                            : AppColors.paleInk3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, size: 16, color: AppColors.paleBg),
          ],
        ),
      ),
    );
  }
}

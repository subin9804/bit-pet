import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/models/pet_models.dart';
import '../providers/pet_provider.dart';
import '../../routine/data/models/routine_models.dart';
import '../../routine/data/routine_repository.dart';
import '../../routine/providers/routine_provider.dart';
import '../../routine/presentation/routine_screen.dart';

class PetListScreen extends ConsumerStatefulWidget {
  const PetListScreen({super.key});

  @override
  ConsumerState<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends ConsumerState<PetListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onAdd() {
    if (_tabController.index == 0) {
      context.push('/pets/new');
    } else {
      // 루틴 추가 — RoutineScreen에서 처리
      _showAddRoutineSheet();
    }
  }

  void _showAddRoutineSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddRoutineSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petListProvider);
    final routinesAsync = ref.watch(routineListProvider);
    final petCount = petsAsync.valueOrNull?.length ?? 0;
    final routineCount = routinesAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('manage',
                style: AppTextStyles.label.copyWith(
                    fontSize: 11,
                    color: AppColors.textDisabled,
                    letterSpacing: 1.5)),
            const Text('내 개체 관리'),
          ],
        ),
        titleSpacing: 20,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: Text(_tabController.index == 0 ? '추가' : '루틴'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                textStyle: AppTextStyles.bodyBold.copyWith(fontSize: 13),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.border.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textDisabled,
                labelStyle: AppTextStyles.bodyBold,
                unselectedLabelStyle: AppTextStyles.body,
                tabs: [
                  Tab(text: '개체  $petCount'),
                  Tab(text: '루틴  $routineCount'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PetTab(),
          RoutineScreen(),
        ],
      ),
    );
  }
}

// ── 개체 탭 ──────────────────────────────────────────────────────────────────

class _PetTab extends ConsumerStatefulWidget {
  const _PetTab();

  @override
  ConsumerState<_PetTab> createState() => _PetTabState();
}

class _PetTabState extends ConsumerState<_PetTab> {
  String _query = '';
  String? _selectedCategory;
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petListProvider);
    final speciesAsync = ref.watch(speciesListProvider);

    // 종 카테고리 추출
    final categories = speciesAsync.valueOrNull
            ?.map((s) => s.category)
            .toSet()
            .toList() ??
        [];

    return Column(
      children: [
        // 검색창
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: '이름 또는 종 검색...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              fillColor: AppColors.surface,
            ),
          ),
        ),
        // 필터칩 + 뷰 토글
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: '전체',
                      selected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(width: 8),
                    ...categories.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: c,
                          selected: _selectedCategory == c,
                          onTap: () =>
                              setState(() => _selectedCategory = c),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.grid_view,
                      color: _isGridView
                          ? AppColors.primary
                          : AppColors.textDisabled,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isGridView = true),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.list,
                      color: !_isGridView
                          ? AppColors.primary
                          : AppColors.textDisabled,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isGridView = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // 개체 목록
        Expanded(
          child: petsAsync.when(
            loading: () => const SkeletonCardList(),
            error: (e, _) => EmptyState(
              message: '불러오기 실패',
              subMessage: e.toString(),
              icon: Icons.error_outline,
              actionLabel: '다시 시도',
              onAction: () => ref.read(petListProvider.notifier).load(),
            ),
            data: (allPets) {
              // 검색 + 필터 적용
              final pets = allPets.where((p) {
                final matchQuery = _query.isEmpty ||
                    p.name
                        .toLowerCase()
                        .contains(_query.toLowerCase()) ||
                    p.speciesName
                        .toLowerCase()
                        .contains(_query.toLowerCase());
                // 종 카테고리 필터는 species 정보 필요 — 현재 Pet 모델에 category 없음
                // speciesName으로 대신 필터
                final matchCategory = _selectedCategory == null;
                return matchQuery && matchCategory;
              }).toList();

              if (pets.isEmpty) {
                return EmptyState(
                  message: '개체가 없어요',
                  icon: Icons.pets,
                  actionLabel: '개체 등록',
                  onAction: () => context.push('/pets/new'),
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(petListProvider.notifier).load(),
                child: _isGridView
                    ? _PetGrid(pets: pets)
                    : _PetListView(pets: pets),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── 개체 그리드 ──────────────────────────────────────────────────────────────

class _PetGrid extends StatelessWidget {
  final List<Pet> pets;
  const _PetGrid({required this.pets});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: pets.length,
      itemBuilder: (_, i) => _PetCard(pet: pets[i]),
    );
  }
}

// ── 개체 카드 (그리드) ────────────────────────────────────────────────────────

class _PetCard extends StatelessWidget {
  final Pet pet;
  const _PetCard({required this.pet});

  Color get _bgColor {
    if (pet.colorCode == null) return AppColors.petColorMint;
    try {
      return Color(int.parse(pet.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.petColorMint;
    }
  }

  IconData get _genderIcon => switch (pet.gender) {
        'MALE' => Icons.male,
        'FEMALE' => Icons.female,
        _ => Icons.question_mark,
      };

  Color get _genderColor => switch (pet.gender) {
        'MALE' => AppColors.male,
        'FEMALE' => AppColors.female,
        _ => AppColors.textDisabled,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/pets/${pet.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사진 영역
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14)),
                    ),
                    child: pet.profileImageUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14)),
                            child: Image.network(
                              pet.profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _spriteIcon(),
                            ),
                          )
                        : _spriteIcon(),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_genderIcon,
                          size: 14, color: _genderColor),
                    ),
                  ),
                ],
              ),
            ),
            // 정보 영역
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.name,
                        style: AppTextStyles.bodyBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(pet.speciesName,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pet.latestWeightG != null
                                ? '${pet.latestWeightG!.toStringAsFixed(0)}g'
                                : '',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textDisabled),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spriteIcon() {
    return Center(
      child: Icon(Icons.pets,
          size: 48, color: AppColors.primary.withValues(alpha: 0.3)),
    );
  }
}

// ── 개체 리스트 뷰 ────────────────────────────────────────────────────────────

class _PetListView extends StatelessWidget {
  final List<Pet> pets;
  const _PetListView({required this.pets});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final pet = pets[i];
        return ListTile(
          onTap: () => context.push('/pets/${pet.id}'),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tileColor: AppColors.surface,
          leading: _PetAvatarSmall(pet: pet),
          title:
              Text(pet.name, style: AppTextStyles.bodyBold),
          subtitle: Text(pet.speciesName, style: AppTextStyles.caption),
          trailing: pet.latestWeightG != null
              ? Text(
                  '${pet.latestWeightG!.toStringAsFixed(0)}g',
                  style: AppTextStyles.caption,
                )
              : null,
        );
      },
    );
  }
}

class _PetAvatarSmall extends StatelessWidget {
  final Pet pet;
  const _PetAvatarSmall({required this.pet});

  Color get _color {
    if (pet.colorCode == null) return AppColors.petColorMint;
    try {
      return Color(int.parse(pet.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.petColorMint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
      child: pet.profileImageUrl != null
          ? ClipOval(
              child: Image.network(pet.profileImageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.pets, color: AppColors.primary.withValues(alpha: 0.4), size: 22)))
          : Icon(Icons.pets,
              color: AppColors.primary.withValues(alpha: 0.4), size: 22),
    );
  }
}

// ── 필터 칩 ──────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── 루틴 추가 바텀시트 (placeholder) ─────────────────────────────────────────

class _AddRoutineSheet extends ConsumerStatefulWidget {
  const _AddRoutineSheet();

  @override
  ConsumerState<_AddRoutineSheet> createState() => _AddRoutineSheetState();
}

class _AddRoutineSheetState extends ConsumerState<_AddRoutineSheet> {
  final _titleController = TextEditingController();
  RoutineTypeSelection _type = RoutineTypeSelection.feeding;
  int _cycleDays = 1;
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('루틴 추가', style: AppTextStyles.title),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: '루틴 이름'),
              ),
              const SizedBox(height: 12),
              // 타입 선택
              Row(
                children: RoutineTypeSelection.values.map((t) {
                  final selected = _type == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: t.label,
                      selected: selected,
                      onTap: () => setState(() => _type = t),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // 주기
              Row(
                children: [
                  Text('주기: ', style: AppTextStyles.body),
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: () => setState(() {
                      if (_cycleDays > 1) _cycleDays--;
                    }),
                  ),
                  Text('$_cycleDays일',
                      style: AppTextStyles.bodyBold),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () =>
                        setState(() => _cycleDays++),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('루틴 추가'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final routineType = switch (_type) {
        RoutineTypeSelection.feeding => RoutineType.FEEDING,
        RoutineTypeSelection.cleaning => RoutineType.CLEANING,
        RoutineTypeSelection.weight => RoutineType.WEIGHT,
        RoutineTypeSelection.custom => RoutineType.CUSTOM,
      };
      await ref.read(routineRepositoryProvider).createRoutine(
            CreateRoutineRequest(
              routineType: routineType,
              title: _titleController.text.trim(),
              cycleDays: _cycleDays,
            ),
          );
      ref.read(routineListProvider.notifier).load();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // 오류 처리 — 간단히 무시
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

enum RoutineTypeSelection {
  feeding('피딩'),
  cleaning('청소'),
  weight('체중'),
  custom('사용자');

  final String label;
  const RoutineTypeSelection(this.label);
}

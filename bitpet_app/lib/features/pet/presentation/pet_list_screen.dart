import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/models/pet_models.dart';
import '../providers/pet_provider.dart';

class PetListScreen extends ConsumerWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => context.push('/pets/bulk-new'),
              icon: const Icon(Icons.library_add_outlined, size: 15),
              label: const Text('일괄'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.paleInk2,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/pets/new'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('추가'),
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
      ),
      body: const _PetTab(),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: '이름 또는 종 검색...',
              prefixIcon: Icon(Icons.search, size: 20),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    AppChip(
                      label: '전체',
                      selected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(width: 8),
                    ...categories.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AppChip(
                          label: c,
                          selected: _selectedCategory == c,
                          onTap: () => setState(() => _selectedCategory = c),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.grid_view,
                        color: _isGridView
                            ? AppColors.primary
                            : AppColors.textDisabled,
                        size: 20),
                    onPressed: () => setState(() => _isGridView = true),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: Icon(Icons.list,
                        color: !_isGridView
                            ? AppColors.primary
                            : AppColors.textDisabled,
                        size: 20),
                    onPressed: () => setState(() => _isGridView = false),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
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
              final pets = allPets.where((p) {
                final matchQuery = _query.isEmpty ||
                    p.name.toLowerCase().contains(_query.toLowerCase()) ||
                    p.speciesName
                        .toLowerCase()
                        .contains(_query.toLowerCase());
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
                onRefresh: () => ref.read(petListProvider.notifier).load(),
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
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _bgColor,
                    ),
                    child: pet.profileImageUrl != null
                        ? Image.network(pet.profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _spriteIcon())
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
                      child: Icon(_genderIcon, size: 14, color: _genderColor),
                    ),
                  ),
                ],
              ),
            ),
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
                    if (pet.latestWeightG != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${pet.latestWeightG!.toStringAsFixed(0)}g',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textDisabled),
                        ),
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

  Widget _spriteIcon() => Center(
      child: Icon(Icons.pets,
          size: 48, color: AppColors.primary.withValues(alpha: 0.3)));
}

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
          shape: const RoundedRectangleBorder(
              side: BorderSide(color: AppColors.border)),
          tileColor: AppColors.surface,
          leading: _PetAvatarSmall(pet: pet),
          title: Text(pet.name, style: AppTextStyles.bodyBold),
          subtitle: Text(pet.speciesName, style: AppTextStyles.caption),
          trailing: pet.latestWeightG != null
              ? Text('${pet.latestWeightG!.toStringAsFixed(0)}g',
                  style: AppTextStyles.caption)
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
                  errorBuilder: (_, __, ___) => Icon(Icons.pets,
                      color: AppColors.primary.withValues(alpha: 0.4),
                      size: 22)))
          : Icon(Icons.pets,
              color: AppColors.primary.withValues(alpha: 0.4), size: 22),
    );
  }
}


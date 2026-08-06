import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/pet_models.dart';
import '../providers/pet_provider.dart';
import '../share/data/models/share_models.dart';
import '../share/presentation/bulk_share_sheet.dart';

/// 개체 다중 선택 모드 on/off (함께 키우기·분양 보내기용)
final petSelectionModeProvider = StateProvider.autoDispose<bool>((_) => false);

/// 선택된 개체 id 집합
final selectedPetIdsProvider = StateProvider.autoDispose<Set<int>>((_) => {});

void _togglePet(WidgetRef ref, int id) {
  final set = {...ref.read(selectedPetIdsProvider)};
  if (!set.add(id)) set.remove(id);
  ref.read(selectedPetIdsProvider.notifier).state = set;
}

void _exitSelection(WidgetRef ref) {
  ref.read(petSelectionModeProvider.notifier).state = false;
  ref.read(selectedPetIdsProvider.notifier).state = {};
}

/// 롱프레스 등으로 선택 모드에 바로 진입하며 해당 개체를 선택.
///
/// 공유받은 개체(KEEPER)는 공유·분양·삭제 어느 것도 소유자만 할 수 있어
/// 선택 모드에서 아예 목록에 나오지 않는다. 그 개체를 길게 눌러 선택 모드로
/// 들어가면 방금 누른 카드가 사라져 버리므로, 진입시키지 않고 이유만 알린다.
void _enterSelectionWith(BuildContext context, WidgetRef ref, Pet pet) {
  if (!pet.isOwner) {
    showToast(context, '공유받은 개체는 분양·삭제할 수 없어요. 소유자만 가능합니다.',
        type: ToastType.info);
    return;
  }
  ref.read(petSelectionModeProvider.notifier).state = true;
  ref.read(selectedPetIdsProvider.notifier).state = {pet.id};
}

/// 선택한 개체 일괄 삭제 — 확인 모달을 거쳐 `DELETE /api/v1/pets` 한 번으로 처리한다.
///
/// 서버가 전부 성공 아니면 전부 실패로 처리하므로, 실패하면 목록은 그대로 두고
/// 선택 모드도 유지한다 — 사용자가 선택을 고쳐 다시 시도할 수 있어야 한다.
Future<void> _confirmAndDelete(
    BuildContext context, WidgetRef ref, int count) async {
  final ids = ref.read(selectedPetIdsProvider).toList();
  if (ids.isEmpty) return;

  final ok = await ConfirmModal.show(
    context,
    title: '개체 삭제',
    message: '정말로 $count마리의 개체 정보를 삭제하시겠습니까?\n'
        '급여·체중 등 그동안의 기록도 함께 사라지며 복구할 수 없습니다.',
    confirmLabel: '삭제',
    isDangerous: true,
  );
  if (!ok) return;

  try {
    await ref.read(petListProvider.notifier).removeAll(ids);
    _exitSelection(ref);
    if (context.mounted) {
      showToast(context, '${ids.length}마리를 삭제했습니다.', type: ToastType.info);
    }
  } catch (e) {
    if (context.mounted) {
      showToast(context, '삭제에 실패했습니다. $e', type: ToastType.error);
    }
  }
}

class PetListScreen extends ConsumerWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selecting = ref.watch(petSelectionModeProvider);
    final selectedCount = ref.watch(selectedPetIdsProvider).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: selecting
          ? _selectionAppBar(context, ref, selectedCount)
          : _normalAppBar(context, ref),
      body: const _PetTab(),
      bottomNavigationBar:
          selecting ? const _ShareActionBar() : null,
    );
  }

  PreferredSizeWidget _normalAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
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
        TextButton.icon(
          onPressed: () =>
              ref.read(petSelectionModeProvider.notifier).state = true,
          icon: const Icon(Icons.group_add, size: 15),
          label: const Text('공유·분양'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: () => context.push('/pets/bulk-new'),
          icon: const Icon(Icons.library_add_outlined, size: 19),
          color: AppColors.paleInk2,
          tooltip: '개체 일괄 등록',
          visualDensity: VisualDensity.compact,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 0),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/pets/new'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('추가'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              textStyle: AppTextStyles.bodyBold.copyWith(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _selectionAppBar(
      BuildContext context, WidgetRef ref, int count) {
    return AppBar(
      backgroundColor: AppColors.bg,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _exitSelection(ref),
      ),
      title: Text(count == 0 ? '개체 선택' : '$count마리 선택됨'),
      titleSpacing: 0,
      actions: [
        IconButton(
          onPressed:
              count == 0 ? null : () => _confirmAndDelete(context, ref, count),
          icon: const Icon(Icons.delete_outline, size: 21),
          color: AppColors.error,
          disabledColor: AppColors.textDisabled,
          tooltip: '선택한 개체 삭제',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(28),
        child: Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            '함께 키우거나 분양·삭제할 개체를 선택하세요',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ── 하단 공유 액션바 (선택 모드) ────────────────────────────────────────────

class _ShareActionBar extends ConsumerWidget {
  const _ShareActionBar();

  Future<void> _startShare(
      BuildContext context, WidgetRef ref, ShareInviteType type) async {
    final ids = ref.read(selectedPetIdsProvider).toList();
    if (ids.isEmpty) return;
    final ok = await showBulkShareSheet(context, petIds: ids, inviteType: type);
    if (ok == true) {
      _exitSelection(ref);
      ref.read(petListProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSelection = ref.watch(selectedPetIdsProvider).isNotEmpty;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.paleLine)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SelectionAction(
                icon: Icons.group_add_outlined,
                label: '함께 키우기',
                enabled: hasSelection,
                onTap: () => _startShare(context, ref, ShareInviteType.share),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SelectionAction(
                icon: Icons.swap_horiz,
                label: '분양 보내기',
                enabled: hasSelection,
                // 분양은 '경고'가 아니라 소유권이 넘어가는 다른 성격의 동작이다.
                // 기존의 채도 높은 error 레드는 앱 팔레트에서 혼자 튀었고,
                // 삭제와 같은 위험 신호로도 읽혔다 → 팔레트 안의 코랄 톤으로.
                bg: AppColors.petCoral,
                fg: AppColors.petCoralInk,
                onTap: () =>
                    _startShare(context, ref, ShareInviteType.transfer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 선택 모드 하단 액션 버튼 — 앱 공통 톤(각진 모서리·팔레트 색·1px 라인)
class _SelectionAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  /// 채움색. 없으면 카드색 + 프라이머리 테두리(보조 액션)
  final Color? bg;
  final Color? fg;

  const _SelectionAction({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.bg,
    this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final filled = bg != null;
    final content = enabled
        ? (fg ?? AppColors.primary)
        : AppColors.textDisabled;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? bg : AppColors.card,
            border: Border.all(
              color: filled
                  ? (fg ?? AppColors.primary).withValues(alpha: 0.28)
                  : (enabled ? AppColors.primary : AppColors.paleLine),
            ),
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: content),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: content)),
            ],
          ),
        ),
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
  int? _selectedSpeciesId;
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petListProvider);
    final selecting = ref.watch(petSelectionModeProvider);

    // 내 개체에 실제로 존재하는 종만 필터칩으로 노출 (등장 순서 유지, 중복 제거)
    final allPets = petsAsync.valueOrNull ?? const <Pet>[];
    final speciesChips = <int, String>{};
    for (final p in allPets) {
      speciesChips.putIfAbsent(p.speciesId, () => p.speciesName);
    }

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
          height: AppChip.barHeight,
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    AppChip(
                      label: '전체',
                      selected: _selectedSpeciesId == null,
                      onTap: () => setState(() => _selectedSpeciesId = null),
                    ),
                    const SizedBox(width: 8),
                    ...speciesChips.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AppChip(
                          label: e.value,
                          selected: _selectedSpeciesId == e.key,
                          onTap: () =>
                              setState(() => _selectedSpeciesId = e.key),
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
                final matchCategory = _selectedSpeciesId == null ||
                    p.speciesId == _selectedSpeciesId;
                // 공유·분양·삭제는 전부 소유자(OWNER) 전용이다.
                // 선택 모드에서는 어차피 아무것도 할 수 없는 개체를 띄워
                // 고르게 한 뒤 403을 돌려주느니, 처음부터 빼고 보여준다.
                final selectable = !selecting || p.isOwner;
                return matchQuery && matchCategory && selectable;
              }).toList();

              // 필터 때문이 아니라 '공유받아서' 사라진 개체는 이유를 알려준다
              final hiddenShared = selecting
                  ? allPets.where((p) => !p.isOwner).length
                  : 0;

              if (pets.isEmpty) {
                return selecting
                    ? const EmptyState(
                        message: '분양·삭제할 수 있는 개체가 없어요',
                        subMessage: '공유받은 개체는 소유자만 관리할 수 있습니다.',
                        icon: Icons.group_outlined,
                      )
                    : EmptyState(
                        message: '개체가 없어요',
                        icon: Icons.pets,
                        actionLabel: '개체 등록',
                        onAction: () => context.push('/pets/new'),
                      );
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(petListProvider.notifier).load(),
                child: Column(
                  children: [
                    if (hiddenShared > 0) _SharedHiddenNotice(hiddenShared),
                    Expanded(
                      child: _isGridView
                          ? _PetGrid(pets: pets)
                          : _PetListView(pets: pets),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 선택 모드에서 공유받은 개체가 목록에서 빠졌음을 알리는 한 줄 안내.
/// 없으면 개체가 그냥 사라진 것처럼 보인다.
class _SharedHiddenNotice extends StatelessWidget {
  final int count;
  const _SharedHiddenNotice(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.paleBgAlt,
        border: Border.all(color: AppColors.paleLineSoft),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: AppColors.paleInk3),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '공유받은 $count마리는 소유자만 관리할 수 있어 목록에서 뺐어요.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.paleInk2, height: 1.3),
            ),
          ),
        ],
      ),
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

class _PetCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final selecting = ref.watch(petSelectionModeProvider);
    final selected = ref.watch(selectedPetIdsProvider).contains(pet.id);

    return GestureDetector(
      onTap: selecting
          ? () => _togglePet(ref, pet.id)
          : () => context.push('/pets/${pet.id}'),
      onLongPress:
          selecting ? null : () => _enterSelectionWith(context, ref, pet),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
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
                  if (selecting)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _CheckBadge(selected: selected),
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

/// 선택 모드 체크 배지
class _CheckBadge extends StatelessWidget {
  final bool selected;
  const _CheckBadge({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(
            color: selected ? AppColors.primary : AppColors.textDisabled,
            width: 1.5),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
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
      itemBuilder: (_, i) => _PetListTile(pet: pets[i]),
    );
  }
}

class _PetListTile extends ConsumerWidget {
  final Pet pet;
  const _PetListTile({required this.pet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selecting = ref.watch(petSelectionModeProvider);
    final selected = ref.watch(selectedPetIdsProvider).contains(pet.id);

    return ListTile(
      onTap: selecting
          ? () => _togglePet(ref, pet.id)
          : () => context.push('/pets/${pet.id}'),
      onLongPress:
          selecting ? null : () => _enterSelectionWith(context, ref, pet),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
          side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1)),
      tileColor: AppColors.surface,
      leading: selecting
          ? _CheckBadge(selected: selected)
          : _PetAvatarSmall(pet: pet),
      title: Text(pet.name, style: AppTextStyles.bodyBold),
      subtitle: Text(pet.speciesName, style: AppTextStyles.caption),
      trailing: pet.latestWeightG != null
          ? Text('${pet.latestWeightG!.toStringAsFixed(0)}g',
              style: AppTextStyles.caption)
          : null,
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


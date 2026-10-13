import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/db/ui_prefs.dart';
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
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/underline_tabs.dart';
import '../../../core/widgets/sex_icon.dart';
import '../../record/presentation/laying/egg_tab.dart';

/// '내 개체' 화면의 탭 — 0 개체 / 1 알(클러치).
///
/// 알은 개체에 매달린 기록이지만 "지금 품고 있는 알"은 개체를 하나씩 열어보는
/// 성질이 아니라 한 줄로 훑는 성질이라, 개체 상세 안에만 두면 매일 확인할 수가 없다.
///
/// **기본은 언제나 '개체'다.** autoDispose 라서 이 화면을 떠나면(하단 탭 이동) 값이
/// 폐기되고 다시 들어올 때 0 으로 시작한다 — '내 개체'를 열었는데 알 목록이 떠 있으면
/// 자기가 뭘 보고 있는지부터 헷갈린다. 개체 상세로 push 하는 동안은 이 화면이 트리에
/// 남아 있어 구독이 유지되므로, 돌아오면 보던 탭 그대로다(작업 중간이 끊기지 않는다).
final petScreenTabProvider = StateProvider.autoDispose<int>((_) => 0);

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
    // 선택 모드(공유·분양)는 개체에만 있는 동작이라 그 동안은 탭을 감춘다.
    final tab = selecting ? 0 : ref.watch(petScreenTabProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: selecting
          ? _selectionAppBar(context, ref, selectedCount)
          : _normalAppBar(context, ref, tab),
      body: selecting
          ? const _PetTab()
          : Column(
              children: [
                AppUnderlineTabs(
                  labels: const ['개체', '알'],
                  index: tab,
                  onChanged: (i) =>
                      ref.read(petScreenTabProvider.notifier).state = i,
                ),
                // IndexedStack — 탭을 왕복할 때마다 목록을 다시 불러오지 않는다.
                Expanded(
                  child: IndexedStack(
                    index: tab,
                    children: const [_PetTab(), EggTab()],
                  ),
                ),
              ],
            ),
      bottomNavigationBar:
          selecting ? const _ShareActionBar() : null,
    );
  }

  /// [tab] 이 '알' 이면 개체 전용 동작(공유·분양, 일괄 등록, 추가)을 내린다 —
  /// 알 탭의 추가는 '＋ 산란 등록' 하나뿐이고 그건 탭 안에 있다.
  PreferredSizeWidget _normalAppBar(
      BuildContext context, WidgetRef ref, int tab) {
    if (tab != 0) {
      return AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('내 개체'),
        titleSpacing: AppSpacing.xl,
      );
    }
    return AppBar(
      // ⚠️ 흰 AppBar + 연회색 본문이면 머리만 다른 색으로 떠 있어 경계선이
      // 생긴다 — 한 화면이 두 장으로 쪼개져 보였다. 헤더도 바탕색으로.
      backgroundColor: AppColors.canvas,
      // 제목 위에 영문 소제목('manage', 12px/자간 1.5)을 얹고 있었다.
      // 홈 헤더에서 걷어낸 것과 같은 종류의 장식이다 — 두 줄짜리 제목이 되어
      // AppBar 만 높아지고, 읽을 정보는 아래 한 줄뿐이다. 내비 라벨과 같은 말로.
      title: const Text('내 개체'),
      titleSpacing: AppSpacing.xl,
      actions: [
        TextButton.icon(
          onPressed: () =>
              ref.read(petSelectionModeProvider.notifier).state = true,
          icon: const Icon(Icons.group_add, size: 16),
          label: const Text('공유·분양'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ink2,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            textStyle:
                AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: () => context.push('/pets/bulk-new'),
          icon: const Icon(Icons.library_add_outlined, size: AppIconSize.md),
          color: AppColors.ink3,
          tooltip: '개체 일괄 등록',
          visualDensity: VisualDensity.compact,
        ),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xl, left: 0),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/pets/new'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('추가'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandAction,
              foregroundColor: AppColors.bg,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: 0),
              textStyle:
                  AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _selectionAppBar(
      BuildContext context, WidgetRef ref, int count) {
    return AppBar(
      backgroundColor: AppColors.canvas,
      leading: IconButton(
        tooltip: '선택 모드 끝내기',
        icon: const Icon(Icons.close),
        onPressed: () => _exitSelection(ref),
      ),
      title: Text(count == 0 ? '개체 선택' : '$count마리 선택됨'),
      titleSpacing: 0,
      actions: [
        IconButton(
          onPressed:
              count == 0 ? null : () => _confirmAndDelete(context, ref, count),
          icon: const Icon(Icons.delete_outline, size: AppIconSize.md),
          color: AppColors.error,
          disabledColor: AppColors.ink3,
          tooltip: '선택한 개체 삭제',
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(28),
        child: Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
          child: Text(
            '함께 키우거나 분양·삭제할 개체를 선택하세요',
            style: AppTextStyles.caption,
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
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
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
    // ⚠️ 비워둔 쪽(함께 키우기)의 기본색이 `primary` 였다 — 이 토큰은 초록이
    // 아니라 **먹색**이라 테두리·글씨가 검게 찍혀 옆의 코랄(분양)보다 무거워
    // 보였다. 보조 액션이지만 '권하는' 동작이므로 브랜드 틴트 계열로 간다.
    final content = enabled
        ? (fg ?? AppColors.brandTintInk)
        : AppColors.ink3;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? bg : AppColors.surface,
            border: Border.all(
              color: filled
                  ? (fg ?? AppColors.brandTintInk).withValues(alpha: 0.28)
                  : (enabled ? AppColors.brandAction : AppColors.line),
            ),
            borderRadius: AppRadius.brMd,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppIconSize.md, color: content),
              const SizedBox(width: AppSpacing.sm),
              Text(label,
                  style: AppTextStyles.bodyBold.copyWith(color: content)),
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

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petListProvider);
    final selecting = ref.watch(petSelectionModeProvider);

    // 보기 방식은 화면 state 가 아니라 기기에 남는 설정이다. 전에는 로컬
    // state 라서 탭을 벗어나기만 해도 2열로 돌아갔는데, 1열로 보는 사람은
    // **매번 다시 눌러야 했다**. 고른 쪽이 그대로 있어야 고른 의미가 있다.
    final isGridView = ref.watch(petListGridProvider);

    // 내 개체에 실제로 존재하는 종만 필터칩으로 노출 (등장 순서 유지, 중복 제거)
    final allPets = petsAsync.valueOrNull ?? const <Pet>[];
    final speciesChips = <int, String>{};
    for (final p in allPets) {
      speciesChips.putIfAbsent(p.speciesId, () => p.speciesName);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.sm),
          // 테마 기본 입력칸은 **밑줄**이다. 연회색 바탕에 밑줄 하나만 그어두면
          // 옛 테마 그대로 보인다 — 바탕 위의 흰 카드로 띄워 다른 섹션과 같은 층에.
          child: Container(
            decoration: AppDecor.card,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: AppTextStyles.body,
              decoration: InputDecoration(
                isDense: true,
                hintText: '이름 또는 종 검색',
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.ink3),
                prefixIcon: const Icon(Icons.search,
                    size: AppIconSize.md, color: AppColors.ink3),
                prefixIconConstraints: const BoxConstraints(
                    minWidth: AppIconSize.lg, minHeight: AppIconSize.lg),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm, AppSpacing.md, 0, AppSpacing.md),
              ),
            ),
          ),
        ),
        SizedBox(
          height: AppChip.barHeight,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            children: [
              AppChip(
                label: '전체',
                selected: _selectedSpeciesId == null,
                onTap: () => setState(() => _selectedSpeciesId = null),
              ),
              const SizedBox(width: AppSpacing.sm),
              ...speciesChips.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AppChip(
                    label: e.value,
                    selected: _selectedSpeciesId == e.key,
                    onTap: () => setState(() => _selectedSpeciesId = e.key),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: petsAsync.when(
            loading: () => const SkeletonCardList(),
            error: (e, _) => EmptyState(
              message: '불러오지 못했어요',
              // 예전엔 `e.toString()` 을 그대로 띄웠다. 사용자는 읽을 수 없고
              // 할 수 있는 것도 없는 글자다 — 원인은 로그로 본다.
              subMessage: '연결을 확인하고 다시 시도해주세요.',
              icon: Icons.cloud_off,
              tone: EmptyTone.neutral,
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
                        // 여기서 사용자가 만들 것은 없다 — 연녹 원을 쓰면
                        // "비었으니 채워보라"로 읽힌다.
                        tone: EmptyTone.neutral,
                      )
                    : EmptyState(
                        message: _query.isEmpty && _selectedSpeciesId == null
                            ? '아직 등록한 개체가 없어요'
                            : '조건에 맞는 개체가 없어요',
                        subMessage: _query.isEmpty && _selectedSpeciesId == null
                            ? '첫 개체를 등록하면 기록을 쌓을 수 있어요.'
                            : '검색어나 종 필터를 바꿔보세요.',
                        icon: _query.isEmpty && _selectedSpeciesId == null
                            ? Icons.pets
                            : Icons.search_off,
                        tone: _query.isEmpty && _selectedSpeciesId == null
                            ? EmptyTone.brand
                            : EmptyTone.neutral,
                        actionLabel: _query.isEmpty && _selectedSpeciesId == null
                            ? '개체 등록'
                            : null,
                        onAction: _query.isEmpty && _selectedSpeciesId == null
                            ? () => context.push('/pets/new')
                            : null,
                      );
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(petListProvider.notifier).load(),
                child: Column(
                  children: [
                    _PetCountLine(
                      shown: pets.length,
                      total: allPets.length,
                      isGrid: isGridView,
                      onViewChanged: (v) =>
                          ref.read(petListGridProvider.notifier).set(v),
                    ),
                    if (hiddenShared > 0) _SharedHiddenNotice(hiddenShared),
                    Expanded(
                      child: isGridView
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

/// 격자 ↔ 목록 보기 토글.
///
/// ⚠️ 전에는 `IconButton` 2개를 나란히 뒀는데, **아이콘이 거기 있는 줄도 모른다**는
/// 지적을 받았다. 색만 다른 두 아이콘은 "버튼"으로 보이지 않는다 —
/// 눌릴 수 있다는 걸 보여주는 건 테두리와 바탕이다. 흰 알약 안에서 고른 쪽만
/// 틴트로 칠하는 분절 토글(segmented)로 바꿨다: 선택 상태와 나머지 선택지가
/// 한눈에 같이 보인다.
class _ViewToggle extends StatelessWidget {
  final bool isGrid;
  final ValueChanged<bool> onChanged;
  const _ViewToggle({required this.isGrid, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _ViewToggleTile(
            icon: Icons.grid_view,
            tooltip: '격자로 보기',
            active: isGrid,
            onTap: () => onChanged(true),
          ),
          _ViewToggleTile(
            icon: Icons.view_agenda_outlined,
            tooltip: '목록으로 보기',
            active: !isGrid,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ViewToggleTile extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;
  const _ViewToggleTile({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.brandTint : Colors.transparent,
            borderRadius: AppRadius.brPill,
          ),
          child: Icon(icon,
              size: 18,
              color: active ? AppColors.brandTintInk : AppColors.ink3),
        ),
      ),
    );
  }
}

/// 지금 보고 있는 개체 수 한 줄.
///
/// 검색·종 필터가 걸려 있으면 '전체 N마리 중'을 함께 보여준다 — 숫자만 띄우면
/// 필터가 걸린 걸 잊은 사람이 개체가 사라졌다고 읽는다.
class _PetCountLine extends StatelessWidget {
  final int shown;
  final int total;

  /// 보기 방식 토글을 이 줄의 오른쪽 끝에 함께 그린다.
  /// ℹ️ 개체가 하나도 없으면 이 줄 자체가 안 그려지므로 토글도 사라진다 —
  ///    보여줄 게 없는 자리에서 보기 방식을 고르게 할 이유가 없다.
  final bool isGrid;
  final ValueChanged<bool> onViewChanged;

  const _PetCountLine({
    required this.shown,
    required this.total,
    required this.isGrid,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = shown != total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.sm),
      child: Row(
        children: [
          Text(
            filtered ? '$shown마리' : '총 $shown마리',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.ink2,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (filtered)
            Text(
              ' · 전체 $total마리 중',
              style: AppTextStyles.caption.copyWith(color: AppColors.ink3),
            ),
          const Spacer(),
          // 보기 토글은 필터칩 줄 끝에 있었다. 거기는 가로 스크롤이 끝나는
          // 자리라 칩이 많으면 칩이 토글에 바짝 붙어 **같은 줄의 또 다른 칩**
          // 처럼 보였다. 이 줄은 스크롤이 없고 "지금 무엇을 보고 있나"를
          // 말하는 줄이라 보기 방식과 축이 같다.
          _ViewToggle(isGrid: isGrid, onChanged: onViewChanged),
        ],
      ),
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
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      // 연회색 바탕 위의 연회색 박스였다 — 아무 경계도 못 만든다.
      // 앱 규칙대로 바탕은 canvas, 내용은 흰 카드.
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline,
              size: AppIconSize.sm, color: AppColors.ink3),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '공유받은 $count마리는 소유자만 관리할 수 있어 목록에서 뺐어요.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.ink2, height: 1.3),
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      // ⛔ 3열로 늘렸다가 되돌렸다. 카드 폭이 ~110px 이 되면 이름·종·체중이
      //    들어갈 자리가 없어 전부 말줄임이 걸린다 — 스크롤 길이를 줄이려고
      //    **정보를 못 읽게 만드는** 교환이었다. 2열이 이 카드의 하한이다.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
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
    // 개체 지정색은 걷어냈다 — 저장된 hex 를 그대로 칠하던 자리다.
    // 자세한 이유는 core/theme/pale_palette.dart 주석 참고.
    return AppColors.bgAlt;
  }

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
        // 카드 위쪽 절반이 사진으로 꽉 차는 구조라, 자르지 않으면 사진이
        // 둥근 모서리를 그대로 뚫고 나온다 — 테두리만 둥글고 내용은 각진 모양이 된다.
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: AppRadius.brLg,
          color: AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.brandAction : AppColors.border,
            width: selected ? 2 : 1,
          ),
          // 선으로만 나눠서 카드가 바탕에 눌려 있었다. elev1 — 있는 줄 모를
          // 만큼 옅고, 없으면 허전한 정도의 그림자다.
          boxShadow: AppShadows.elev1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _bgColor,
                    ),
                    child: pet.profileImageUrl != null
                        ? AppNetworkImage(pet.profileImageUrl,
                                fit: BoxFit.cover,
                                memWidth: 400,
                                placeholder: _spriteIcon())
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
                      child: Center(
                        child: SexIcon.fromCode(pet.gender, size: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                // ⚠️ 여기서 overflow 가 났다. 정보칸은 카드 높이의 4/10 로
                // **고정**인데 이름·종·체중을 **세 줄**로 쌓고 있었다. 기기가
                // 좁거나 OS 글자 크기를 키운 사람(textScaler > 1)에게는 세 줄이
                // 그 높이를 넘긴다 — 비율을 조금 키워봐야 글자 배율은 한계가 없다.
                //
                // 그래서 줄 수를 줄인다: **종과 체중을 한 줄에** 놓는다
                // (종은 왼쪽에서 남는 폭을 먹고, 체중은 오른쪽 끝). 두 줄이면
                // 여유가 생기고, 종·체중은 성격이 달라 가로로 나란히 두는 게
                // 위아래로 쌓는 것보다 오히려 잘 읽힌다.
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.name,
                        style: AppTextStyles.bodyBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(pet.speciesName,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (pet.latestWeightG != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${pet.latestWeightG!.toStringAsFixed(0)}g',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.ink3),
                          ),
                        ],
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

  // 사진 없는 카드는 그 개체의 종 실루엣으로 메운다. 전부 도마뱀이면
  // 뱀만 키우는 사람의 목록이 통째로 거짓말을 한다.
  Widget _spriteIcon() => Center(
      child: AppIcon(AppIcons.species(pet.speciesSubcategory),
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
        color: selected
            ? AppColors.brandAction
            : AppColors.surface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(
            color: selected ? AppColors.brandAction : AppColors.ink3,
            width: 1.5),
      ),
      child: selected
          ? const Icon(Icons.check, size: AppIconSize.sm, color: AppColors.bg)
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: pets.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
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

    // ⚠️ `ListTile` 은 `tileColor` 를 자기가 칠하므로 **그림자를 넣을 자리가
    // 없다**(shape 의 border 까지가 한계였다). 그래서 카드 모양·그림자는 바깥
    // Container 가 그리고 타일은 투명하게 얹는다 — 2열 카드와 같은 무게로.
    // 모서리도 `borderRadius` 를 안 줘서 1열 모드만 각이 서 있었다.
    return Container(
      // 타일의 잉크 효과가 둥근 모서리를 뚫고 네모로 번지지 않게 자른다.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(
            color: selected ? AppColors.brandAction : AppColors.border,
            width: selected ? 2 : 1),
        boxShadow: AppShadows.elev1,
      ),
      child: ListTile(
      onTap: selecting
          ? () => _togglePet(ref, pet.id)
          : () => context.push('/pets/${pet.id}'),
      onLongPress:
          selecting ? null : () => _enterSelectionWith(context, ref, pet),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      tileColor: Colors.transparent,
      leading: selecting
          ? _CheckBadge(selected: selected)
          : _PetAvatarSmall(pet: pet),
      title: Text(pet.name, style: AppTextStyles.bodyBold),
      subtitle: Text(pet.speciesName, style: AppTextStyles.caption),
      trailing: pet.latestWeightG != null
          ? Text('${pet.latestWeightG!.toStringAsFixed(0)}g',
              style: AppTextStyles.caption)
          : null,
      ),
    );
  }
}

class _PetAvatarSmall extends StatelessWidget {
  final Pet pet;
  const _PetAvatarSmall({required this.pet});

  Color get _color {
    // 개체 지정색은 걷어냈다 — 저장된 hex 를 그대로 칠하던 자리다.
    // 자세한 이유는 core/theme/pale_palette.dart 주석 참고.
    return AppColors.bgAlt;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
      child: pet.profileImageUrl != null
          ? ClipOval(
              child: AppNetworkImage(pet.profileImageUrl,
                  fit: BoxFit.cover,
                  memWidth: 120,
                  placeholder: AppIcon(
                      AppIcons.species(pet.speciesSubcategory),
                      color: AppColors.primary.withValues(alpha: 0.4),
                      size: 20)))
          : AppIcon(AppIcons.species(pet.speciesSubcategory),
              color: AppColors.primary.withValues(alpha: 0.4), size: 20),
    );
  }
}


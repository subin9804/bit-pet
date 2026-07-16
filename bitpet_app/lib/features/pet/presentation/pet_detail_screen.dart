import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/pale_palette.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/pet_models.dart';
import '../providers/pet_provider.dart';
import 'widgets/pet_hero_card.dart';
import 'widgets/pet_info_grid.dart';
import 'widgets/record_tab.dart';
import 'widgets/pet_calendar_tab.dart';
import 'widgets/gallery_tab.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  final int petId;
  const PetDetailScreen({super.key, required this.petId});

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  int _tabIndex = 0; // 0:기록 1:캘린더 2:갤러리

  static const _tabs = ['기록', '캘린더', '갤러리'];
  // mock 탭 카운트 (추후 API 대체)
  static const _tabCounts = [24, 4, 9];

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(petDetailProvider(widget.petId));

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: petAsync.when(
        loading: () => const _LoadingSkeleton(),
        error:   (e, _) => Center(child: Text(e.toString())),
        data:    (pet) {
          final paletteKey = PalePalette.keyFromHex(pet.colorCode);
          return Column(
            children: [
              // ── TopBar (SafeArea 포함) ──────────────────────
              SafeArea(
                bottom: false,
                child: _TopBar(
                  onBack: () => context.pop(),
                  onEdit: () => context.push('/pets/${widget.petId}/edit'),
                  onMore: (anchorContext) => _showMoreMenu(anchorContext, pet),
                ),
              ),

              // ── 스크롤 본문 ─────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 히어로 프로필 카드
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: PetHeroCard(pet: pet, paletteKey: paletteKey),
                      ),
                      const SizedBox(height: 14),

                      // 기본 정보 카드
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: PetInfoGrid(pet: pet, petId: widget.petId),
                      ),
                      const SizedBox(height: 22),

                      // 탭 바 (3등분)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          children: List.generate(_tabs.length, (i) {
                            final active = _tabIndex == i;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _tabIndex = i),
                                child: Container(
                                  margin: EdgeInsets.only(
                                      right: i < _tabs.length - 1 ? 6 : 0),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.primary
                                        : AppColors.card,
                                    border: active
                                        ? null
                                        : Border.all(color: AppColors.paleLine),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _tabs[i],
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: active
                                              ? AppColors.paleBg
                                              : AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_tabCounts[i]}',
                                        style: AppTextStyles.mono(
                                          10, FontWeight.w600,
                                          color: active
                                              ? AppColors.paleBg.withValues(alpha: 0.6)
                                              : AppColors.paleInk3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 탭 콘텐츠
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: IndexedStack(
                          index: _tabIndex,
                          children: [
                            RecordTab(
                              petId: widget.petId,
                              paletteKey: paletteKey,
                            ),
                            PetCalendarTab(petId: widget.petId),
                            GalleryTab(
                              petId: widget.petId,
                              paletteKey: paletteKey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 점 세개 버튼 아래 드롭다운 메뉴 — 이별하기 / 이 개체 삭제하기
  Future<void> _showMoreMenu(BuildContext anchorContext, Pet pet) async {
    final box     = anchorContext.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset  = box.localToGlobal(Offset.zero, ancestor: overlay);
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + box.size.height + 6,
      overlay.size.width - offset.dx - box.size.width,
      0,
    );

    final action = await showMenu<String>(
      context: context,
      position: position,
      color: AppColors.card,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.paleLine),
      ),
      items: [
        PopupMenuItem(
          value: pet.isDeceased ? 'revert' : 'farewell',
          height: 44,
          child: Row(
            children: [
              const Text('🌈', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                pet.isDeceased ? '이별 취소' : '이별하기',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          height: 44,
          child: Row(
            children: const [
              Icon(Icons.ios_share, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 8),
              Text('공유 관리',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 44,
          child: Row(
            children: const [
              Icon(Icons.delete_outline, size: 16, color: AppColors.error),
              SizedBox(width: 8),
              Text('이 개체 삭제하기',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
    if (!mounted) return;

    switch (action) {
      case 'farewell': await _handleFarewell(pet.name);
      case 'revert':   await _handleRevertFarewell();
      case 'share':    context.push('/pets/${widget.petId}/share');
      case 'delete':   await _handleDelete(pet.name);
    }
  }

  /// 이별하기 — 폐사 처리 (기록 보존)
  Future<void> _handleFarewell(String name) async {
    final ok = await ConfirmModal.show(
      context,
      title: '이별하기',
      message:
          '$name와(과) 이별할까요?\n함께한 기록은 그대로 남고, 내 개체 목록 맨 아래로 이동해요.',
      confirmLabel: '이별하기',
    );
    if (ok && mounted) {
      await ref.read(petListProvider.notifier).markDeceased(widget.petId);
      ref.invalidate(petDetailProvider(widget.petId));
      if (mounted) {
        ToastMessage.show(context, '$name와(과)의 기억은 그대로 남아있어요. 🌈',
            type: ToastType.success);
      }
    }
  }

  /// 이별 취소 — 폐사 표시 해제
  Future<void> _handleRevertFarewell() async {
    await ref.read(petListProvider.notifier).revertDeceased(widget.petId);
    ref.invalidate(petDetailProvider(widget.petId));
    if (mounted) {
      ToastMessage.show(context, '이별이 취소되었습니다.', type: ToastType.success);
    }
  }

  Future<void> _handleDelete(String name) async {
    final ok = await ConfirmModal.show(
      context,
      title: '개체 삭제',
      message: '$name을(를) 삭제할까요? 모든 기록도 함께 삭제됩니다.',
      confirmLabel: '삭제',
      isDangerous: true,
      requireTextConfirmation: name,
    );
    if (ok && mounted) {
      await ref.read(petListProvider.notifier).remove(widget.petId);
      if (mounted) {
        context.pop();
        ToastMessage.show(context, '개체가 삭제되었습니다.', type: ToastType.success);
      }
    }
  }
}

// ── TopBar ──────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final void Function(BuildContext anchorContext) onMore;

  const _TopBar({
    required this.onBack,
    required this.onEdit,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          // 뒤로가기 버튼 36×36 원형
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.paleLine),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.primary),
            ),
          ),
          const Spacer(),
          // 편집 버튼
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.paleLine),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 16, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 6),
          // 더보기 (이별하기 · 삭제)
          Builder(
            builder: (anchorContext) => GestureDetector(
              onTap: () => onMore(anchorContext),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.paleLine),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.more_vert,
                    size: 16, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 로딩 스켈레톤 ────────────────────────────────────────────
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: double.infinity, height: 130),
            const SizedBox(height: 14),
            SkeletonBox(width: double.infinity, height: 130),
            const SizedBox(height: 22),
            SkeletonBox(width: double.infinity, height: 44),
            const SizedBox(height: 18),
            SkeletonBox(width: double.infinity, height: 200),
          ],
        ),
      ),
    );
  }
}

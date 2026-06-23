import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/pale_palette.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../providers/pet_provider.dart';
import 'widgets/pet_hero_card.dart';
import 'widgets/pet_info_grid.dart';
import 'widgets/record_tab.dart';
import 'widgets/gallery_tab.dart';
import '../../routine/presentation/pet_routine_tab.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  final int petId;
  const PetDetailScreen({super.key, required this.petId});

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  int _tabIndex = 0; // 0:기록 1:루틴 2:갤러리

  static const _tabs = ['기록', '루틴', '갤러리'];
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
                  onBack:   () => context.pop(),
                  onEdit:   () => context.push('/pets/${widget.petId}/edit'),
                  onDelete: () => _handleDelete(pet.name),
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
                                    borderRadius: BorderRadius.circular(12),
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
                            PetRoutineTab(
                              petId: widget.petId,
                              paletteKey: paletteKey,
                            ),
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

  Future<void> _handleDelete(String name) async {
    final ok = await ConfirmModal.show(
      context,
      title: '개체 삭제',
      message: '$name을(를) 삭제할까요? 모든 기록도 함께 삭제됩니다.',
      confirmLabel: '삭제',
      isDangerous: true,
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
  final VoidCallback onDelete;

  const _TopBar({
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
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
          // 더보기(삭제 등)
          GestureDetector(
            onTap: onDelete,
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
            SkeletonBox(width: double.infinity, height: 130, borderRadius: 22),
            const SizedBox(height: 14),
            SkeletonBox(width: double.infinity, height: 130, borderRadius: 16),
            const SizedBox(height: 22),
            SkeletonBox(width: double.infinity, height: 44, borderRadius: 12),
            const SizedBox(height: 18),
            SkeletonBox(width: double.infinity, height: 200, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_response.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/toast_message.dart';
import '../../../core/utils/weight_format.dart';
import '../../record/presentation/fab_record_sheet.dart';
import '../data/models/pet_models.dart';
import '../providers/pet_provider.dart';
import '../share/data/share_repository.dart';
import 'widgets/pet_hero_card.dart';
import 'widgets/pet_info_grid.dart';
import 'widgets/record_tab.dart';
import 'widgets/pet_calendar_tab.dart';
import 'widgets/gallery_tab.dart';
import 'widgets/pedigree_tab.dart';
import '../../../core/theme/app_dimens.dart';

class PetDetailScreen extends ConsumerStatefulWidget {
  final int petId;

  /// 진입 직후 자동으로 열 기록 종류 ('feed' / 'scale'). null이면 열지 않는다.
  /// NFC 태그 스캔 시 `?openRecord=feed` 형태로 들어온다.
  final String? openRecordType;

  const PetDetailScreen({
    super.key,
    required this.petId,
    this.openRecordType,
  });

  @override
  ConsumerState<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends ConsumerState<PetDetailScreen> {
  int _tabIndex = 0; // 0:기록 1:캘린더 2:갤러리 3:가계도(부모가 있을 때만)

  @override
  void initState() {
    super.initState();
    // 태그 스캔으로 들어온 경우 기록 시트를 바로 띄운다.
    // 시트를 닫아도 이 상세 화면에 그대로 남는다.
    final type = widget.openRecordType;
    if (type == null || type.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showAppSheet<void>(
        context: context,
        enableDrag: false, // 개별 입력은 한꺼번에 저장 — 시트가 확인을 받는다
        builder: (_) => FabRecordSheet(
          initialTypeId: type,
          initialPetId: widget.petId,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(petDetailProvider(widget.petId));
    // 가계도 탭은 부모가 등록된 개체에만 붙는다. 부모가 지워져 탭이 사라지면
    // 가계도를 보고 있던 인덱스가 범위를 벗어나므로 첫 탭으로 되돌린다.
    final hasPedigree = ref
            .watch(genealogyProvider(widget.petId))
            .valueOrNull
            ?.hasParents ??
        false;
    final tabs = ['기록', '캘린더', '갤러리', if (hasPedigree) '가계도'];
    final tabIndex = _tabIndex < tabs.length ? _tabIndex : 0;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      // ⛔ 여기에 하단 고정 버튼을 두지 말 것. 이 화면은 하단 내비 안쪽이라
      // 무엇을 깔아도 **내비 바 위에 한 층 더 쌓인다** — 기록 버튼을 뒀더니
      // 내비 중앙 ＋ 와 같은 동작이 60px 간격으로 두 개가 됐고, 바닥 세이프에어리어도
      // 두 번 들어가 빈 띠가 생겼다. 기록은 내비 중앙 ＋ 가 받고, 그 ＋ 는 이 화면에서
      // **이 개체로 미리 채워진다** (`HomeScreen._detailPetId`).
      //
      // 수정 진입점도 여기가 아니다 — TopBar 연필과 점세개 메뉴에 이미 둘이 있다.
      body: petAsync.when(
        loading: () => const _LoadingSkeleton(),
        error:   (e, _) => Center(child: Text(e.toString())),
        data:    (pet) {
          return Column(
            children: [
              // ── TopBar (SafeArea 포함) ──────────────────────
              //
              // ⚠️ 바가 연회색 바탕 위에 떠 있고 그 **아래**에서 연녹 밴드가
              // 시작했다. 색이 두 번 바뀌니(회색 → 연녹 → 흰 카드) 머리가
              // 어디까지인지 알 수 없었다. 바도 밴드와 같은 색을 깔아
              // 헤더 하나로 이어 붙인다 — 스크롤하면 밴드만 이 바 아래로
              // 빠져나가고 색은 그대로 남는다.
              Container(
                color: AppColors.brandTintSoft,
                child: SafeArea(
                bottom: false,
                child: _TopBar(
                  onBack: () => context.pop(),
                  onEdit: () => context.push('/pets/${widget.petId}/edit'),
                  onMore: (anchorContext) => _showMoreMenu(anchorContext, pet),
                ),
                ),
              ),

              // ── 스크롤 본문 ─────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  // 하단 내비 바가 자리를 차지하므로 예전의 110 은 과하다.
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 연녹 헤더 밴드 ──────────────────────
                      //
                      // 개체 상세는 '그 개체의 공간'이어야 하는데 지금까지는 배경이
                      // 목록 화면과 똑같아서 어디로 들어왔는지가 색으로 구분되지
                      // 않았다. 밴드는 브랜드 틴트 한 겹뿐이다 (글씨가 올라가지
                      // 않는 면이라 brand50 로도 대비 문제가 없다).
                      Container(
                        width: double.infinity,
                        color: AppColors.brandTintSoft,
                        // 히어로는 이제 카드가 아니라 밴드 위에 바로 놓인다
                        // (아래 통계 카드 하나만 밴드에 걸치게 하려고).
                        // 카드가 만들어 주던 안쪽 여백을 밴드가 대신 든다.
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 44),
                        child: PetHeroCard(pet: pet),
                      ),

                      // 통계 3칸을 밴드 위로 28px 끌어올려 걸친다. 밴드와 본문이
                      // 카드 한 줄로 이어져 경계가 선이 아니라 면이 된다.
                      Transform.translate(
                        offset: const Offset(0, -28),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                          child: _PetStats(pet: pet),
                        ),
                      ),

                      // 기본 정보 카드. 위 Transform 은 레이아웃 높이를 줄이지
                      // 않으므로 실제 간격은 28px 더 벌어져 있다 — 그래서 여기에
                      // 추가 간격을 두지 않는다.
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl),
                        child: PetInfoGrid(pet: pet, petId: widget.petId),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ── 탭 바 (밑줄형) ────────────────────────
                      //
                      // 알약 토글이었다가 밑줄로 되돌렸다. 알약은 '세 개 중
                      // 하나를 고르는 **설정**'의 모양이고(개체 목록의 1열/2열
                      // 보기 토글이 그렇다), 여기서 고르는 건 설정이 아니라
                      // **지금 보고 있는 페이지**다. 밑줄은 아래 내용과 한 덩어리로
                      // 붙어서 "이 줄 아래가 그 내용"이라고 말해 준다.
                      //
                      // 칸을 3등분하지 않고 글자 폭에 맞춰 왼쪽부터 세우는 것도
                      // 같은 이유다 — 밑줄이 글자만큼만 그어져야 제목처럼 읽힌다.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl),
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: AppColors.line)),
                        ),
                        child: Row(
                          children: List.generate(tabs.length, (i) {
                            final active = tabIndex == i;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _tabIndex = i),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    right: AppSpacing.xl),
                                // 밑줄은 글자와 **같은 폭**이어야 한다.
                                // `stretch` 만으로는 가로 제약이 열려 있어
                                // 화면 끝까지 늘어나므로 IntrinsicWidth 로
                                // 글자 폭을 먼저 확정한다 (탭 3개라 비용은 없다).
                                child: IntrinsicWidth(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: AppSpacing.md),
                                        child: Text(
                                          tabs[i],
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.subheading
                                              .copyWith(
                                            fontWeight: active
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: active
                                                ? AppColors.ink
                                                : AppColors.ink3,
                                          ),
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: active
                                              ? AppColors.brandAction
                                              : Colors.transparent,
                                          borderRadius: const BorderRadius
                                              .vertical(
                                              top: Radius.circular(2)),
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
                      const SizedBox(height: AppSpacing.xl),

                      // 탭 콘텐츠
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl),
                        child: IndexedStack(
                          index: tabIndex,
                          children: [
                            RecordTab(petId: widget.petId, gender: pet.gender,
                                speciesCategory: pet.speciesCategory),
                            PetCalendarTab(petId: widget.petId, gender: pet.gender,
                                speciesCategory: pet.speciesCategory),
                            GalleryTab(
                              petId: widget.petId,
                              profilePhotoId: pet.profilePhotoId,
                            ),
                            if (hasPedigree) PedigreeTab(petId: widget.petId),
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

  /// 점 세개 버튼 아래 드롭다운 메뉴.
  ///
  /// 이별·공유 관리·삭제는 모두 **소유자(OWNER) 전용**이다. 공유받은 개체(KEEPER)에
  /// 그대로 노출하면 눌러야만 403을 알게 되므로, 아예 다른 메뉴를 띄운다 —
  /// 공유받은 쪽이 할 수 있는 건 '함께 키우기 그만두기'뿐이다.
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
      color: AppColors.surface,
      // 메뉴는 화면 위에 **떠 있는 것**이라 그림자를 받는다 — 테두리만 있을
      // 때는 뒤 카드와 같은 층처럼 보여 어디까지가 메뉴인지 애매했다.
      elevation: 3,
      shadowColor: AppShadows.material,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.brMd,
        side: BorderSide(color: AppColors.line),
      ),
      items: pet.isOwner ? _ownerMenuItems(pet) : _keeperMenuItems(pet),
    );
    if (!mounted) return;

    switch (action) {
      case 'farewell': await _handleFarewell(pet.name);
      case 'revert':   await _handleRevertFarewell();
      case 'share':    context.push('/pets/${widget.petId}/share');
      case 'delete':   await _handleDelete(pet.name);
      case 'leave':    await _handleLeave(pet.name);
    }
  }

  /// 이별하기 — 사육자면 누구나. 폐사는 소유권 판단이 아니라 일어난 사실의 기록이고,
  /// 되돌리는 '이별 취소'가 있어 함께 키우는 쪽에 열어도 복구된다.
  PopupMenuEntry<String> _farewellMenuItem(Pet pet) => PopupMenuItem(
        value: pet.isDeceased ? 'revert' : 'farewell',
        height: 44,
        child: Row(
          children: [
            const Text('🌈', style: TextStyle(fontSize: 14)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              pet.isDeceased ? '이별 취소' : '이별하기',
              style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
          ],
        ),
      );

  List<PopupMenuEntry<String>> _ownerMenuItems(Pet pet) => [
        _farewellMenuItem(pet),
        PopupMenuItem(
          value: 'share',
          height: 44,
          child: Row(
            children: [
              const Icon(Icons.ios_share,
                  size: AppIconSize.sm, color: AppColors.ink2),
              const SizedBox(width: AppSpacing.sm),
              Text('공유 관리',
                  style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600, color: AppColors.ink)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          height: 44,
          child: Row(
            children: [
              const Icon(Icons.delete_outline,
                  size: AppIconSize.sm, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Text('이 개체 삭제하기',
                  style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600, color: AppColors.error)),
            ],
          ),
        ),
      ];

  /// 공유받은 개체 — 되돌릴 수 있는 동작(이별)은 그대로 쓰고,
  /// 개체가 사라지거나 남에게 넘어가는 동작(삭제·공유 관리)만 빠진다.
  List<PopupMenuEntry<String>> _keeperMenuItems(Pet pet) => [
        PopupMenuItem(
          enabled: false,
          height: 34,
          child: Row(
            children: [
              const Icon(Icons.group_outlined,
                  size: AppIconSize.sm, color: AppColors.ink3),
              const SizedBox(width: AppSpacing.sm),
              Text('공유받은 개체', style: AppTextStyles.label),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        _farewellMenuItem(pet),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'leave',
          height: 44,
          child: Row(
            children: [
              const Icon(Icons.logout,
                  size: AppIconSize.sm, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Text('함께 키우기 그만두기',
                  style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600, color: AppColors.error)),
            ],
          ),
        ),
      ];

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

  /// 함께 키우기 그만두기 — 공유받은 개체에서 스스로 빠진다 (KEEPER).
  /// 개체와 기록은 소유자 쪽에 그대로 남고, 내 목록에서만 사라진다.
  Future<void> _handleLeave(String name) async {
    final ok = await ConfirmModal.show(
      context,
      title: '함께 키우기 그만두기',
      message: '$name을(를) 내 목록에서 뺄까요?\n'
          '개체와 기록은 소유자에게 그대로 남고, 나는 더 이상 볼 수 없어요.',
      confirmLabel: '그만두기',
      isDangerous: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(shareRepositoryProvider).leave(widget.petId);
      await ref.read(petListProvider.notifier).load();
      if (mounted) {
        context.pop();
        ToastMessage.show(context, '$name 공유를 그만뒀어요.', type: ToastType.success);
      }
    } on ApiException catch (e) {
      if (mounted) ToastMessage.show(context, e.message, type: ToastType.error);
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
      // 좌우 16 이었다 — 바로 아래 히어로 카드가 20 이라 뒤로가기 버튼만
      // 4px 밖으로 나와 있었다. 이 화면의 거터는 하나다.
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
      child: Row(
        children: [
          _RoundIconButton(
              icon: Icons.arrow_back_ios_new,
              tooltip: '뒤로',
              onTap: onBack),
          const Spacer(),
          _RoundIconButton(
              icon: Icons.edit_outlined, tooltip: '수정', onTap: onEdit),
          const SizedBox(width: AppSpacing.sm),
          Builder(
            builder: (anchorContext) => _RoundIconButton(
              icon: Icons.more_vert,
              tooltip: '더보기',
              onTap: () => onMore(anchorContext),
            ),
          ),
        ],
      ),
    );
  }
}

/// 헤더의 둥근 아이콘 버튼. 같은 Container 가 세 번 복사돼 있었다.
///
/// 연녹 밴드 위에 얹히므로 **흰 채움 + 그림자**다 — 테두리만 있으면 밴드와
/// 명도 차가 작아 버튼이 아니라 밴드에 그린 선처럼 보인다.
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            shape: BoxShape.circle,
            boxShadow: AppShadows.elev1,
          ),
          child: Icon(icon, size: AppIconSize.sm, color: AppColors.ink),
        ),
      ),
    );
  }
}

// ── 로딩 스켈레톤 ────────────────────────────────────────────
// ── 통계 카드 3칸 ─────────────────────────────────────────────
//
// 전부 이미 받아둔 `Pet` 에서 나오는 값이다 — 이 줄을 위해 새 API 를 만들지 않았다.
// 값이 없으면 `0` 이 아니라 `-` 로 둔다 (StatCard 가 그렇게 그린다).
class _PetStats extends StatelessWidget {
  final Pet pet;

  const _PetStats({required this.pet});

  /// 함께한 날 — 입양일이 있으면 그 날부터, 없으면 해칭일부터 센다.
  /// 둘 다 없는 개체(분양받아 날짜를 모르는 경우)는 셀 근거가 없으므로 null.
  int? get _days {
    final from = pet.adoptionDate ?? pet.hatchingDate;
    if (from == null) return null;
    final d = DateTime.now().difference(from).inDays;
    return d < 0 ? null : d + 1;
  }

  /// 나이 — 개월. 12개월을 넘으면 연 단위로 바꿔 보여준다.
  (String, String)? get _age {
    final h = pet.hatchingDate;
    if (h == null) return null;
    final months = (DateTime.now().difference(h).inDays / 30.44).floor();
    if (months < 0) return null;
    if (months < 12) return ('$months', '개월');
    return ((months / 12).floor().toString(), '년');
  }

  @override
  Widget build(BuildContext context) {
    final age = _age;
    final days = _days;

    return StatCardRow(
      cards: [
        StatCard(
          label: '최근 체중',
          value: pet.latestWeightG == null
              ? null
              : formatWeight(pet.latestWeightG!),
          unit: 'g',
        ),
        StatCard(label: '나이', value: age?.$1, unit: age?.$2),
        StatCard(
          label: '함께한 날',
          value: days?.toString(),
          unit: '일',
        ),
      ],
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: double.infinity, height: 130),
            const SizedBox(height: 16),
            SkeletonBox(width: double.infinity, height: 130),
            const SizedBox(height: 20),
            SkeletonBox(width: double.infinity, height: 44),
            const SizedBox(height: 20),
            SkeletonBox(width: double.infinity, height: 200),
          ],
        ),
      ),
    );
  }
}

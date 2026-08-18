import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/upload/image_upload.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/toast_message.dart';
import '../../auth/data/models/auth_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pet/share/providers/share_provider.dart';

class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('MY'),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('프로필 로드 실패')),
        data: (user) => ListView(
          children: [
            // 프로필 영역 — 카드 없이 플랫 레이아웃
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  _ProfileAvatar(imageUrl: user?.profileImageUrl),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '사용자',
                          style: AppTextStyles.h3),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '',
                          style: AppTextStyles.caption),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        color: AppColors.bg2,
                        child: Text(
                          user?.userType == 'BREEDER' ? 'BREEDER' : 'GENERAL',
                          style: AppTextStyles.label
                              .copyWith(color: AppColors.textSecondary,
                                  letterSpacing: 1.0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 공유 관리 허브 — 공유코드·받은 초대·개체 공유 시작
            const _ShareManageItem(),
            // NFC 이름표 — 연결 확인·기본 동작 변경·해제
            _MenuItem(
              icon: Icons.sell_outlined,
              label: '이름표 관리',
              onTap: () => context.push('/my/tags'),
            ),
            // 가계도 닉네임 공개 — 남의 가계도에 부모로 걸렸을 때 내가 드러날지
            _PedigreeNicknameToggle(
              value: user?.showNicknameInPedigree ?? true,
            ),
            _MenuItem(
              icon: Icons.notifications_outlined,
              label: '알림 설정',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.article_outlined,
              label: '내 게시글',
              onTap: () => context.push('/my/activity'),
            ),
            _MenuItem(
              icon: Icons.info_outline,
              label: '앱 정보',
              onTap: () {},
            ),

            const SizedBox(height: 24),

            // 메뉴 그룹 2 — 계정
            _MenuItem(
              icon: Icons.logout,
              label: '로그아웃',
              onTap: () async {
                final ok = await ConfirmModal.show(
                  context,
                  title: '로그아웃',
                  message: '로그아웃 하시겠어요?',
                  confirmLabel: '로그아웃',
                );
                if (ok && context.mounted) {
                  await ref.read(authStateProvider.notifier).logout();
                }
              },
            ),
            _MenuItem(
              icon: Icons.person_remove_outlined,
              label: '회원 탈퇴',
              labelColor: AppColors.error,
              onTap: () => _startWithdraw(context, ref),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// 공유 관리 메뉴 — 받은 초대 개수 배지 포함. 탭 시 공유 허브로 이동.
class _ShareManageItem extends ConsumerWidget {
  const _ShareManageItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(receivedBatchesProvider).maybeWhen(
          data: (list) => list.length,
          orElse: () => 0,
        );

    return InkWell(
      onTap: () => context.push('/share'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.handshake_outlined,
                size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text('공유 관리', style: AppTextStyles.body)),
            if (count > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$count',
                    style: AppTextStyles.label.copyWith(color: Colors.white)),
              ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

// 프로필 아바타 — 탭하면 갤러리에서 골라 업로드
class _ProfileAvatar extends ConsumerStatefulWidget {
  final String? imageUrl;
  const _ProfileAvatar({this.imageUrl});

  @override
  ConsumerState<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<_ProfileAvatar> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    if (_uploading) return;
    try {
      final picked =
          await ref.read(imageUploadServiceProvider).pickFromGallery();
      if (picked == null) return;
      setState(() => _uploading = true);
      await ref.read(authStateProvider.notifier).uploadProfileImage(picked);
      if (mounted) showToast(context, '프로필 사진을 변경했어요.', type: ToastType.success);
    } catch (e) {
      if (mounted) showToast(context, '업로드 실패: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl;
    return GestureDetector(
      onTap: _uploading ? null : _pickAndUpload,
      child: Stack(
        children: [
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(color: AppColors.bg2),
            child: url != null
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person,
                        color: AppColors.textSecondary, size: 28),
                  )
                : const Icon(Icons.person,
                    color: AppColors.textSecondary, size: 28),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              color: AppColors.primary,
              child: _uploading
                  ? const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: Colors.white),
                    )
                  : const Icon(Icons.camera_alt, size: 10, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 회원 탈퇴 ────────────────────────────────────────────────────────────────

/// 탈퇴 시작. 공동 사육자가 있는 개체가 있으면 **넘길지 지울지 먼저 묻는다**.
///
/// 없으면 굳이 선택지를 띄우지 않고 기존 확인 모달로 끝낸다 — 대부분의 유저는
/// 공유 개체가 없어서, 항상 물으면 이해할 필요 없는 질문만 하나 늘어난다.
Future<void> _startWithdraw(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(authStateProvider.notifier);

  List<SharedPetPreview> shared;
  try {
    shared = await notifier.withdrawPreview();
  } catch (_) {
    // 미리보기 실패로 탈퇴 자체를 막지는 않는다. 다만 선택지를 못 보여주므로
    // 안전한 쪽(넘기기)으로 진행한다 — 지운 건 되돌릴 수 없다
    shared = const [];
  }
  if (!context.mounted) return;

  bool handOver = true;
  if (shared.isNotEmpty) {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SharedPetChoiceSheet(sharedPets: shared),
    );
    if (choice == null || !context.mounted) return; // 취소
    handOver = choice;
  }

  final ok = await ConfirmModal.show(
    context,
    title: '회원 탈퇴',
    // 즉시 삭제된다. 다만 남의 가계도에 부모로 걸린 개체는 이름만 남기고
    // 익명화되므로 "전부 사라진다"고 쓰면 사실과 다르다
    message: '탈퇴하면 개체와 사육 기록이 즉시 삭제됩니다.\n'
        '다른 사육자의 가계도에 부모로 등록된 개체는 이름만 남고 '
        '기록·사진은 지워집니다. 정말 탈퇴하시겠어요?',
    confirmLabel: '탈퇴',
    isDangerous: true,
  );
  if (!ok || !context.mounted) return;

  try {
    await notifier.withdraw(handOverSharedPets: handOver);
  } catch (_) {
    if (context.mounted) {
      ToastMessage.show(context, '탈퇴에 실패했어요. 잠시 후 다시 시도해주세요.');
    }
  }
}

/// 공유 개체 처리 선택 — 넘기기(true) / 모두 삭제(false). 닫으면 null(취소).
///
/// 개체별이 아니라 **일괄 선택**이다. 넘길 대상은 서버가 정한다(가장 먼저 합류한
/// 공동 사육자) — 목록에 누가 받는지 미리 보여줘서 선택의 결과를 감추지 않는다.
class _SharedPetChoiceSheet extends StatefulWidget {
  final List<SharedPetPreview> sharedPets;
  const _SharedPetChoiceSheet({required this.sharedPets});

  @override
  State<_SharedPetChoiceSheet> createState() => _SharedPetChoiceSheetState();
}

class _SharedPetChoiceSheetState extends State<_SharedPetChoiceSheet> {
  bool _handOver = true;

  @override
  Widget build(BuildContext context) {
    final pets = widget.sharedPets;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paleBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.paleLine,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
              child: Text('함께 보는 개체가 ${pets.length}마리 있어요',
                  style: AppTextStyles.h3),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
              child: Text('탈퇴하면 이 개체들은 어떻게 할까요?',
                  style: AppTextStyles.caption),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                itemCount: pets.length,
                itemBuilder: (_, i) {
                  final p = pets[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Text('🦎', style: TextStyle(fontSize: 15)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(p.petName,
                              style: AppTextStyles.body,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                          _handOver
                              ? '→ ${p.recipientNickname ?? '함께 보던 사육자'}'
                              : '삭제',
                          style: AppTextStyles.caption.copyWith(
                              color: _handOver
                                  ? AppColors.textSecondary
                                  : AppColors.error),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _ChoiceRow(
              selected: _handOver,
              label: '함께 보던 사육자에게 넘기기',
              caption: '사육 기록과 사진도 함께 넘어가요',
              onTap: () => setState(() => _handOver = true),
            ),
            _ChoiceRow(
              selected: !_handOver,
              label: '넘기지 않고 모두 삭제',
              caption: '함께 보던 사람도 더 이상 볼 수 없어요',
              danger: true,
              onTap: () => setState(() => _handOver = false),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _handOver),
                      child: const Text('다음'),
                    ),
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

class _ChoiceRow extends StatelessWidget {
  final bool selected;
  final String label;
  final String caption;
  final bool danger;
  final VoidCallback onTap;

  const _ChoiceRow({
    required this.selected,
    required this.label,
    required this.caption,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected
                  ? (danger ? AppColors.error : AppColors.primary)
                  : AppColors.textDisabled,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.body.copyWith(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400)),
                  const SizedBox(height: 2),
                  Text(caption, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 가계도 닉네임 공개 토글.
///
/// 끄면 남의 가계도에서 내 자리가 '비공개'로 보이고, 서버가 userId 자체를 내려주지
/// 않아 프로필로도 들어올 수 없다. **개체명은 혈통 식별 정보라 이 설정과 무관하게 노출된다** —
/// 그래서 "개체를 숨긴다"가 아니라 "나를 숨긴다"로 설명한다.
class _PedigreeNicknameToggle extends ConsumerStatefulWidget {
  final bool value;
  const _PedigreeNicknameToggle({required this.value});

  @override
  ConsumerState<_PedigreeNicknameToggle> createState() =>
      _PedigreeNicknameToggleState();
}

class _PedigreeNicknameToggleState
    extends ConsumerState<_PedigreeNicknameToggle> {
  bool _saving = false;

  Future<void> _toggle(bool next) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(authStateProvider.notifier).setShowNicknameInPedigree(next);
    } catch (_) {
      if (mounted) ToastMessage.show(context, '설정 변경에 실패했어요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.account_tree_outlined,
              size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('가계도에 닉네임 공개', style: AppTextStyles.body),
                const SizedBox(height: 2),
                Text('끄면 남의 가계도에서 내 닉네임이 “비공개”로 표시돼요',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          Switch(
            value: widget.value,
            onChanged: _saving ? null : _toggle,
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: labelColor ?? AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppTextStyles.body.copyWith(color: labelColor)),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}

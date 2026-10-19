// 09 / 09b · 글 등록·수정 — 서버 카테고리 기반, 간소화
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_response.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_input_styles.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/upload/image_upload.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/post_models.dart';
import '../providers/post_provider.dart';
import '../../../core/theme/app_dimens.dart';

class PostComposeScreen extends ConsumerStatefulWidget {
  final int? postId; // null → 새 글, non-null → 수정
  const PostComposeScreen({super.key, this.postId});

  bool get isEdit => postId != null;

  @override
  ConsumerState<PostComposeScreen> createState() => _PostComposeScreenState();
}

class _PostComposeScreenState extends ConsumerState<PostComposeScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    final cs = ref.read(composeProvider);
    _titleCtrl = TextEditingController(text: cs.title);
    _bodyCtrl = TextEditingController(text: cs.body);

    if (widget.isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final provider = postDetailProvider(widget.postId!);
        _prefill(ref.read(provider));
        // 상세를 아직 못 받았으면(딥링크로 곧장 수정에 들어온 경우) 올 때까지 기다린다.
        // 예전엔 이 순간에 데이터가 없으면 폼이 영영 빈 채로 남았다.
        _prefillSub = ref.listenManual(provider, (_, next) => _prefill(next));
      });
    }
  }

  bool _prefilled = false;
  ProviderSubscription<AsyncValue<Post?>>? _prefillSub;

  /// 딱 한 번만 채운다 — 상세가 다시 로드될 때마다 덮으면 사용자가 고치던 내용이 날아간다.
  void _prefill(AsyncValue<Post?> detail) {
    if (_prefilled || !mounted) return;
    final post = detail.valueOrNull;
    if (post == null) return;
    _prefilled = true;
    ref.read(composeProvider.notifier).prefill(post);
    setState(() {
      _titleCtrl.text = post.title;
      _bodyCtrl.text = post.content;
    });
  }

  @override
  void dispose() {
    _prefillSub?.close();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(composeProvider.notifier);
    try {
      if (widget.isEdit) {
        final post = await notifier.update(widget.postId!);
        if (post != null && mounted) {
          ref.invalidate(postDetailProvider(widget.postId!));
          ref.invalidate(feedProvider);
          context.pop();
        }
      } else {
        final post = await notifier.submit();
        if (post != null && mounted) {
          ref.invalidate(feedProvider);
          context.go('/community');
        }
      }
    } on PhotoUploadFailure catch (e) {
      // 글 본문은 저장된 상태다. 화면을 닫지 않고 남겨서 실패한 사진만 다시 올리게 한다
      // ('등록'을 다시 눌러도 글이 또 만들어지지는 않는다).
      if (mounted) {
        showToast(context, '$e', type: ToastType.warning);
      }
    } catch (e) {
      if (mounted) {
        // 어린이 게시판 제한(CHILD_BOARD_ONLY / KIDS_BOARD_FORBIDDEN)처럼
        // 어디에 써야 하는지를 서버가 문장으로 알려주는 경우가 있다.
        showToast(context, serverMessageOf(e) ?? '글을 저장하지 못했어요.',
            type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(composeProvider);
    // visible 이 아니라 composable — 운영자가 아니면 공지사항이 목록에 없다
    final categories = ref.watch(composableCategoriesProvider);

    final canSubmit = state.canSubmit && !state.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      // 손으로 그린 흰 띠 상단바('취소' 글자 + 가운데 '새 글 작성 / NEW' 2줄 + 검정 알약 '등록')였다.
      // 영문 소제목은 다른 화면에서 걷어낸 장식이고, 검정 버튼은 먹색 `primary` 를 칠한 것이다.
      // '루틴 추가'·'추가' 와 같은 AppBar + 브랜드색 버튼으로.
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        leading: IconButton(
          tooltip: '취소',
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.isEdit ? '글 수정' : '새 글 작성'),
        titleSpacing: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xl),
            child: ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                textStyle: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.brandTintInk),
                    )
                  : Text(widget.isEdit ? '저장' : '등록'),
            ),
          ),
        ],
      ),
      body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg,
                    MediaQuery.of(context).viewInsets.bottom + 32),
                children: [
                  // ── 게시판 선택 ────────────────────────────────
                  _Field(
                    label: '게시판 선택',
                    required: true,
                    // 손으로 그린 칩(선택 시 검정 채움)이었다 — 목록 화면의 게시판 칩과
                    // 같은 [AppChip] 이어야 '같은 게시판을 고르는 것'으로 읽힌다.
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: categories
                          .map((c) => AppChip(
                                label: c.nameKo,
                                selected: state.categoryId == c.id,
                                onTap: () => ref
                                    .read(composeProvider.notifier)
                                    .setCategory(c.id),
                              ))
                          .toList(),
                    ),
                  ),

                  // ── 제목 ──────────────────────────────────────
                  _Field(
                    label: '제목',
                    required: true,
                    child: _PaleTextField(
                      controller: _titleCtrl,
                      placeholder: '제목을 입력하세요',
                      onChanged: (v) =>
                          ref.read(composeProvider.notifier).setTitle(v),
                    ),
                  ),

                  // ── 내용 ──────────────────────────────────────
                  _Field(
                    label: '내용',
                    required: true,
                    child: TextField(
                      controller: _bodyCtrl,
                      onChanged: (v) =>
                          ref.read(composeProvider.notifier).setBody(v),
                      maxLines: null,
                      minLines: 8,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.ink, height: 1.6),
                      decoration: AppInputStyles.textarea(
                        hintText: '자유롭게 작성해보세요.',
                        hintStyle: AppTextStyles.body
                            .copyWith(color: AppColors.ink3),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                      ),
                    ),
                  ),

                  // ── 사진 첨부 (선택, 최대 5장) ──────────────────
                  _Field(
                    label: '사진',
                    hint: '최대 $kMaxPostPhotos장까지 첨부할 수 있어요. 한 번에 여러 장 고를 수 있어요.',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // 이미 올린 사진과 방금 고른 사진이 한 줄에 같이 온다.
                        ...state.attachments.asMap().entries.map((e) => Stack(
                              children: [
                                Container(
                                  width: 78,
                                  height: 78,
                                  clipBehavior: Clip.hardEdge,
                                  decoration: const BoxDecoration(
                                      color: AppColors.bgAlt,
                                      borderRadius: AppRadius.brMd),
                                  child: e.value.isExisting
                                      ? AppNetworkImage(e.value.url,
                                          width: 78,
                                          height: 78,
                                          memWidth: 200)
                                      : Image.memory(e.value.picked!.bytes,
                                          fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => ref
                                        .read(composeProvider.notifier)
                                        .removeAttachment(e.key),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                        if (state.remainingSlots > 0)
                          GestureDetector(
                            onTap: () async {
                              // 남은 칸만큼만 고르게 한다 (한 칸이면 단일 선택기가 뜬다).
                              final picked = await ref
                                  .read(imageUploadServiceProvider)
                                  .pickMultiFromGallery(
                                      limit: state.remainingSlots);
                              ref
                                  .read(composeProvider.notifier)
                                  .addImages(picked);
                            },
                            child: Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.brMd,
                                color: AppColors.card,
                                border: Border.all(
                                    color: AppColors.line, width: 1.5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt_outlined,
                                      size: 20, color: AppColors.ink2),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${state.attachments.length}/$kMaxPostPhotos',
                                      style: AppTextStyles.monoXs.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.ink2)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

// ── 공통 위젯들 ─────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final bool required;
  final String? hint;
  final Widget child;

  const _Field({
    required this.label,
    this.required = false,
    this.hint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // 항목 하나 = 흰 카드 한 장. 캔버스 위에 밑줄로만 나눠 두면 입력칸이 어디서
    // 시작하는지 안 보였다(2026-10-19) — 다른 입력 화면과 같은 카드 결로.
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecor.cardRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: AppColors.ink2,
                ),
              ),
              if (required)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(hint!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.ink3)),
          ],
        ],
      ),
    );
  }
}

class _PaleTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;

  const _PaleTextField({
    required this.controller,
    required this.placeholder,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.body.copyWith(color: AppColors.ink),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle:
            AppTextStyles.body.copyWith(color: AppColors.ink3),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.brandAction, width: 1.5),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      ),
    );
  }
}

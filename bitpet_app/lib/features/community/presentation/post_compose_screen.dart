// 09 / 09b · 글 등록·수정 — PALE 디자인 핸드오프 반영
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_input_styles.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_toggle.dart';
import '../data/models/post_models.dart';
import '../providers/post_provider.dart';

// 게시판 탭 (전체 제외)
const _kCats = [
  ('free', '자유'),
  ('qna', 'QnA'),
  ('info', '정보'),
  ('sell', '분양'),
];

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
  final _tagCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cs = ref.read(composeProvider);
    _titleCtrl = TextEditingController(text: cs.title);
    _bodyCtrl = TextEditingController(text: cs.body);

    if (widget.isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final postAsync =
            ref.read(postDetailProvider(widget.postId!));
        postAsync.whenOrNull(data: (post) {
          if (post != null) {
            ref.read(composeProvider.notifier).prefill(post);
            setState(() {
              _titleCtrl.text = post.title;
              _bodyCtrl.text = post.content;
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag() {
    final raw = _tagCtrl.text.trim();
    if (raw.isEmpty) return;
    final tag = raw.startsWith('#') ? raw : '#$raw';
    ref.read(composeProvider.notifier).addTag(tag);
    _tagCtrl.clear();
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(composeProvider);

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── TopBar ──────────────────────────────────────────
            _TopBar(
              isEdit: widget.isEdit,
              canSubmit: state.canSubmit && !state.isSubmitting,
              isSubmitting: state.isSubmitting,
              onCancel: () => context.pop(),
              onSubmit: _submit,
            ),

            // ── 폼 본문 ─────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    22,
                    8,
                    22,
                    MediaQuery.of(context).viewInsets.bottom + 30),
                children: [
                  // ── 게시판 선택 ────────────────────────────────
                  _Field(
                    label: '게시판 선택',
                    required: true,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _kCats.map((c) {
                        final active = state.cat == c.$1;
                        return GestureDetector(
                          onTap: () => ref
                              .read(composeProvider.notifier)
                              .setCat(c.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.card,
                              border: Border.all(
                                color: active
                                    ? Colors.transparent
                                    : AppColors.paleLine,
                              ),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Text(
                              c.$2,
                              style: AppTextStyles.bodyBold.copyWith(
                                fontSize: 13,
                                color: active
                                    ? AppColors.paleBg
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
                      minLines: 7,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.primary, height: 1.6),
                      decoration: AppInputStyles.textarea(
                        hintText:
                            '자유롭게 작성해보세요.\n마크다운을 지원합니다.',
                        hintStyle: AppTextStyles.body
                            .copyWith(color: AppColors.paleInk3),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),

                  // ── 태그 ──────────────────────────────────────
                  _Field(
                    label: '태그',
                    hint: '최대 5개까지 추가할 수 있습니다.',
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...state.tags.map((tg) => _TagChip(
                              label: tg,
                              onRemove: () => ref
                                  .read(composeProvider.notifier)
                                  .removeTag(tg),
                            )),
                        if (state.tags.length < 5)
                          GestureDetector(
                            onTap: () => _showTagInput(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.paleLine,
                                    style: BorderStyle.solid),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text(
                                '+ 태그 추가',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.paleInk2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── 이미지 첨부 ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // 카메라 추가 박스
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            border: Border.all(
                              color: AppColors.paleLine,
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_outlined,
                                  size: 22, color: AppColors.paleInk2),
                              const SizedBox(height: 4),
                              Text(
                                '0/5',
                                style: AppTextStyles.monoXs.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.paleInk2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 옵션 카드 ──────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.paleLine),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Column(
                      children: [
                        _OptionRow(
                          label: '익명으로 작성',
                          sub: '닉네임 대신 익명으로 표시됩니다',
                          value: state.anonymous,
                          onToggle: () => ref
                              .read(composeProvider.notifier)
                              .toggleAnonymous(),
                          showDivider: true,
                        ),
                        _OptionRow(
                          label: '댓글 허용',
                          sub: '다른 사용자의 댓글을 받습니다',
                          value: state.allowComments,
                          onToggle: () => ref
                              .read(composeProvider.notifier)
                              .toggleAllowComments(),
                          showDivider: true,
                        ),
                        _OptionRow(
                          label: '알림 받기',
                          sub: '내 글에 댓글이 달리면 알림',
                          value: state.notify,
                          onToggle: () =>
                              ref.read(composeProvider.notifier).toggleNotify(),
                          showDivider: false,
                        ),
                      ],
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

  void _showTagInput(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('태그 추가',
            style: AppTextStyles.bodyBold.copyWith(fontSize: 15)),
        content: TextField(
          controller: _tagCtrl,
          autofocus: true,
          style: AppTextStyles.body.copyWith(color: AppColors.primary),
          decoration: InputDecoration(
            hintText: '#레오파드게코',
            hintStyle:
                AppTextStyles.body.copyWith(color: AppColors.paleInk3),
            prefixText: '# ',
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.paleLine),
            ),
          ),
          onSubmitted: (_) {
            _addTag();
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('취소', style: TextStyle(color: AppColors.paleInk2)),
          ),
          TextButton(
            onPressed: () {
              _addTag();
              Navigator.pop(context);
            },
            child: Text('추가',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ── 공통 위젯들 ─────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isEdit;
  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _TopBar({
    required this.isEdit,
    required this.canSubmit,
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: AppColors.paleBg,
      child: Row(
        children: [
          GestureDetector(
            onTap: onCancel,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                '취소',
                style: AppTextStyles.bodyBold.copyWith(
                  fontSize: 13,
                  color: AppColors.paleInk2,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  isEdit ? '글 수정' : '새 글 작성',
                  style: AppTextStyles.bodyBold
                      .copyWith(fontSize: 15, letterSpacing: -0.2),
                ),
                Text(
                  isEdit ? 'EDIT' : 'NEW',
                  style: AppTextStyles.monoXs,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: canSubmit ? onSubmit : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: canSubmit ? AppColors.primary : AppColors.paleLine,
                borderRadius: BorderRadius.zero,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.paleBg),
                    )
                  : Text(
                      '등록',
                      style: AppTextStyles.bodyBold.copyWith(
                        fontSize: 12,
                        color: AppColors.paleBg,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.paleLineSoft)),
      ),
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
                  color: AppColors.paleInk2,
                ),
              ),
              if (required)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Color(0xFFCC5522),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.paleInk3)),
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
      style: AppTextStyles.body.copyWith(color: AppColors.primary),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle:
            AppTextStyles.body.copyWith(color: AppColors.paleInk3),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.paleLine),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _TagChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: AppColors.paleBgAlt,
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.paleInk2,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  size: 11, color: AppColors.paleInk2),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final String sub;
  final bool value;
  final VoidCallback onToggle;
  final bool showDivider;

  const _OptionRow({
    required this.label,
    required this.sub,
    required this.value,
    required this.onToggle,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.paleInk3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppToggle(value: value, onToggle: onToggle),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
              height: 1, thickness: 1, color: AppColors.paleLineSoft),
      ],
    );
  }
}


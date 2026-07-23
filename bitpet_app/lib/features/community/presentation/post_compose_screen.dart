// 09 / 09b · 글 등록·수정 — 서버 카테고리 기반, 간소화
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_input_styles.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/post_provider.dart';

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
        final postAsync = ref.read(postDetailProvider(widget.postId!));
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
    final categories = ref.watch(visibleCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              isEdit: widget.isEdit,
              canSubmit: state.canSubmit && !state.isSubmitting,
              isSubmitting: state.isSubmitting,
              onCancel: () => context.pop(),
              onSubmit: _submit,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    22, 8, 22,
                    MediaQuery.of(context).viewInsets.bottom + 30),
                children: [
                  // ── 게시판 선택 ────────────────────────────────
                  _Field(
                    label: '게시판 선택',
                    required: true,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: categories.map((c) {
                        final active = state.categoryId == c.id;
                        return GestureDetector(
                          onTap: () => ref
                              .read(composeProvider.notifier)
                              .setCategory(c.id),
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
                              c.nameKo,
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
                      minLines: 8,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.primary, height: 1.6),
                      decoration: AppInputStyles.textarea(
                        hintText: '자유롭게 작성해보세요.',
                        hintStyle: AppTextStyles.body
                            .copyWith(color: AppColors.paleInk3),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
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

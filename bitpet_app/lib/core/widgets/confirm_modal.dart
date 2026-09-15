// 공통 확인 모달 — 센터 다이얼로그.
// 루틴 일괄 완료 모달(bulk_confirm_sheet)과 같은 문법: 헤더 밴드(아이콘 + 모노 라벨 + 제목),
// 본문, 상단 구분선이 있는 푸터(보조 취소 버튼 + 꽉 찬 확인 버튼). 직각.
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ConfirmModal extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDangerous;
  // 입력하지 않으면 일반 확인 모달, 값을 주면 그 문자열을 정확히 입력해야만 확인 가능
  final String? requireTextConfirmation;

  const ConfirmModal({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = '확인',
    this.cancelLabel = '취소',
    this.isDangerous = false,
    this.requireTextConfirmation,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = '확인',
    String cancelLabel = '취소',
    bool isDangerous = false,
    String? requireTextConfirmation,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x801C1610),
      builder: (_) => ConfirmModal(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDangerous: isDangerous,
        requireTextConfirmation: requireTextConfirmation,
      ),
    );
    return result ?? false;
  }

  @override
  State<ConfirmModal> createState() => _ConfirmModalState();
}

class _ConfirmModalState extends State<ConfirmModal> {
  final _controller = TextEditingController();
  bool _matched = false;

  bool get _requiresText => widget.requireTextConfirmation != null;
  bool get _canConfirm => !_requiresText || _matched;

  // 위험 동작은 연한 코랄 밴드 + 붉은 확인 버튼, 일반은 회색 밴드 + 검정 버튼
  Color get _bandColor =>
      widget.isDangerous ? AppColors.petCoral : AppColors.paleBgAlt;
  Color get _bandInk =>
      widget.isDangerous ? AppColors.petCoralInk : AppColors.paleInk2;
  Color get _confirmColor =>
      widget.isDangerous ? AppColors.error : AppColors.primary;
  // 위험 동작 중에서도 '삭제'만 휴지통 — 탈퇴·그만두기 같은 동작에 휴지통이 뜨면 어색하다
  bool get _isDelete =>
      widget.isDangerous && widget.confirmLabel.contains('삭제');
  IconData get _icon => _isDelete
      ? Icons.delete_outline
      : widget.isDangerous
          ? Icons.warning_amber_rounded
          : Icons.help_outline;
  String get _bandLabel =>
      _isDelete ? 'DELETE' : widget.isDangerous ? 'CAUTION' : 'CONFIRM';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    final matched = v == widget.requireTextConfirmation;
    if (matched != _matched) setState(() => _matched = matched);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bg,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 헤더 밴드 ──
            Container(
              color: _bandColor,
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    color: Colors.white.withValues(alpha: 0.62),
                    child: Icon(_icon, size: 22, color: _bandInk),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _bandLabel,
                          style: AppTextStyles.mono(10, FontWeight.w700,
                              color: _bandInk),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 본문 ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_requiresText) ...[
                      const SizedBox(height: 18),
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.paleInk2),
                          children: [
                            const TextSpan(text: '확인하려면 '),
                            TextSpan(
                              text: widget.requireTextConfirmation,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                            ),
                            const TextSpan(text: '을(를) 입력하세요'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        onChanged: _onChanged,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.paleBgAlt,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide:
                                  BorderSide(color: AppColors.paleLine)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide:
                                  BorderSide(color: AppColors.paleLine)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(
                                  color: AppColors.primary, width: 1.5)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── 푸터 ──
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        widget.cancelLabel,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _canConfirm
                          ? () => Navigator.pop(context, true)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        color: _canConfirm
                            ? _confirmColor
                            : AppColors.toggleOff,
                        child: Text(
                          widget.confirmLabel,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
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

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
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.divider),
      ),
      title: Text(widget.title, style: AppTextStyles.h3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message, style: AppTextStyles.body),
          if (_requiresText) ...[
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                style: AppTextStyles.caption,
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
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                border: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.border)),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(widget.cancelLabel),
        ),
        ElevatedButton(
          onPressed: (_requiresText && !_matched)
              ? null
              : () => Navigator.pop(context, true),
          style: widget.isDangerous
              ? ElevatedButton.styleFrom(backgroundColor: AppColors.error)
              : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ── Step configuration ──────────────────────────────────────────────────────

class StepConfig {
  final String title;
  final String? desc;
  final bool Function()? valid;
  final Widget Function(StepContext ctx) render;

  const StepConfig({
    required this.title,
    this.desc,
    this.valid,
    required this.render,
  });

  bool get isValid => valid == null || valid!();
}

class StepContext {
  final VoidCallback advance;
  final void Function(int) goEdit;
  const StepContext({required this.advance, required this.goEdit});
}

// ── StepShell ───────────────────────────────────────────────────────────────

/// Wizard step shell — TopBar, progress dots, animated body, footer.
/// Does NOT include a Scaffold; wrap in one if needed.
class StepShell extends StatefulWidget {
  final String headerTitle;
  final Color accentInk;
  final List<StepConfig> steps;
  final String doneLabel;
  final Future<void> Function()? onDone;
  final VoidCallback? onCancel;
  final int initialStep;

  const StepShell({
    super.key,
    required this.headerTitle,
    required this.accentInk,
    required this.steps,
    this.doneLabel = '완료',
    this.onDone,
    this.onCancel,
    this.initialStep = 0,
  });

  @override
  State<StepShell> createState() => _StepShellState();
}

class _StepShellState extends State<StepShell> {
  late int _idx;
  bool _submitting = false;
  int? _returnStep; // 확인 페이지에서 수정 진입 시 돌아올 스텝

  @override
  void initState() {
    super.initState();
    _idx = widget.initialStep.clamp(0, widget.steps.length - 1);
  }

  StepConfig get _step => widget.steps[_idx];
  bool get _isLast => _idx == widget.steps.length - 1;
  bool get _canNext => _step.isValid && !_submitting;

  void _goNext() {
    if (!_canNext) return;
    if (_isLast) {
      _done();
    } else if (_returnStep != null) {
      final ret = _returnStep!;
      setState(() { _idx = ret; _returnStep = null; });
    } else {
      setState(() => _idx++);
    }
  }

  void _goPrev() {
    if (_idx > 0) setState(() => _idx--);
  }

  void _advance() {
    final at = _idx;
    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted && _idx == at && _idx < widget.steps.length - 1) {
        setState(() => _idx++);
      }
    });
  }

  void _goEdit(int step) {
    if (step >= 0 && step < widget.steps.length) {
      setState(() { _returnStep = _idx; _idx = step; });
    }
  }

  Future<void> _done() async {
    if (widget.onDone == null) return;
    setState(() => _submitting = true);
    try {
      await widget.onDone!();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = StepContext(advance: _advance, goEdit: _goEdit);

    return Column(
      children: [
        _StepTopBar(
          idx: _idx,
          total: widget.steps.length,
          title: widget.headerTitle,
          onCancel: widget.onCancel,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepProgressDots(
                count: widget.steps.length,
                current: _idx,
                accentInk: widget.accentInk,
                onJump: (i) { if (i < _idx) setState(() => _idx = i); },
              ),
              const SizedBox(height: 14),
              Text(
                _step.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.primary,
                  letterSpacing: -0.4,
                ),
              ),
              if (_step.desc != null) ...[
                const SizedBox(height: 4),
                Text(
                  _step.desc!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.paleInk2,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.025),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_idx),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                child: _step.render(ctx),
              ),
            ),
          ),
        ),
        _StepFooter(
          idx: _idx,
          isLast: _isLast,
          canNext: _canNext,
          submitting: _submitting,
          doneLabel: widget.doneLabel,
          returnMode: _returnStep != null,
          onPrev: _goPrev,
          onNext: _goNext,
        ),
      ],
    );
  }
}

// ── TopBar ──────────────────────────────────────────────────────────────────

class _StepTopBar extends StatelessWidget {
  final int idx, total;
  final String title;
  final VoidCallback? onCancel;

  const _StepTopBar({
    required this.idx,
    required this.total,
    required this.title,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final VoidCallback backAction =
        onCancel ?? () => Navigator.of(context).maybePop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 4),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: TextButton(
              onPressed: backAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: AppColors.paleInk2,
              ),
              child: const Text(
                '뒤로',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.paleInk2,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.primary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${idx + 1} / $total',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.paleInk3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 68),
        ],
      ),
    );
  }
}

// ── Progress dots ───────────────────────────────────────────────────────────

class StepProgressDots extends StatelessWidget {
  final int count, current;
  final Color accentInk;
  final void Function(int)? onJump;

  const StepProgressDots({
    super.key,
    required this.count,
    required this.current,
    required this.accentInk,
    this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isCur = i == current;
        final isDone = i < current;
        return GestureDetector(
          onTap: isDone && onJump != null ? () => onJump!(i) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(right: i < count - 1 ? 6 : 0),
            width: isCur ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: isCur
                  ? accentInk
                  : isDone
                      ? AppColors.paleInk3
                      : AppColors.paleLine,
            ),
          ),
        );
      }),
    );
  }
}

// ── Footer ──────────────────────────────────────────────────────────────────

class _StepFooter extends StatelessWidget {
  final int idx;
  final bool isLast, canNext, submitting, returnMode;
  final String doneLabel;
  final VoidCallback onPrev, onNext;

  const _StepFooter({
    required this.idx,
    required this.isLast,
    required this.canNext,
    required this.submitting,
    required this.doneLabel,
    this.returnMode = false,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
      decoration: const BoxDecoration(
        color: AppColors.paleBg,
        border: Border(top: BorderSide(color: AppColors.paleLineSoft)),
      ),
      child: Row(
        children: [
          if (idx > 0) ...[
            GestureDetector(
              onTap: onPrev,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.paleLine),
                ),
                child: const Text(
                  '이전',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: GestureDetector(
              onTap: canNext ? onNext : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: canNext ? AppColors.primary : AppColors.paleLine,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: submitting
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.paleBg,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLast) ...[
                            Icon(
                              Icons.check,
                              size: 16,
                              color: canNext ? AppColors.paleBg : AppColors.paleInk3,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            isLast ? doneLabel : (returnMode ? '확인으로' : '다음'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: canNext ? AppColors.paleBg : AppColors.paleInk3,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── StepSummary ─────────────────────────────────────────────────────────────

class StepSummaryGroup {
  final String label;
  final int step;
  final List<StepSummaryRow> rows;
  const StepSummaryGroup({
    required this.label,
    required this.step,
    required this.rows,
  });
}

class StepSummaryRow {
  final String k, v;
  final bool muted;
  const StepSummaryRow({required this.k, required this.v, this.muted = false});
}

class StepSummary extends StatelessWidget {
  final List<StepSummaryGroup> groups;
  final void Function(int) goEdit;

  const StepSummary({super.key, required this.groups, required this.goEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: groups.map((g) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.paleLine),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => goEdit(g.step),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: const BoxDecoration(
                    color: AppColors.paleBgAlt,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Row(
                    children: [
                      Text(g.label, style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.paleInk2,
                      )),
                      const Spacer(),
                      const Text('수정 ', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary,
                      )),
                      const Icon(Icons.chevron_right, size: 14, color: AppColors.paleInk2),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: g.rows.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        border: i < g.rows.length - 1
                            ? const Border(bottom: BorderSide(color: AppColors.paleLineSoft))
                            : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.k, style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.paleInk3,
                          )),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              r.v.isEmpty ? '—' : r.v,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: r.muted ? AppColors.paleInk3 : AppColors.primary,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

// ── SField ─────────────────────────────────────────────────────────────────

/// Step body field label wrapper.
class SField extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const SField({super.key, required this.label, this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(label, style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: -0.2,
              )),
              if (hint != null) ...[
                const Spacer(),
                Text(hint!, style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.paleInk3,
                )),
              ],
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ── PALETextField ───────────────────────────────────────────────────────────

/// PALE-styled text input field.
class PaleTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? placeholder;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final int? maxLines;

  const PaleTextField({
    super.key,
    required this.controller,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.paleLine),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: maxLines != null && maxLines! > 1
            ? TextInputType.multiline
            : keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.paleInk3,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

// ── PaleSegment ─────────────────────────────────────────────────────────────

class PaleSegment extends StatelessWidget {
  final List<String> options;
  final String value;
  final void Function(String) onChange;

  const PaleSegment({
    super.key,
    required this.options,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.paleBgAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.paleLine),
      ),
      child: Row(
        children: options.map((o) {
          final sel = value == o;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChange(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: sel ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: sel
                      ? [const BoxShadow(color: Color(0x143A332B), blurRadius: 3)]
                      : null,
                ),
                child: Text(
                  o,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: sel ? AppColors.primary : AppColors.paleInk2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

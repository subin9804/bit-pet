import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_dimens.dart';
import 'confirm_modal.dart';

/// 스텝 폼의 좌우 기준선.
///
/// 앱 공통 [AppSpacing.screenH](24)보다 좁다. 이 화면은 제목·설명·입력칸이
/// 세로로 길게 이어지는 **폼**이라, 24로 띄우면 글이 화면 한가운데로 몰려
/// 왼쪽이 통째로 비어 보인다. 목록·카드 화면과 달리 왼쪽 가장자리가 그대로
/// 읽기 시작선이 되는 자리라 붙여 두는 쪽이 읽힌다.
///
/// ⚠️ `screenH` 를 고쳐서 맞추지 말 것 — 그러면 앱 전체가 같이 움직인다
/// (토큰 주석의 "특정 화면만 좁히려면 그 화면에서 명시하라"가 이 경우다).
const double _stepGutter = AppSpacing.lg;

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
  final bool confirmOnCancel;

  const StepShell({
    super.key,
    required this.headerTitle,
    required this.accentInk,
    required this.steps,
    this.doneLabel = '완료',
    this.onDone,
    this.onCancel,
    this.initialStep = 0,
    this.confirmOnCancel = false,
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
          confirmOnCancel: widget.confirmOnCancel,
        ),
        Padding(
          // 좌우는 `_stepGutter` 하나로 — 헤더·프로그레스·본문·푸터가 전부 같은 선에서
          // 시작해야 스텝을 넘겨도 기준선이 움직이지 않는다.
          padding: const EdgeInsets.fromLTRB(
              _stepGutter, AppSpacing.lg, _stepGutter, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepProgressDots(
                count: widget.steps.length,
                current: _idx,
                accentInk: widget.accentInk,
                onJump: (i) { if (i < _idx) setState(() => _idx = i); },
              ),
              const SizedBox(height: AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.xs),
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
              const SizedBox(height: AppSpacing.md),
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
                padding: const EdgeInsets.fromLTRB(
                    _stepGutter, 0, _stepGutter, AppSpacing.xl),
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
  final bool confirmOnCancel;

  const _StepTopBar({
    required this.idx,
    required this.total,
    required this.title,
    this.onCancel,
    this.confirmOnCancel = false,
  });

  @override
  Widget build(BuildContext context) {
    final VoidCallback rawCancel =
        onCancel ?? () => Navigator.of(context).maybePop();

    Future<void> handleCancel() async {
      if (!confirmOnCancel) { rawCancel(); return; }
      // 앱 공통 `ConfirmModal` 을 쓴다. 여기만 머티리얼 기본 `AlertDialog` 라
      // 모서리·버튼·여백이 다른 화면의 확인 모달과 전부 달랐다 — 같은 앱에서
      // 같은 질문을 두 가지 모양으로 하는 셈이었다.
      final confirmed = await ConfirmModal.show(
        context,
        title: '나가시겠어요?',
        message: '저장되지 않은 정보가 모두 삭제돼요.',
        confirmLabel: '나가기',
        cancelLabel: '계속 작성',
        isDangerous: true,
      );
      if (confirmed) rawCancel();
    }

    final VoidCallback backAction = () => handleCancel();

    // 제목은 **왼쪽 고정**이다. 가운데 정렬이면 제목 길이에 따라 글자가 좌우로 움직여
    // 스텝을 넘길 때마다 헤더가 흔들린다. 본문·프로그레스와 같은 `_stepGutter` 선에
    // 맞춰 세로로 읽히는 기준선을 하나만 둔다.
    // 오른쪽에서 8을 빼는 건 '뒤로'가 TextButton 이라 안쪽에 8을 더 물고 있어서다 —
    // 그대로 두면 글자 기준으로 8만큼 더 들어가 왼쪽과 어긋난다.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          _stepGutter, AppSpacing.sm, _stepGutter - 8, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 2),
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
          TextButton(
            onPressed: backAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: AppColors.paleInk2,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
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
            margin: EdgeInsets.only(right: i < count - 1 ? 8 : 0),
            width: isCur ? 24 : 6,
            height: 4,
            // 4px 짜리 막대라 알약이 아니면 끝이 잘린 조각처럼 보인다.
            decoration: BoxDecoration(
              borderRadius: AppRadius.brPill,
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
      padding: const EdgeInsets.fromLTRB(
          _stepGutter, AppSpacing.md, _stepGutter, AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.paleBg,
        border: Border(top: BorderSide(color: AppColors.paleLineSoft)),
      ),
      child: Row(
        children: [
          // 마지막(확인) 화면에는 '이전'을 두지 않는다. 그 화면은 항목마다
          // '수정'이 달려 있어 고칠 곳으로 **바로** 갈 수 있고, 한 칸씩 되짚는
          // 이전은 그보다 느린 길일 뿐이다. 저장 버튼도 그만큼 넓어진다.
          if (idx > 0 && !isLast) ...[
            GestureDetector(
              onTap: onPrev,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  borderRadius: AppRadius.brMd,
                  color: AppColors.surface,
                  border: Border.fromBorderSide(BorderSide(color: AppColors.paleLine)),
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.brMd,
                  color: canNext ? AppColors.primary : AppColors.paleLine,
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
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          // 안쪽 헤더 띠가 카드 모서리를 넘어가지 않도록 잘라낸다.
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            borderRadius: AppRadius.brLg,
            color: AppColors.surface,
            border: Border.fromBorderSide(BorderSide(color: AppColors.paleLine)),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => goEdit(g.step),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.paleBgAlt,
                    border: Border(bottom: BorderSide(color: AppColors.paleLineSoft)),
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
                      const AppIcon(AppIcons.chevronRight, size: 16, color: AppColors.paleInk2),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: g.rows.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
    return TextField(
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
          horizontal: 4,
          vertical: 12,
        ),
        suffixIcon: suffixIcon,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.paleLine),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.paleLine),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
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
    // 트랙은 입력칸(`AppRadius.brLg`)과 같은 모양이고, 선택칸은 그 안에 들어가므로
    // 한 단계 작은 `brMd` 다. 예전엔 트랙도 선택칸도 직각에 테두리만 있어서
    // 이 줄만 다른 앱에서 가져온 것처럼 보였다.
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        borderRadius: AppRadius.brLg,
        color: AppColors.paleBgAlt,
        border: Border.fromBorderSide(BorderSide(color: AppColors.paleLine)),
      ),
      child: Row(
        children: options.map((o) {
          final sel = value == o;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChange(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.brMd,
                  color: sel ? AppColors.surface : Colors.transparent,
                  // 선택 표시는 채움과 그림자로 충분하다. 테두리까지 더하면
                  // 트랙 테두리와 2겹이 되어 그 줄만 두꺼워 보인다.
                  boxShadow: sel
                      ? const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
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

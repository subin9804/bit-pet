// 클러치 상세 — 알 칸 + 날짜별 관찰 메모.
//
// 알 칸은 **누를 때마다 상태가 돌아간다**(대기 → 부화 → 무정 → 대기). 폼을 열어
// 상태를 고르게 하면 알 6개를 찍는 데 시트를 6번 열게 된다. 날짜를 직접 고치거나
// 실패(FAILED)로 바꾸는 건 드문 일이라 롱프레스로 숨겨 둔다.
//
// 개체로 등록된 알은 순환에서 빠진다 — 탭하면 그 개체 상세로 간다
// (서버도 `HATCH_ALREADY_REGISTERED` 로 막는다).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/toast_message.dart';
import '../../data/models/record_models.dart';
import '../../data/record_repository.dart';
import '../../providers/record_invalidation.dart';
import '../../providers/record_provider.dart';
import 'hatch_register_sheet.dart';

class ClutchDetailScreen extends ConsumerWidget {
  final int layingId;
  const ClutchDetailScreen({super.key, required this.layingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(layingDetailProvider(layingId));
    final petName = async.valueOrNull?.petName;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(petName == null ? '클러치' : '$petName의 클러치'),
        titleSpacing: 0,
      ),
      body: async.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => Center(
          child: Padding(
            padding: AppSpacing.screenPad,
            child: Text('클러치를 불러오지 못했어요.\n$e',
                style: AppTextStyles.caption, textAlign: TextAlign.center),
          ),
        ),
        data: (laying) => _Body(laying: laying),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final LayingRecord laying;
  const _Body({required this.laying});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerable = laying.registerableCount;

    return Column(
      children: [
        _SummaryLine(laying: laying),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async =>
                ref.refresh(layingDetailProvider(laying.id).future),
            color: AppColors.brandAction,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.x40),
              children: [
                _EggCard(laying: laying),
                const SizedBox(height: AppSpacing.cardGap),
                _NoteCard(laying: laying),
              ],
            ),
          ),
        ),
        // 부화했는데 아직 개체가 없는 알이 있을 때만 뜬다.
        if (registerable > 0)
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                MediaQuery.of(context).padding.bottom + AppSpacing.lg),
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _openRegisterSheet(
                  context,
                  laying,
                  laying.hatches.firstWhere((h) =>
                      h.status == HatchStatus.HATCHED && !h.isRegistered),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text('부화한 알 $registerable개 개체 등록'),
              ),
            ),
          ),
      ],
    );
  }
}

void _openRegisterSheet(
    BuildContext context, LayingRecord laying, HatchRecord hatch) {
  showAppSheet<void>(
    context: context,
    builder: (_) => HatchRegisterSheet(laying: laying, hatch: hatch),
  );
}

/// 면 없는 캡션 한 줄 — 개체 상세의 히어로 카드와 겹치지 않게 카드로 만들지 않는다.
class _SummaryLine extends StatelessWidget {
  final LayingRecord laying;
  const _SummaryLine({required this.laying});

  @override
  Widget build(BuildContext context) {
    final strong = AppTextStyles.caption
        .copyWith(fontWeight: FontWeight.w700, color: AppColors.ink);
    final env = <String>[
      if (laying.incubationTemp != null) '온도 ${_trim(laying.incubationTemp!)}℃',
      if (laying.incubationHumidity != null)
        '습도 ${_trim(laying.incubationHumidity!)}%',
    ].join(' / ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
      child: Text.rich(
        TextSpan(
          style: AppTextStyles.caption,
          children: [
            const TextSpan(text: '산란 '),
            TextSpan(text: _md(laying.laidAt), style: strong),
            const TextSpan(text: ' · 경과 '),
            TextSpan(text: 'D+${laying.daysSinceLaid}', style: strong),
            const TextSpan(text: ' · '),
            TextSpan(text: '${laying.totalCount}', style: strong),
            const TextSpan(text: '알'),
            if (env.isNotEmpty) TextSpan(text: ' · $env'),
          ],
        ),
      ),
    );
  }
}

// ── 알 칸 ─────────────────────────────────────────────────────

class _EggCard extends ConsumerWidget {
  final LayingRecord laying;
  const _EggCard({required this.laying});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eggs = [...laying.hatches]
      ..sort((a, b) => a.eggIndex.compareTo(b.eggIndex));

    return Container(
      decoration: AppDecor.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                  child: Text('알 ${laying.totalCount}개',
                      style: AppTextStyles.subheading)),
              if (laying.hatchedCount > 0)
                _CountChip(
                    label: '부화 ${laying.hatchedCount}',
                    bg: AppColors.brandTint,
                    fg: AppColors.brandTintInk),
              if (laying.pendingCount > 0)
                _CountChip(
                    label: '대기 ${laying.pendingCount}',
                    bg: AppColors.bgAlt,
                    fg: AppColors.ink2),
              if (laying.failedCount > 0)
                _CountChip(
                    label: '무정 ${laying.failedCount}',
                    bg: AppColors.petCoral,
                    fg: AppColors.petCoralInk),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.08,
            children: [
              for (final egg in eggs)
                _EggTile(
                  egg: egg,
                  onTap: () => _onTap(context, ref, egg),
                  onLongPress: () => _openEggSheet(context, egg),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '누를 때마다 대기 → 부화 → 무정 으로 바뀌어요\n'
            '길게 누르면 날짜를 고치거나 실패로 바꿀 수 있어요',
            style: AppTextStyles.label,
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, HatchRecord egg) {
    // 등록까지 끝난 알은 순환에서 빠진다 — 그 개체를 보러 가는 자리가 된다.
    if (egg.isRegistered) {
      context.push('/pets/${egg.hatchedPetId}');
      return;
    }
    _cycle(context, ref, egg);
  }

  Future<void> _cycle(
      BuildContext context, WidgetRef ref, HatchRecord egg) async {
    try {
      await ref.read(recordRepositoryProvider).cycleHatch(laying.id, egg.id);
      invalidatePetRecords(ref, laying.petId);
    } catch (_) {
      if (context.mounted) {
        showToast(context, '상태를 바꾸지 못했어요', type: ToastType.error);
      }
    }
  }

  void _openEggSheet(BuildContext context, HatchRecord egg) {
    showAppSheet<void>(
      context: context,
      builder: (_) => _EggOptionSheet(laying: laying, egg: egg),
    );
  }
}

class _EggTile extends StatelessWidget {
  final HatchRecord egg;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _EggTile({
    required this.egg,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final hatched = egg.status == HatchStatus.HATCHED;
    final failed =
        egg.status == HatchStatus.FAILED || egg.status == HatchStatus.SLUG;

    final bg = hatched
        ? AppColors.brandTintSoft
        : failed
            ? AppColors.petCoral
            : AppColors.bg;
    final titleColor = hatched
        ? AppColors.brandTintInk
        : failed
            ? AppColors.petCoralInk
            : AppColors.ink;

    final title = egg.isRegistered && egg.hatchedPetName != null
        ? '${egg.eggIndex}번 · ${egg.hatchedPetName}'
        : '${egg.eggIndex}번';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: onTap,
        // 등록된 알은 상태를 되돌릴 자리가 없다 — 개체를 지우는 일이다.
        onLongPress: egg.isRegistered ? null : onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.brMd,
            border: Border.all(
              color: hatched ? AppColors.brandAction : AppColors.line,
              width: hatched ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hatched)
                const Icon(Icons.check, size: 22, color: AppColors.brandAction)
              else if (failed)
                const Icon(Icons.close, size: 22, color: AppColors.petCoralInk)
              else
                const AppIcon(AppIcons.laying,
                    size: 22, color: AppColors.ink3),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700, color: titleColor)),
              const SizedBox(height: 2),
              _subLine(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subLine() {
    if (egg.isRegistered) {
      return Container(
        decoration: const BoxDecoration(
            color: AppColors.brandTint, borderRadius: AppRadius.brPill),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text('개체 등록됨',
            style:
                AppTextStyles.label.copyWith(color: AppColors.brandTintInk)),
      );
    }
    switch (egg.status) {
      case HatchStatus.HATCHED:
        return Text(
            egg.hatchedAt == null ? '부화' : '${_md(egg.hatchedAt!)} 부화',
            style: AppTextStyles.label.copyWith(color: AppColors.ink2));
      case HatchStatus.SLUG:
        return Text('무정란',
            style: AppTextStyles.label.copyWith(color: AppColors.petCoralInk));
      case HatchStatus.FAILED:
        return Text('실패',
            style: AppTextStyles.label.copyWith(color: AppColors.petCoralInk));
      case HatchStatus.PENDING:
        return Text('대기', style: AppTextStyles.label);
    }
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _CountChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brPill),
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      child: Text(label,
          style: AppTextStyles.label
              .copyWith(fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

/// 롱프레스로만 열리는 드문 조작 — 부화일 수정, 실패·무정 표시, 대기로 되돌리기.
class _EggOptionSheet extends ConsumerStatefulWidget {
  final LayingRecord laying;
  final HatchRecord egg;
  const _EggOptionSheet({required this.laying, required this.egg});

  @override
  ConsumerState<_EggOptionSheet> createState() => _EggOptionSheetState();
}

class _EggOptionSheetState extends ConsumerState<_EggOptionSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final egg = widget.egg;

    return AppSheet(
      title: '${egg.eggIndex}번 알',
      subtitle: '자주 쓰는 상태 변경은 알 칸을 누르면 돼요',
      child: Container(
        decoration: AppDecor.card,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            if (egg.status == HatchStatus.HATCHED)
              _row(
                icon: Icons.event,
                label: '부화일 바꾸기',
                sub: egg.hatchedAt == null ? null : _md(egg.hatchedAt!),
                onTap: _pickHatchedAt,
              ),
            if (egg.status != HatchStatus.FAILED)
              _row(
                icon: Icons.close,
                label: '실패로 표시',
                sub: '유정란이었지만 부화하지 못한 알',
                onTap: () => _setStatus(HatchStatus.FAILED),
              ),
            if (egg.status != HatchStatus.SLUG)
              _row(
                icon: Icons.remove_circle_outline,
                label: '무정란으로 표시',
                onTap: () => _setStatus(HatchStatus.SLUG),
              ),
            if (egg.status != HatchStatus.PENDING)
              _row(
                icon: Icons.undo,
                label: '대기로 되돌리기',
                onTap: () => _setStatus(HatchStatus.PENDING),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    String? sub,
    required VoidCallback onTap,
  }) {
    return ListTile(
      enabled: !_busy,
      dense: true,
      leading: Icon(icon, size: AppIconSize.md, color: AppColors.ink2),
      title: Text(label, style: AppTextStyles.body),
      subtitle: sub == null ? null : Text(sub, style: AppTextStyles.caption),
      onTap: onTap,
    );
  }

  Future<void> _pickHatchedAt() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.egg.hatchedAt ?? now,
      firstDate: widget.laying.laidAt,
      lastDate: now,
    );
    if (picked == null) return;
    await _save(HatchStatus.HATCHED, picked);
  }

  Future<void> _setStatus(HatchStatus status) => _save(
        status,
        status == HatchStatus.HATCHED ? DateTime.now() : null,
      );

  /// 대기·실패·무정으로 돌리면 부화일은 의미가 없어 null 로 비운다.
  Future<void> _save(HatchStatus status, DateTime? hatchedAt) async {
    setState(() => _busy = true);
    try {
      await ref.read(recordRepositoryProvider).updateHatch(
            widget.laying.id,
            widget.egg.id,
            {
              'status': status.name,
              'hatchedAt': hatchedAt == null ? null : _iso(hatchedAt),
            },
          );
      invalidatePetRecords(ref, widget.laying.petId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showToast(context, '바꾸지 못했어요', type: ToastType.error);
      }
    }
  }
}

// ── 관찰 메모 ─────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final LayingRecord laying;
  const _NoteCard({required this.laying});

  @override
  Widget build(BuildContext context) {
    final notes = [...laying.notes]
      ..sort((a, b) => b.notedAt.compareTo(a.notedAt));

    return Container(
      decoration: AppDecor.card,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text('관찰 메모', style: AppTextStyles.subheading)),
              TextButton(
                onPressed: () => _openNoteSheet(context, laying, null),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandAction,
                  minimumSize: const Size(0, 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  textStyle: AppTextStyles.caption
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                child: const Text('＋ 추가'),
              ),
            ],
          ),
          if (notes.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  0, AppSpacing.xs, 0, AppSpacing.lg),
              child: Text('캔들링 결과나 습도를 올린 날처럼, 날짜로 남길 일을 적어두세요.',
                  style: AppTextStyles.caption),
            )
          else
            for (final (i, note) in notes.indexed)
              InkWell(
                onTap: () => _openNoteSheet(context, laying, note),
                child: Container(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : const Border(
                            top: BorderSide(color: AppColors.bgAlt)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(_md(note.notedAt),
                            style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                          child: Text(note.content, style: AppTextStyles.body)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

void _openNoteSheet(
    BuildContext context, LayingRecord laying, LayingNote? note) {
  showAppSheet<void>(
    context: context,
    builder: (_) => _NoteSheet(laying: laying, note: note),
  );
}

class _NoteSheet extends ConsumerStatefulWidget {
  final LayingRecord laying;

  /// null 이면 새로 쓰는 것.
  final LayingNote? note;
  const _NoteSheet({required this.laying, this.note});

  @override
  ConsumerState<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends ConsumerState<_NoteSheet> {
  late final TextEditingController _content =
      TextEditingController(text: widget.note?.content ?? '');
  late DateTime _notedAt = widget.note?.notedAt ?? DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.note != null;

    return AppSheet(
      title: editing ? '관찰 메모 수정' : '관찰 메모',
      subtitle: '${widget.laying.petName ?? '클러치'} · D+${widget.laying.daysSinceLaid}',
      busy: _busy,
      primaryLabel: editing ? '수정' : '저장',
      onPrimary: _save,
      dateField: _DateField(
        value: _notedAt,
        firstDate: widget.laying.laidAt,
        onChanged: (d) => setState(() => _notedAt = d),
      ),
      child: Container(
        decoration: AppDecor.card,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _content,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              maxLength: 300,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: '예: 캔들링 — 3번 알 혈관이 안 보임, 무정 의심',
                counterText: '',
              ),
            ),
            if (editing)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : _delete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    textStyle: AppTextStyles.caption
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  child: const Text('삭제'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final content = _content.text.trim();
    if (content.isEmpty) {
      showToast(context, '내용을 적어주세요', type: ToastType.warning);
      return;
    }
    setState(() => _busy = true);
    final repo = ref.read(recordRepositoryProvider);
    try {
      if (widget.note == null) {
        await repo.addLayingNote(widget.laying.id, _notedAt, content);
      } else {
        await repo.updateLayingNote(
            widget.laying.id, widget.note!.id, _notedAt, content);
      }
      invalidatePetRecords(ref, widget.laying.petId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showToast(context, '저장하지 못했어요', type: ToastType.error);
      }
    }
  }

  Future<void> _delete() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(recordRepositoryProvider)
          .deleteLayingNote(widget.laying.id, widget.note!.id);
      invalidatePetRecords(ref, widget.laying.petId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showToast(context, '삭제하지 못했어요', type: ToastType.error);
      }
    }
  }
}

/// 슬롯 5 — 날짜 한 줄. 대개 오늘이라 안 건드린다.
class _DateField extends StatelessWidget {
  final DateTime value;
  final DateTime firstDate;
  final ValueChanged<DateTime> onChanged;

  const _DateField({
    required this.value,
    required this.firstDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.brMd,
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: firstDate,
          lastDate: now,
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        decoration: AppDecor.card,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.event, size: AppIconSize.sm, color: AppColors.ink3),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text('${value.year}. ${value.month}. ${value.day}',
                  style: AppTextStyles.body),
            ),
            Text('날짜', style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}

// ── 로딩 ──────────────────────────────────────────────────────

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonBox(width: 220, height: 14, borderRadius: AppRadius.sm),
          SizedBox(height: AppSpacing.lg),
          SkeletonBox(
              width: double.infinity,
              height: 280,
              borderRadius: AppRadius.lg),
          SizedBox(height: AppSpacing.cardGap),
          SkeletonBox(
              width: double.infinity,
              height: 160,
              borderRadius: AppRadius.lg),
        ],
      ),
    );
  }
}

String _md(DateTime d) => '${d.month}. ${d.day}';

String _trim(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// 서버의 `hatchedAt` 은 `OffsetDateTime` 이다 — 날짜만 보내면 파싱이 깨진다.
String _iso(DateTime d) => d.toUtc().toIso8601String();

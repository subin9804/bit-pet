import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/pale_palette.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/record_models.dart';
import '../data/record_repository.dart';
import '../providers/record_provider.dart';
import '../../pet/providers/pet_provider.dart';

class WeightScreen extends ConsumerStatefulWidget {
  final int petId;
  const WeightScreen({super.key, required this.petId});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  String _range = '3M'; // 1M / 3M / 6M / ALL
  final _entryCtrl = TextEditingController();
  bool _saving = false;
  DateTime _entryDate = DateTime.now();

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _entryDate = DateTime(
            picked.year, picked.month, picked.day,
            _entryDate.hour, _entryDate.minute,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final petAsync    = ref.watch(petDetailProvider(widget.petId));
    final weightsAsync = ref.watch(weightListProvider(widget.petId));

    return Scaffold(
      backgroundColor: AppColors.paleBg,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _TopBar(
              onBack: () => context.pop(),
              petName: petAsync.whenOrNull(data: (p) => p.name) ?? '',
            ),
          ),
          Expanded(
            child: weightsAsync.when(
              loading: () => const SkeletonCardList(),
              error:   (e, _) => Center(child: Text(e.toString())),
              data:    (records) {
                final paletteKey = PalePalette.keyFromHex(
                    petAsync.whenOrNull(data: (p) => p.colorCode));
                return _WeightBody(
                  petId:      widget.petId,
                  records:    records,
                  range:      _range,
                  onRange:    (r) => setState(() => _range = r),
                  entryCtrl:  _entryCtrl,
                  entryDate:  _entryDate,
                  onPickDate: _pickDate,
                  saving:     _saving,
                  paletteKey: paletteKey,
                  onSave:     _save,
                  onDelete:   _delete,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(List<WeightRecord> records) async {
    final w = double.tryParse(_entryCtrl.text);
    if (w == null || w <= 0) {
      showToast(context, '올바른 체중을 입력하세요', type: ToastType.error);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(recordRepositoryProvider)
          .addWeight(widget.petId, w, _entryDate, null);
      ref.invalidate(weightListProvider(widget.petId));
      ref.invalidate(petDetailProvider(widget.petId));
      if (mounted) {
        showToast(context, '체중이 기록되었습니다.', type: ToastType.success);
        _entryCtrl.clear();
        setState(() => _entryDate = DateTime.now());
      }
    } catch (e) {
      if (mounted) showToast(context, '오류: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(int id) async {
    try {
      await ref.read(recordRepositoryProvider).deleteWeight(id);
      ref.invalidate(weightListProvider(widget.petId));
      ref.invalidate(petDetailProvider(widget.petId));
      if (mounted) showToast(context, '기록을 삭제했어요.', type: ToastType.success);
    } catch (e) {
      if (mounted) showToast(context, '오류: $e', type: ToastType.error);
    }
  }
}

// ── TopBar ─────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final String petName;

  const _TopBar({required this.onBack, required this.petName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.paleLine),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.primary),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              const Text('몸무게 추이',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.primary, letterSpacing: -0.2)),
              if (petName.isNotEmpty)
                Text(petName.toUpperCase(),
                    style: AppTextStyles.monoXs),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// ── 본문 ────────────────────────────────────────────────────
class _WeightBody extends StatelessWidget {
  final int petId;
  final List<WeightRecord> records;
  final String range;
  final ValueChanged<String> onRange;
  final TextEditingController entryCtrl;
  final DateTime entryDate;
  final VoidCallback onPickDate;
  final bool saving;
  final PetPaletteKey paletteKey;
  final Future<void> Function(List<WeightRecord>) onSave;
  final Future<void> Function(int id) onDelete;

  const _WeightBody({
    required this.petId,
    required this.records,
    required this.range,
    required this.onRange,
    required this.entryCtrl,
    required this.entryDate,
    required this.onPickDate,
    required this.saving,
    required this.paletteKey,
    required this.onSave,
    required this.onDelete,
  });

  List<WeightRecord> _filtered() {
    if (records.isEmpty) return records;
    final sorted = [...records]
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    final now = DateTime.now();
    switch (range) {
      case '1M': return sorted.where((r) =>
          now.difference(r.measuredAt).inDays <= 31).toList();
      case '3M': return sorted.where((r) =>
          now.difference(r.measuredAt).inDays <= 92).toList();
      case '6M': return sorted.where((r) =>
          now.difference(r.measuredAt).inDays <= 183).toList();
      default:   return sorted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data    = _filtered();
    final latest  = records.isEmpty ? null
        : ([...records]..sort((a,b) => b.measuredAt.compareTo(a.measuredAt))).first;

    final maxW = data.isEmpty ? 0.0 : data.map((d) => d.weightG).reduce(max);
    final minW = data.isEmpty ? 0.0 : data.map((d) => d.weightG).reduce(min);
    final avg  = data.isEmpty ? 0.0 : data.map((d) => d.weightG).reduce((a,b)=>a+b)/data.length;
    final delta = data.length >= 2 ? data.last.weightG - data.first.weightG : 0.0;

    final pale    = PalePalette.pale(paletteKey);
    final paleInk = PalePalette.ink(paletteKey);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 큰 숫자 + 델타 pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                latest != null
                    ? latest.weightG.toStringAsFixed(0)
                    : '-',
                style: AppTextStyles.monoHero,
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('g',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColors.paleInk2)),
              ),
              if (data.length >= 2) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: delta >= 0
                          ? AppColors.petSage
                          : AppColors.petCoral,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      '${delta >= 0 ? '▲' : '▼'} ${delta.abs().toStringAsFixed(1)}g',
                      style: AppTextStyles.mono(12, FontWeight.w700,
                          color: delta >= 0
                              ? AppColors.petSageInk
                              : AppColors.petCoralInk),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (latest != null)
            Text(
              '최근 측정 · ${_fmtDate(latest.measuredAt)}',
              style: AppTextStyles.monoXs,
            ),
          const SizedBox(height: 16),

          // 기간 세그먼트
          _Segment(
            options: const ['1M', '3M', '6M', 'ALL'],
            value: range,
            onChange: onRange,
          ),
          const SizedBox(height: 16),

          // 큰 차트 (데이터 없어도 틀 표시)
          _BigWeightChart(data: data, pale: pale, paleInk: paleInk),
          const SizedBox(height: 16),

          // 통계 3분할
          Row(children: [
            _StatCard(label: '평균', value: '${avg.toStringAsFixed(1)}g'),
            const SizedBox(width: 8),
            _StatCard(label: '최대', value: '${maxW.toStringAsFixed(0)}g'),
            const SizedBox(width: 8),
            _StatCard(label: '최소', value: '${minW.toStringAsFixed(0)}g'),
          ]),
          const SizedBox(height: 22),

          // 새 기록 인라인 입력
          _SectionHeader(
            title: '새 기록',
            action: null,
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.paleLine),
              borderRadius: BorderRadius.zero,
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜 선택
                GestureDetector(
                  onTap: onPickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.paleBgAlt,
                      border: Border.all(color: AppColors.paleLine),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 13, color: AppColors.paleInk2),
                        const SizedBox(width: 6),
                        Text(
                          _fmtDate(entryDate),
                          style: AppTextStyles.mono(12, FontWeight.w600,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down,
                            size: 14, color: AppColors.paleInk3),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WEIGHT',
                              style: AppTextStyles.mono(11, FontWeight.w700,
                                  color: AppColors.paleInk2)),
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: entryCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: AppTextStyles.mono(28, FontWeight.w700),
                                    decoration: const InputDecoration.collapsed(hintText: '0'),
                                  ),
                                ),
                                Text('g', style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600,
                                    color: AppColors.paleInk2)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            latest != null
                                ? '직전 기록 ${latest.weightG.toStringAsFixed(0)}g'
                                : '첫 기록을 입력하세요',
                            style: TextStyle(fontSize: 11, color: AppColors.paleInk3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // +/- 스텝 버튼
                    Column(
                      children: [
                        AppStepperButton(
                          '+',
                          style: AppStepperStyle.boxed,
                          onTap: () {
                            final v = double.tryParse(entryCtrl.text) ?? 0;
                            entryCtrl.text = (v + 1).toStringAsFixed(0);
                          },
                        ),
                        const SizedBox(height: 4),
                        AppStepperButton(
                          '−',
                          style: AppStepperStyle.boxed,
                          onTap: () {
                            final v = double.tryParse(entryCtrl.text) ?? 0;
                            if (v > 0) entryCtrl.text = (v - 1).toStringAsFixed(0);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // 저장 버튼
                    GestureDetector(
                      onTap: saving ? null : () => onSave(records),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.zero,
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Row(children: [
                                const Icon(Icons.check, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text('저장',
                                    style: TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w700,
                                        color: AppColors.paleBg)),
                              ]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 기록 히스토리
          _SectionHeader(
            title: '기록 히스토리',
            action: records.isEmpty ? null : '전체 ${records.length}개',
          ),
          if (records.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.paleLine),
                borderRadius: BorderRadius.zero,
              ),
              child: const Column(
                children: [
                  Icon(Icons.monitor_weight_outlined,
                      size: 28, color: AppColors.paleInk3),
                  SizedBox(height: 8),
                  Text('저장된 기록이 없어요',
                      style: TextStyle(fontSize: 13, color: AppColors.paleInk2,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.paleLine),
                borderRadius: BorderRadius.zero,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: () {
                  final sorted = [...records]
                    ..sort((a,b) => b.measuredAt.compareTo(a.measuredAt));
                  final shown = sorted.take(20).toList();
                  return shown.asMap().entries.map((e) {
                    final i = e.key;
                    final r = e.value;
                    final prev = i < shown.length - 1 ? shown[i+1] : null;
                    final dlt  = prev != null ? r.weightG - prev.weightG : 0.0;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: i < shown.length - 1
                            ? const Border(bottom: BorderSide(
                                color: AppColors.paleLineSoft))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: pale, borderRadius: BorderRadius.zero,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _fmtDateShort(r.measuredAt),
                            style: AppTextStyles.mono(12, FontWeight.w600,
                                color: AppColors.paleInk2),
                          ),
                          const Spacer(),
                          Text(
                            '${r.weightG.toStringAsFixed(0)}g',
                            style: AppTextStyles.mono(14, FontWeight.w700),
                          ),
                          if (prev != null) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 48,
                              child: Text(
                                '${dlt > 0 ? '+' : ''}${dlt.toStringAsFixed(0)}g',
                                textAlign: TextAlign.right,
                                style: AppTextStyles.mono(11, FontWeight.w600,
                                    color: dlt > 0
                                        ? AppColors.petSageInk
                                        : dlt < 0
                                            ? AppColors.petCoralInk
                                            : AppColors.paleInk3),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          // 삭제 버튼
                          GestureDetector(
                            onTap: () => onDelete(r.id),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.paleBgAlt,
                                borderRadius: BorderRadius.zero,
                                border: Border.all(color: AppColors.paleLine),
                              ),
                              child: const Icon(Icons.delete_outline,
                                  size: 14, color: AppColors.paleInk3),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                }(),
              ),
            ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2,'0')}.${d.day.toString().padLeft(2,'0')}';

  String _fmtDateShort(DateTime d) =>
      '${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')}';

  String _fmtDateTime(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2,'0')}.${d.day.toString().padLeft(2,'0')} · ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}

// ── 큰 라인 차트 (CustomPainter) ─────────────────────────────
class _BigWeightChart extends StatelessWidget {
  final List<WeightRecord> data;
  final Color pale;
  final Color paleInk;

  const _BigWeightChart({
    required this.data,
    required this.pale,
    required this.paleInk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: SizedBox(
        height: 180,
        child: CustomPaint(
          painter: _BigChartPainter(
            data: data,
            pale: pale,
            paleInk: paleInk,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BigChartPainter extends CustomPainter {
  final List<WeightRecord> data;
  final Color pale;
  final Color paleInk;
  static const _padL = 28.0, _padR = 12.0, _padT = 18.0, _padB = 28.0;

  const _BigChartPainter({
    required this.data, required this.pale, required this.paleInk});

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width  - _padL - _padR;
    final ch = size.height - _padT - _padB;

    // 가이드라인 3개 (데이터 없어도 항상 표시)
    final guidePaint = Paint()
      ..color = AppColors.paleLine
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final dash = Path();
    for (int g = 0; g < 3; g++) {
      final gy = _padT + g * ch / 2;
      double x = _padL;
      while (x < size.width - _padR) {
        dash.moveTo(x, gy);
        dash.lineTo(min(x + 3, size.width - _padR), gy);
        x += 6;
      }
    }
    canvas.drawPath(dash, guidePaint);

    if (data.length < 2) return;

    final maxW  = data.map((d) => d.weightG).reduce(max);
    final minW  = data.map((d) => d.weightG).reduce(min);
    final range = max(maxW - minW, 1.0);

    List<Offset> pts = [];
    for (int i = 0; i < data.length; i++) {
      final x = _padL + (i / (data.length - 1)) * cw;
      final y = _padT + ch - ((data[i].weightG - minW) / range) * ch;
      pts.add(Offset(x, y));
    }

    // 좌측 라벨 (데이터 있을 때만)
    for (int g = 0; g < 3; g++) {
      final gy = _padT + g * ch / 2;
      final wVal = (maxW - g * (maxW - minW) / 2).toStringAsFixed(0);
      _drawText(canvas, wVal, Offset(_padL - 6, gy - 5),
          TextAlign.right, 9, AppColors.paleInk3);
    }

    // area fill
    final area = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) area.lineTo(p.dx, p.dy);
    area..lineTo(pts.last.dx, _padT + ch)
        ..lineTo(pts.first.dx, _padT + ch)
        ..close();
    canvas.drawPath(area,
        Paint()..color = pale.withValues(alpha: 0.7)..style = PaintingStyle.fill);

    // line
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) linePath.lineTo(p.dx, p.dy);
    canvas.drawPath(linePath,
        Paint()
          ..color = paleInk
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);

    // pixel dots (5×5 사각형)
    final dotPaint = Paint()..color = AppColors.primary;
    for (final p in pts) {
      canvas.drawRect(Rect.fromCenter(center: p, width: 5, height: 5), dotPaint);
    }

    // 마지막 값 pill
    final last = pts.last;
    final lastVal = '${data.last.weightG.toStringAsFixed(0)}g';
    final pillW = 38.0, pillH = 16.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(last.dx, last.dy - pillH),
            width: pillW, height: pillH),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.primary,
    );
    _drawText(canvas, lastVal,
        Offset(last.dx - pillW / 2, last.dy - pillH * 1.8),
        TextAlign.center, 10, Colors.white, bold: true);

    // x축 날짜 (5개 등간격)
    final step = max(1, (data.length / 5).ceil());
    for (int i = 0; i < data.length; i += step) {
      final p = pts[i];
      final d = data[i].measuredAt;
      final label = '${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')}';
      _drawText(canvas, label, Offset(p.dx, size.height - _padB + 4),
          TextAlign.center, 9, AppColors.paleInk3);
    }
  }

  void _drawText(Canvas canvas, String text, Offset origin,
      TextAlign align, double size, Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size, color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    final dx = switch (align) {
      TextAlign.center => origin.dx - tp.width / 2,
      TextAlign.right  => origin.dx - tp.width,
      _                => origin.dx,
    };
    tp.paint(canvas, Offset(dx, origin.dy));
  }

  @override
  bool shouldRepaint(_BigChartPainter old) =>
      old.data != data || old.pale != pale || old.paleInk != paleInk;
}

// ── 세그먼트 탭 ──────────────────────────────────────────────
class _Segment extends StatelessWidget {
  final List<String> options;
  final String value;
  final ValueChanged<String> onChange;

  const _Segment({required this.options, required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paleBgAlt,
        border: Border.all(color: AppColors.paleLine),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          final active = value == o;
          return GestureDetector(
            onTap: () => onChange(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? AppColors.card : Colors.transparent,
                border: active ? const Border(bottom: BorderSide(color: AppColors.paleInk2, width: 1.5)) : null,
                borderRadius: BorderRadius.zero,
              ),
              child: Text(
                o,
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.paleInk2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.paleLine),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.paleInk2)),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.monoMd),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.paleSectionTitle),
          if (action != null)
            Text(action!, style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.paleInk2)),
        ],
      ),
    );
  }
}


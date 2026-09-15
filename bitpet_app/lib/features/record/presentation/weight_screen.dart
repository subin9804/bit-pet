import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/pale_palette.dart';
import '../../../core/utils/weight_format.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/confirm_modal.dart';
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
    final ok = await ConfirmModal.show(
      context,
      title: '기록 삭제',
      message: '이 체중 기록을 삭제할까요?\n삭제하면 복구할 수 없습니다.',
      confirmLabel: '삭제',
      isDangerous: true,
    );
    if (!ok) return;
    try {
      await ref.read(recordRepositoryProvider).deleteWeight(id);
      ref.invalidate(weightListProvider(widget.petId));
      ref.invalidate(petDetailProvider(widget.petId));
      ref.invalidate(petCalendarProvider);
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
                latest != null ? formatWeight(latest.weightG) : '-',
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
                      '${delta >= 0 ? '▲' : '▼'} ${formatWeight(delta.abs())}g',
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
            // 평균은 계산값이라 소수 1자리로 정리한다. 최대·최소는 실측값 그대로
            _StatCard(label: '평균',
                value: data.isEmpty ? '-' : '${formatWeight(avg, maxDecimals: 1)}g'),
            const SizedBox(width: 8),
            _StatCard(label: '최대',
                value: data.isEmpty ? '-' : '${formatWeight(maxW)}g'),
            const SizedBox(width: 8),
            _StatCard(label: '최소',
                value: data.isEmpty ? '-' : '${formatWeight(minW)}g'),
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
                                ? '직전 기록 ${formatWeight(latest.weightG)}g'
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
                            // 52.5 에서 +1 → 53.5 (toStringAsFixed(0) 이면 54 로 튄다)
                            entryCtrl.text = formatWeight(v + 1);
                          },
                        ),
                        const SizedBox(height: 4),
                        AppStepperButton(
                          '−',
                          style: AppStepperStyle.boxed,
                          onTap: () {
                            final v = double.tryParse(entryCtrl.text) ?? 0;
                            if (v > 0) entryCtrl.text = formatWeight(max(v - 1, 0.0));
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
                            '${formatWeight(r.weightG)}g',
                            style: AppTextStyles.mono(14, FontWeight.w700),
                          ),
                          if (prev != null) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              // 소수 증감(+12.25g)도 한 줄에 들어가게
                              width: 60,
                              child: Text(
                                '${formatWeightDelta(dlt)}g',
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

  // 서버 시각(UTC)을 로컬(KST)로 변환해 표시 (이미 로컬이면 무해)
  String _fmtDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}.${d.month.toString().padLeft(2,'0')}.${d.day.toString().padLeft(2,'0')}';
  }

  String _fmtDateShort(DateTime dt) {
    final d = dt.toLocal();
    return '${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')}';
  }

  String _fmtDateTime(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}.${d.month.toString().padLeft(2,'0')}.${d.day.toString().padLeft(2,'0')} · ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }
}

// ── 큰 라인 차트 (CustomPainter) ─────────────────────────────
//
// - 0개: 가이드라인 틀 + "이 기간에 기록이 없어요"
// - 1개: 가운데 점 하나 + 값 라벨 (선은 없음)
// - 2개 이상: 영역 + 선 + 점
// 선택된 점(기본은 마지막)에 날짜·값 말풍선을 띄운다. 차트를 탭하거나 가로로 끌면
// 가장 가까운 점으로 선택이 옮겨간다.
class _BigWeightChart extends StatefulWidget {
  final List<WeightRecord> data;
  final Color pale;
  final Color paleInk;

  const _BigWeightChart({
    required this.data,
    required this.pale,
    required this.paleInk,
  });

  @override
  State<_BigWeightChart> createState() => _BigWeightChartState();
}

class _BigWeightChartState extends State<_BigWeightChart> {
  int? _selected; // null = 마지막 점

  @override
  void didUpdateWidget(covariant _BigWeightChart old) {
    super.didUpdateWidget(old);
    // 기간 탭이 바뀌거나 기록이 추가·삭제되면 인덱스가 다른 기록을 가리키게 되므로
    // 마지막 점으로 되돌린다. 목록은 부모가 빌드마다 새로 만들므로 참조가 아니라 내용(id)으로 비교
    if (!_sameIds(old.data, widget.data)) _selected = null;
  }

  static bool _sameIds(List<WeightRecord> a, List<WeightRecord> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _selectAt(double dx, double width) {
    final n = widget.data.length;
    if (n == 0) return;
    final idx = _ChartGeometry.nearestIndex(dx, width, n);
    if (idx != _selected) setState(() => _selected = idx);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: SizedBox(
        height: 200,
        child: LayoutBuilder(
          builder: (context, c) {
            final chart = CustomPaint(
              painter: _BigChartPainter(
                data: data,
                pale: widget.pale,
                paleInk: widget.paleInk,
                selected: data.isEmpty
                    ? null
                    : (_selected ?? data.length - 1).clamp(0, data.length - 1),
              ),
              child: const SizedBox.expand(),
            );
            if (data.isEmpty) {
              return Stack(
                children: [
                  chart,
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.show_chart,
                            size: 26, color: AppColors.paleInk3),
                        SizedBox(height: 6),
                        Text('이 기간에 기록이 없어요',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.paleInk2)),
                      ],
                    ),
                  ),
                ],
              );
            }
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _selectAt(d.localPosition.dx, c.maxWidth),
              onHorizontalDragStart: (d) =>
                  _selectAt(d.localPosition.dx, c.maxWidth),
              onHorizontalDragUpdate: (d) =>
                  _selectAt(d.localPosition.dx, c.maxWidth),
              child: chart,
            );
          },
        ),
      ),
    );
  }
}

/// painter 와 제스처가 같은 x 좌표 계산을 쓰도록 한 곳에 모은다.
class _ChartGeometry {
  static const padL = 40.0, padR = 16.0, padT = 18.0, padB = 28.0;

  static double xOf(int i, int n, double width) {
    final cw = width - padL - padR;
    if (n <= 1) return padL + cw / 2; // 한 개면 가운데
    return padL + (i / (n - 1)) * cw;
  }

  static int nearestIndex(double dx, double width, int n) {
    if (n <= 1) return 0;
    final cw = width - padL - padR;
    final t = ((dx - padL) / cw).clamp(0.0, 1.0);
    return (t * (n - 1)).round();
  }
}

class _BigChartPainter extends CustomPainter {
  final List<WeightRecord> data;
  final Color pale;
  final Color paleInk;
  final int? selected;

  const _BigChartPainter({
    required this.data,
    required this.pale,
    required this.paleInk,
    required this.selected,
  });

  static const _padL = _ChartGeometry.padL;
  static const _padR = _ChartGeometry.padR;
  static const _padT = _ChartGeometry.padT;
  static const _padB = _ChartGeometry.padB;

  @override
  void paint(Canvas canvas, Size size) {
    final ch = size.height - _padT - _padB;
    final bottom = _padT + ch;

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

    if (data.isEmpty) return;

    // y 범위 — 값이 하나이거나 전부 같으면 폭이 0이 되므로 위아래로 여유를 만든다.
    // 점이 틀 끝에 붙지 않게 범위의 10% 를 위아래로 더 준다.
    final rawMax = data.map((d) => d.weightG).reduce(max);
    final rawMin = data.map((d) => d.weightG).reduce(min);
    final spread = rawMax - rawMin;
    final margin = spread == 0 ? max(rawMax * 0.1, 1.0) : spread * 0.1;
    final top = rawMax + margin;
    final low = max(rawMin - margin, 0.0);
    final range = top - low;

    double yOf(double w) => _padT + ch - ((w - low) / range) * ch;

    final pts = [
      for (int i = 0; i < data.length; i++)
        Offset(_ChartGeometry.xOf(i, data.length, size.width),
            yOf(data[i].weightG)),
    ];

    // 좌측 y 라벨 — 범위가 좁으면 정수로 찍었을 때 세 줄이 같은 숫자가 되므로 소수 1자리
    final labelDecimals = range < 6 ? 1 : 0;
    for (int g = 0; g < 3; g++) {
      final gy = _padT + g * ch / 2;
      final v = top - g * range / 2;
      _drawText(canvas, formatWeight(v, maxDecimals: labelDecimals),
          Offset(_padL - 6, gy - 6), TextAlign.right, 9, AppColors.paleInk3);
    }

    if (pts.length >= 2) {
      // area fill
      final area = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        area.lineTo(p.dx, p.dy);
      }
      area
        ..lineTo(pts.last.dx, bottom)
        ..lineTo(pts.first.dx, bottom)
        ..close();
      canvas.drawPath(
          area,
          Paint()
            ..color = pale.withValues(alpha: 0.7)
            ..style = PaintingStyle.fill);

      // line
      final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        linePath.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
          linePath,
          Paint()
            ..color = paleInk
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
    }

    // x축 날짜 — 최대 5개. 첫·마지막은 항상 찍고 가운데는 등간격
    final labelIdx = <int>{};
    if (data.length <= 5) {
      labelIdx.addAll(List.generate(data.length, (i) => i));
    } else {
      for (int k = 0; k < 5; k++) {
        labelIdx.add(((data.length - 1) * k / 4).round());
      }
    }
    for (final i in labelIdx) {
      final d = data[i].measuredAt.toLocal();
      final label =
          '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
      _drawText(canvas, label, Offset(pts[i].dx, size.height - _padB + 8),
          TextAlign.center, 9, AppColors.paleInk3,
          clampWidth: size.width);
    }

    // 선택 세로선
    final sel = selected;
    if (sel != null) {
      final p = pts[sel];
      final vline = Path();
      double y = _padT;
      while (y < bottom) {
        vline.moveTo(p.dx, y);
        vline.lineTo(p.dx, min(y + 3, bottom));
        y += 6;
      }
      canvas.drawPath(
          vline,
          Paint()
            ..color = AppColors.paleInk3
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke);
    }

    // 점 (5×5 사각형)
    final dotPaint = Paint()..color = AppColors.primary;
    for (int i = 0; i < pts.length; i++) {
      if (i == sel) continue;
      canvas.drawRect(
          Rect.fromCenter(center: pts[i], width: 5, height: 5), dotPaint);
    }

    if (sel == null) return;

    // 선택 점 강조 — 흰 테두리 있는 큰 사각형
    final sp = pts[sel];
    canvas.drawRect(Rect.fromCenter(center: sp, width: 11, height: 11),
        Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromCenter(center: sp, width: 9, height: 9),
        Paint()..color = AppColors.primary);

    _drawTooltip(canvas, size, sp, data[sel]);
  }

  /// 말풍선 — 텍스트 크기를 실제로 재서 박스를 만들고, 차트 밖으로 나가지 않게 가둔다.
  /// (이전엔 박스 폭 38px 고정 + 텍스트 위치를 따로 계산해서 글자가 박스를 벗어나
  /// 검은 네모만 보였다)
  void _drawTooltip(Canvas canvas, Size size, Offset anchor, WeightRecord r) {
    final d = r.measuredAt.toLocal();
    final valueTp = TextPainter(
      text: TextSpan(
        text: '${formatWeight(r.weightG)}g',
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dateTp = TextPainter(
      text: TextSpan(
        text:
            '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}',
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const padH = 9.0, padV = 5.0, gap = 1.0, offsetY = 12.0;
    final w = max(valueTp.width, dateTp.width) + padH * 2;
    final h = dateTp.height + gap + valueTp.height + padV * 2;

    // 위에 자리가 없으면 점 아래로
    var boxTop = anchor.dy - offsetY - h;
    if (boxTop < 0) boxTop = anchor.dy + offsetY;
    final boxLeft =
        (anchor.dx - w / 2).clamp(0.0, max(0.0, size.width - w));
    final rect = Rect.fromLTWH(boxLeft, boxTop, w, h);

    canvas.drawRect(rect, Paint()..color = AppColors.primary);
    dateTp.paint(canvas,
        Offset(rect.left + (w - dateTp.width) / 2, rect.top + padV));
    valueTp.paint(
        canvas,
        Offset(rect.left + (w - valueTp.width) / 2,
            rect.top + padV + dateTp.height + gap));
  }

  void _drawText(Canvas canvas, String text, Offset origin, TextAlign align,
      double size, Color color,
      {bool bold = false, double? clampWidth}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    var dx = switch (align) {
      TextAlign.center => origin.dx - tp.width / 2,
      TextAlign.right => origin.dx - tp.width,
      _ => origin.dx,
    };
    if (clampWidth != null) {
      dx = dx.clamp(0.0, max(0.0, clampWidth - tp.width));
    }
    tp.paint(canvas, Offset(dx, origin.dy));
  }

  @override
  bool shouldRepaint(_BigChartPainter old) =>
      old.data != data ||
      old.pale != pale ||
      old.paleInk != paleInk ||
      old.selected != selected;
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


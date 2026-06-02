import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pale_palette.dart';
import '../../../../features/record/data/models/record_models.dart';
import '../../../../features/record/providers/record_provider.dart';

// ── 카테고리 메타 ─────────────────────────────────────────────
class _CatMeta {
  final String label;
  final IconData icon;
  const _CatMeta(this.label, this.icon);
}

const _catMeta = {
  'WEIGHT':  _CatMeta('체중',   Icons.monitor_weight_outlined),
  'FEEDING': _CatMeta('먹이',   Icons.restaurant_outlined),
  'CLEANING':_CatMeta('청소',   Icons.cleaning_services_outlined),
  'MEMO':    _CatMeta('메모',   Icons.note_alt_outlined),
  'MATING':  _CatMeta('메이팅', Icons.favorite_outline),
  'LAYING':  _CatMeta('산란',   Icons.egg_outlined),
};

// API 카테고리 코드 → UI 표시용 key (PalePalette.catPale/catInk에서 사용)
String _paleCatKey(String apiCat) => apiCat; // 이미 WEIGHT/FEEDING/... 형식

// 체중 스파크라인 데이터 포인트
class WeightPoint {
  final double w;
  const WeightPoint(this.w);
}

// ── RecordTab ────────────────────────────────────────────────
class RecordTab extends ConsumerStatefulWidget {
  final int petId;
  final PetPaletteKey paletteKey;

  const RecordTab({super.key, required this.petId, required this.paletteKey});

  @override
  ConsumerState<RecordTab> createState() => _RecordTabState();
}

class _RecordTabState extends ConsumerState<RecordTab> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedDay = DateTime.now().day;

  void _navMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDay = 1;
    });
  }

  String get _ymStr =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  String get _selDateStr =>
      '$_ymStr-${_selectedDay.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final weightsAsync  = ref.watch(weightListProvider(widget.petId));
    final calendarAsync = ref.watch(
        petCalendarProvider(PetYearMonth(widget.petId, _ymStr)));
    final dayAsync      = ref.watch(
        petDayTimelineProvider(PetDateParam(widget.petId, _selDateStr)));
    final summaryAsync  = ref.watch(petRecordSummaryProvider(widget.petId));

    const weekKo = ['일','월','화','수','목','금','토'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 요약 카드 2열 그리드 ──────────────────────────────
        _buildSummaryGrid(context, summaryAsync, weightsAsync),
        const SizedBox(height: 14),

        // ── 캘린더 카드 ───────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.paleLine),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            children: [
              // 캘린더 헤더
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 7),
                  const Text('캘린더',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _navMonth(-1),
                    child: const Icon(Icons.chevron_left, size: 18,
                        color: AppColors.paleInk3),
                  ),
                  Text(
                    '${_month.year}년 ${_month.month}월',
                    style: AppTextStyles.mono(12, FontWeight.w700,
                        color: AppColors.paleInk2),
                  ),
                  GestureDetector(
                    onTap: () => _navMonth(1),
                    child: const Icon(Icons.chevron_right, size: 18,
                        color: AppColors.paleInk3),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _RecordCalendar(
                month: _month,
                selectedDay: _selectedDay,
                calendarAsync: calendarAsync,
                onSelect: (d) => setState(() => _selectedDay = d),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── 선택일 기록 헤더 ──────────────────────────────────
        Builder(builder: (_) {
          final selDate = DateTime(_month.year, _month.month, _selectedDay);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.paleSectionTitle,
                  children: [
                    TextSpan(text: '${_month.month}.$_selectedDay '),
                    TextSpan(
                      text: '(${weekKo[selDate.weekday % 7]})',
                      style: const TextStyle(
                          color: AppColors.paleInk2, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              dayAsync.whenOrNull(data: (items) =>
                Text('${items.length}건',
                    style: AppTextStyles.mono(12, FontWeight.w700,
                        color: AppColors.paleInk2))) ??
                const SizedBox.shrink(),
            ],
          );
        }),
        const SizedBox(height: 4),

        // ── 선택일 타임라인 리스트 ────────────────────────────
        _buildDayList(dayAsync),
      ],
    );
  }

  // ── 요약 카드 그리드 ─────────────────────────────────────────
  Widget _buildSummaryGrid(
    BuildContext context,
    AsyncValue<List<TimelineItem>> summaryAsync,
    AsyncValue<List<WeightRecord>> weightsAsync,
  ) {
    // 카테고리별 최신 1건 추출
    final latestByCategory = <String, TimelineItem>{};
    summaryAsync.whenOrNull(data: (items) {
      for (final item in items) {
        latestByCategory.putIfAbsent(item.category, () => item);
      }
    });

    // 스파크라인용 체중 데이터
    final weightPoints = weightsAsync.whenOrNull(data: (records) {
      final sorted = [...records]
        ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
      return sorted.map((r) => WeightPoint(r.weightG)).toList();
    });

    final categories = ['WEIGHT', 'FEEDING', 'CLEANING', 'MEMO', 'MATING', 'LAYING'];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: categories.map((cat) {
        final item    = latestByCategory[cat];
        final meta    = _catMeta[cat];
        final isEmpty = item == null;
        final isLoading = summaryAsync is AsyncLoading;

        return GestureDetector(
          onTap: () {
            if (cat == 'WEIGHT')  context.push('/pets/${widget.petId}/weight');
            if (cat == 'FEEDING') context.push('/pets/${widget.petId}/feeding');
          },
          child: Opacity(
            opacity: isEmpty && !isLoading ? 0.72 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.paleLine),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
              child: isLoading
                  ? const Center(child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(meta?.icon ?? Icons.circle,
                              size: 14,
                              color: PalePalette.catInk(_paleCatKey(cat))),
                          const SizedBox(width: 6),
                          Text(meta?.label ?? cat,
                              style: AppTextStyles.paleCatLabel),
                        ]),
                        const SizedBox(height: 11),
                        Text(
                          isEmpty ? '—' : item.summary,
                          style: AppTextStyles.paleValue.copyWith(
                              color: isEmpty
                                  ? AppColors.paleInk3
                                  : AppColors.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEmpty
                              ? '기록 없음'
                              : _agoLabel(item.recordedAt),
                          style: AppTextStyles.paleMeta,
                        ),
                        if (cat == 'WEIGHT' &&
                            weightPoints != null &&
                            weightPoints.length >= 2) ...[
                          const Spacer(),
                          RecordSparkline(
                            data: weightPoints.map((p) => p.w).toList(),
                            strokeColor: PalePalette.catInk('WEIGHT'),
                            fillColor: PalePalette.catPale('WEIGHT'),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayList(AsyncValue<List<TimelineItem>> dayAsync) {
    return dayAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Center(child: Text('오류: $e',
            style: TextStyle(color: AppColors.error, fontSize: 12))),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: Text('이 날의 기록이 없어요',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.paleInk3)),
            ),
          );
        }
        return Column(
          children: items.asMap().entries.map((e) {
            final i    = e.key;
            final item = e.value;
            final meta = _catMeta[item.category];
            return Container(
              decoration: BoxDecoration(
                border: i < items.length - 1
                    ? const Border(bottom: BorderSide(
                        color: AppColors.paleLineSoft))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
              child: Row(
                children: [
                  Container(
                    width: 9, height: 9,
                    decoration: BoxDecoration(
                      color: PalePalette.catInk(_paleCatKey(item.category)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(meta?.label ?? item.category,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.summary,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.paleInk2)),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _agoLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24)  return '${diff.inHours}시간 전';
    if (diff.inDays == 1)   return '어제';
    if (diff.inDays < 30)   return '${diff.inDays}일 전';
    return '${dt.month}.${dt.day}';
  }
}

// ── 스파크라인 (CustomPainter) ─────────────────────────────
class RecordSparkline extends StatelessWidget {
  final List<double> data;
  final Color strokeColor;
  final Color fillColor;

  const RecordSparkline({
    super.key,
    required this.data,
    required this.strokeColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: CustomPaint(
        painter: _SparklinePainter(
          data: data,
          strokeColor: strokeColor,
          fillColor: fillColor,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color strokeColor;
  final Color fillColor;

  const _SparklinePainter({
    required this.data, required this.strokeColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final maxW  = data.reduce(max);
    final minW  = data.reduce(min);
    final range = max(maxW - minW, 1.0);
    final W = size.width, H = size.height;

    final pts = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      pts.add(Offset(
        (i / (data.length - 1)) * W,
        (H - 3) - ((data[i] - minW) / range) * (H - 8),
      ));
    }

    final area = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) area.lineTo(p.dx, p.dy);
    area..lineTo(W, H)..lineTo(0, H)..close();
    canvas.drawPath(
        area,
        Paint()
          ..color = fillColor.withValues(alpha: 0.55)
          ..style = PaintingStyle.fill);

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) line.lineTo(p.dx, p.dy);
    canvas.drawPath(
        line,
        Paint()
          ..color = strokeColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.data != data || old.strokeColor != strokeColor;
}

// ── 월 캘린더 ─────────────────────────────────────────────────
class _RecordCalendar extends StatelessWidget {
  final DateTime month;
  final int selectedDay;
  final AsyncValue<List<CalendarDay>> calendarAsync;
  final ValueChanged<int> onSelect;

  const _RecordCalendar({
    required this.month,
    required this.selectedDay,
    required this.calendarAsync,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // CalendarDay[] → {day: categories} 맵 변환
    final catsByDay = <int, List<String>>{};
    calendarAsync.whenOrNull(data: (days) {
      for (final d in days) {
        final day = int.tryParse(d.date.substring(8)) ?? 0;
        catsByDay[day] = d.categories;
      }
    });

    const weekKo = ['일', '월', '화', '수', '목', '금', '토'];
    final firstWD    = DateTime(month.year, month.month, 1).weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final header = Row(
      children: List.generate(7, (i) => Expanded(
        child: Text(weekKo[i],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: i == 0
                  ? AppColors.petCoralInk
                  : i == 6 ? AppColors.petSkyInk : AppColors.paleInk3,
            )),
      )),
    );

    final rows = <Widget>[header, const SizedBox(height: 4)];
    final cells = [
      ...List<int?>.filled(firstWD, null),
      ...List.generate(daysInMonth, (i) => i + 1),
    ];
    for (int r = 0; r < (cells.length / 7).ceil(); r++) {
      rows.add(Row(
        children: List.generate(7, (c) {
          final idx = r * 7 + c;
          if (idx >= cells.length || cells[idx] == null) {
            return const Expanded(child: SizedBox(height: 38));
          }
          final d    = cells[idx]!;
          final sel  = d == selectedDay;
          final today = d == DateTime.now().day &&
              month.year == DateTime.now().year &&
              month.month == DateTime.now().month;
          final cats = catsByDay[d] ?? [];

          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(d),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28, height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary
                            : today ? AppColors.paleBgAlt : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$d',
                        style: AppTextStyles.mono(
                          13, sel ? FontWeight.w700 : FontWeight.w600,
                          color: sel ? AppColors.paleBg : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: cats.take(3).map((cat) => Container(
                          width: 4, height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: PalePalette.catInk(_paleCatKey(cat)),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

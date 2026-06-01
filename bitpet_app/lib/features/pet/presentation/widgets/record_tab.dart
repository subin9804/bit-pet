import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pale_palette.dart';

// 카테고리 메타
class _CatMeta {
  final String label;
  final IconData icon;
  final String key;
  const _CatMeta(this.label, this.icon, this.key);
}

const _cats = {
  'weight': _CatMeta('체중',   Icons.monitor_weight_outlined, 'weight'),
  'feed':   _CatMeta('먹이',   Icons.restaurant_outlined,     'feed'),
  'clean':  _CatMeta('청소',   Icons.cleaning_services_outlined,'clean'),
  'memo':   _CatMeta('메모',   Icons.note_alt_outlined,       'memo'),
  'mating': _CatMeta('메이팅', Icons.favorite_outline,        'mating'),
  'laying': _CatMeta('산란',   Icons.egg_outlined,            'laying'),
};

class _RecSummary {
  final String cat;
  final String value;
  final String meta;
  final bool mono;
  final bool empty;
  final List<WeightPoint>? sparkData;

  const _RecSummary({
    required this.cat,
    required this.value,
    required this.meta,
    this.mono = false,
    this.empty = false,
    this.sparkData,
  });
}

// 체중 스파크라인 데이터 포인트
class WeightPoint {
  final double w;
  const WeightPoint(this.w);
}

class RecordTab extends StatefulWidget {
  final int petId;
  final PetPaletteKey paletteKey;

  const RecordTab({super.key, required this.petId, required this.paletteKey});

  @override
  State<RecordTab> createState() => _RecordTabState();
}

class _RecordTabState extends State<RecordTab> {
  // 현재 표시 연월 (예: 2026-05)
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedDay = DateTime.now().day;

  // mock 요약 카드 데이터 (추후 API 대체)
  static const _summaries = [
    _RecSummary(
      cat: 'weight', value: '76g', meta: '+1g · 3일 전',
      mono: true,
      sparkData: [
        WeightPoint(68), WeightPoint(70), WeightPoint(71),
        WeightPoint(73), WeightPoint(72), WeightPoint(74),
        WeightPoint(75), WeightPoint(76),
      ],
    ),
    _RecSummary(cat: 'feed',   value: '귀뚜라미', meta: '×5 · 1일 전'),
    _RecSummary(cat: 'clean',  value: '전체 청소', meta: '5일 전'),
    _RecSummary(cat: 'memo',   value: '탈피 시작', meta: '2일 전 · 12건'),
    _RecSummary(cat: 'mating', value: '합사 45분', meta: '시즌 중 · 12일 전'),
    _RecSummary(cat: 'laying', value: '—',       meta: '기록 없음', empty: true),
  ];

  // mock 일별 기록 (추후 getCalendar API 대체)
  static const Map<int, List<Map<String, String>>> _dayLog = {
    3:  [{'cat':'weight','text':'73g (−1g)'},{'cat':'feed','text':'귀뚜라미 × 4 완식'}],
    5:  [{'cat':'feed','text':'밀웜 × 3'}],
    8:  [{'cat':'weight','text':'74g (+1g)'},{'cat':'feed','text':'귀뚜라미 × 5'},{'cat':'mating','text':'합사 30분 · 거부'}],
    11: [{'cat':'memo','text':'바닥재 교체 · 습도 65 조정'}],
    14: [{'cat':'weight','text':'75g (±0g)'}],
    17: [{'cat':'memo','text':'탈피 징후 — 체색 흐려짐'}],
    21: [{'cat':'mating','text':'합사 40분 · 관심 보임'}],
    24: [{'cat':'weight','text':'76g (+1g)'},{'cat':'feed','text':'귀뚜라미 × 5 완식'}],
    27: [{'cat':'feed','text':'귀뚜라미 × 5'}],
  };

  void _navMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDay = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayRecs = _dayLog[_selectedDay] ?? [];
    final selDate = DateTime(_month.year, _month.month, _selectedDay);
    const weekKo  = ['일','월','화','수','목','금','토'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 요약 카드 2열 그리드
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.2,
          children: _summaries.map((s) => _SummaryCard(
            s: s,
            petId: widget.petId,
            paletteKey: widget.paletteKey,
          )).toList(),
        ),
        const SizedBox(height: 14),

        // 캘린더 카드
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
                dayLog: _dayLog,
                onSelect: (d) => setState(() => _selectedDay = d),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // 선택일 기록 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: AppTextStyles.paleSectionTitle,
                children: [
                  TextSpan(text: '${_month.month}.${_selectedDay} '),
                  TextSpan(
                    text: '(${weekKo[selDate.weekday % 7]})',
                    style: TextStyle(
                        color: AppColors.paleInk2, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Text(
              '${dayRecs.length}건',
              style: AppTextStyles.mono(12, FontWeight.w700,
                  color: AppColors.paleInk2),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // 선택일 기록 리스트
        if (dayRecs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: Text('이 날의 기록이 없어요',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.paleInk3)),
            ),
          )
        else
          ...dayRecs.asMap().entries.map((e) {
            final i = e.key;
            final r = e.value;
            final cat  = r['cat'] ?? 'memo';
            final meta = _cats[cat];
            final catCode = switch (cat) {
              'weight' => 'WEIGHT', 'feed' => 'FEEDING', 'clean' => 'CLEANING',
              'memo' => 'MEMO', 'mating' => 'MATING', 'laying' => 'LAYING', _ => 'MEMO',
            };
            return Container(
              decoration: BoxDecoration(
                border: i < dayRecs.length - 1
                    ? const Border(
                        bottom: BorderSide(color: AppColors.paleLineSoft))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
              child: Row(
                children: [
                  Container(
                    width: 9, height: 9,
                    decoration: BoxDecoration(
                      color: PalePalette.catInk(catCode),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    meta?.label ?? cat,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r['text'] ?? '',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.paleInk2),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ── 요약 카드 ───────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final _RecSummary s;
  final int petId;
  final PetPaletteKey paletteKey;

  const _SummaryCard({
    required this.s, required this.petId, required this.paletteKey});

  @override
  Widget build(BuildContext context) {
    final catCode = switch (s.cat) {
      'weight' => 'WEIGHT', 'feed' => 'FEEDING', 'clean' => 'CLEANING',
      'memo' => 'MEMO', 'mating' => 'MATING', 'laying' => 'LAYING', _ => 'MEMO',
    };
    final catInkColor  = PalePalette.catInk(catCode);
    final catPaleColor = PalePalette.catPale(catCode);
    final meta = _cats[s.cat];

    return GestureDetector(
      onTap: () {
        if (s.cat == 'weight') context.push('/pets/$petId/weight');
        if (s.cat == 'feed')   context.push('/pets/$petId/feeding');
      },
      child: Opacity(
        opacity: s.empty ? 0.72 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.paleLine),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(meta?.icon ?? Icons.circle,
                      size: 14, color: catInkColor),
                  const SizedBox(width: 6),
                  Text(meta?.label ?? s.cat, style: AppTextStyles.paleCatLabel),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                s.value,
                style: s.mono
                    ? AppTextStyles.mono(17, FontWeight.w700,
                        color: s.empty ? AppColors.paleInk3 : AppColors.primary)
                    : AppTextStyles.paleValue.copyWith(
                        color: s.empty ? AppColors.paleInk3 : AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(s.meta, style: AppTextStyles.paleMeta),
              if (s.sparkData != null) ...[
                const Spacer(),
                RecordSparkline(
                  data: s.sparkData!.map((p) => p.w).toList(),
                  strokeColor: catInkColor,
                  fillColor: catPaleColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── 스파크라인 (CustomPainter) ────────────────────────────
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
    required this.data,
    required this.strokeColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final maxW  = data.reduce(max);
    final minW  = data.reduce(min);
    final range = max(maxW - minW, 1.0);
    final W = size.width, H = size.height;

    List<Offset> pts = [];
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * W;
      final y = (H - 3) - ((data[i] - minW) / range) * (H - 8);
      pts.add(Offset(x, y));
    }

    // area fill
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) path.lineTo(p.dx, p.dy);
    path..lineTo(W, H)..lineTo(0, H)..close();
    canvas.drawPath(
      path,
      Paint()..color = fillColor.withValues(alpha: 0.55)..style = PaintingStyle.fill,
    );

    // line
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) linePath.lineTo(p.dx, p.dy);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = strokeColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.data != data || old.strokeColor != strokeColor || old.fillColor != fillColor;
}

// ── 월 캘린더 ───────────────────────────────────────────────
class _RecordCalendar extends StatelessWidget {
  final DateTime month;
  final int selectedDay;
  final Map<int, List<Map<String, String>>> dayLog;
  final ValueChanged<int> onSelect;

  const _RecordCalendar({
    required this.month,
    required this.selectedDay,
    required this.dayLog,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const weekKo = ['일', '월', '화', '수', '목', '금', '토'];
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    final daysInMonth  = DateTime(month.year, month.month + 1, 0).day;

    // 요일 헤더
    final header = Row(
      children: List.generate(7, (i) => Expanded(
        child: Text(
          weekKo[i],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: i == 0
                ? AppColors.petCoralInk
                : i == 6 ? AppColors.petSkyInk : AppColors.paleInk3,
          ),
        ),
      )),
    );

    // 날짜 셀
    final List<Widget?> cells = [
      ...List.generate(firstWeekday, (_) => null),
      ...List.generate(daysInMonth, (i) {
        final d    = i + 1;
        final sel  = d == selectedDay;
        final recs = dayLog[d] ?? [];
        final today = d == DateTime.now().day &&
            month.year == DateTime.now().year &&
            month.month == DateTime.now().month;

        return GestureDetector(
          onTap: () => onSelect(d),
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
                  children: recs.take(3).map((r) {
                    final cat = r['cat'] ?? 'memo';
                    final catCode = switch (cat) {
                      'weight' => 'WEIGHT', 'feed' => 'FEEDING',
                      'clean' => 'CLEANING', 'memo' => 'MEMO',
                      'mating' => 'MATING', 'laying' => 'LAYING', _ => 'MEMO',
                    };
                    return Container(
                      width: 4, height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: PalePalette.catInk(catCode),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }),
    ];

    final rows = <Widget>[header, const SizedBox(height: 4)];
    for (int r = 0; r < (cells.length / 7).ceil(); r++) {
      rows.add(Row(
        children: List.generate(7, (c) {
          final idx = r * 7 + c;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: idx < cells.length && cells[idx] != null
                  ? cells[idx]!
                  : const SizedBox(height: 36),
            ),
          );
        }),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

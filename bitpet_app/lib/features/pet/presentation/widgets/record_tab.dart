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

/// 최근 기록이 얼마나 지났는지 — 오늘 / 어제 / N일 전 / N주 전 / N개월 전 / N년 전
String _relativeDay(DateTime dt) {
  final today = DateTime.now();
  final d = DateTime(today.year, today.month, today.day)
      .difference(DateTime(dt.year, dt.month, dt.day))
      .inDays;
  if (d <= 0) return '오늘';
  if (d == 1) return '어제';
  if (d < 7) return '$d일 전';
  if (d < 30) return '${d ~/ 7}주 전';
  if (d < 365) return '${d ~/ 30}개월 전';
  return '${d ~/ 365}년 전';
}

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
  // 캘린더는 캘린더 탭으로 이전 — 기록 탭은 요약 + 오늘 기록만 표시
  DateTime get _today => DateTime.now();

  String get _todayStr =>
      '${_today.year}-${_today.month.toString().padLeft(2, '0')}-${_today.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final weightsAsync = ref.watch(weightListProvider(widget.petId));
    final dayAsync     = ref.watch(
        petDayTimelineProvider(PetDateParam(widget.petId, _todayStr)));
    final summaryAsync = ref.watch(petRecordSummaryProvider(widget.petId));

    const weekKo = ['일','월','화','수','목','금','토'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 요약 — 체중 히어로 + 나머지 카테고리 리스트 ─────
        _buildSummaryHero(context, summaryAsync, weightsAsync),
        const SizedBox(height: 22),

        // ── 오늘 기록 헤더 ────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: AppTextStyles.paleSectionTitle,
                children: [
                  TextSpan(text: '오늘 ${_today.month}.${_today.day} '),
                  TextSpan(
                    text: '(${weekKo[_today.weekday % 7]})',
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
        ),
        const SizedBox(height: 4),

        // ── 오늘 타임라인 리스트 ──────────────────────────────
        _buildDayList(dayAsync),
      ],
    );
  }

  // ── 요약 — Hero 레이아웃 (04 handoff: 체중 히어로 + 나머지 리스트) ──
  Widget _buildSummaryHero(
    BuildContext context,
    AsyncValue<List<TimelineItem>> summaryAsync,
    AsyncValue<List<WeightRecord>> weightsAsync,
  ) {
    final latestByCategory = <String, TimelineItem>{};
    summaryAsync.whenOrNull(data: (items) {
      for (final item in items) {
        latestByCategory.putIfAbsent(item.category, () => item);
      }
    });

    final weightPoints = weightsAsync.whenOrNull(data: (records) {
      final sorted = [...records]
        ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
      return sorted.map((r) => WeightPoint(r.weightG)).toList();
    });

    final isLoading = summaryAsync is AsyncLoading;
    final weightItem = latestByCategory['WEIGHT'];

    // ① 체중 히어로 카드
    final heroCard = GestureDetector(
      onTap: () => context.push('/pets/${widget.petId}/weight'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
          color: PalePalette.catPale('WEIGHT'),
        ),
        child: isLoading
            ? const SizedBox(height: 72,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_catMeta['WEIGHT']!.icon, size: 15,
                          color: PalePalette.catInk('WEIGHT')),
                      const SizedBox(width: 6),
                      Text('체중', style: AppTextStyles.paleCatLabel),
                      const Spacer(),
                      if (weightItem != null)
                        Text(
                          _relativeDay(weightItem.recordedAt),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: PalePalette.catInk('WEIGHT'),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right,
                          size: 18, color: PalePalette.catInk('WEIGHT')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        weightItem?.summary ?? '—',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: weightItem == null
                              ? AppColors.paleInk3
                              : AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      if (weightPoints != null && weightPoints.length >= 2)
                        SizedBox(
                          width: 140,
                          child: RecordSparkline(
                            data: weightPoints.map((p) => p.w).toList(),
                            strokeColor: PalePalette.catInk('WEIGHT'),
                            fillColor: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );

    // ② 나머지 5개 카테고리 — 단일 카드 안에 아이콘칩 리스트
    const restCats = ['FEEDING', 'CLEANING', 'MEMO', 'MATING', 'LAYING'];
    final restCard = Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        children: restCats.asMap().entries.map((entry) {
          final i   = entry.key;
          final cat = entry.value;
          final meta = _catMeta[cat]!;
          final item = latestByCategory[cat];
          final isEmpty = item == null;
          return GestureDetector(
            onTap: () {
              switch (cat) {
                case 'FEEDING':
                  context.push('/pets/${widget.petId}/feeding');
                case 'CLEANING':
                  context.push('/pets/${widget.petId}/records/cleaning');
                case 'MEMO':
                  context.push('/pets/${widget.petId}/records/memo');
                case 'MATING':
                  context.push('/pets/${widget.petId}/records/mating');
                case 'LAYING':
                  context.push('/pets/${widget.petId}/records/laying');
              }
            },
            child: Opacity(
              opacity: isEmpty ? 0.6 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: i < restCats.length - 1
                      ? const Border(
                          bottom: BorderSide(color: AppColors.paleLineSoft))
                      : null,
                ),
                child: Row(
                  children: [
                    // 아이콘칩
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: PalePalette.catPale(cat),
                      ),
                      child: Icon(meta.icon, size: 16,
                          color: PalePalette.catInk(cat)),
                    ),
                    const SizedBox(width: 12),
                    // 라벨 고정폭 — '메이팅' 3글자가 줄바꿈되지 않을 만큼 확보.
                    // 시스템 글자 크기를 키운 기기에서도 넘치지 않도록 배율을 반영한다.
                    SizedBox(
                      width: (48 * MediaQuery.textScalerOf(context).scale(1.0))
                          .clamp(48.0, 76.0),
                      child: Text(meta.label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.paleInk2,
                          )),
                    ),
                    const SizedBox(width: 8),
                    // 값
                    Expanded(
                      child: Text(
                        isEmpty ? '—' : item.summary,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isEmpty ? AppColors.paleInk3 : AppColors.primary,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 얼마나 지난 기록인지
                    if (!isEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        _relativeDay(item.recordedAt),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.paleInk3,
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        size: 18,
                        color: isEmpty
                            ? AppColors.paleInk3
                            : PalePalette.catInk(cat)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    return Column(
      children: [
        heroCard,
        const SizedBox(height: 12),
        restCard,
      ],
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
                    child: Text(item.displayText,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.paleInk2),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
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


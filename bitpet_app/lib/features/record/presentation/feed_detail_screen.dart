import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_input_styles.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/month_grid_calendar.dart';
import '../../../core/widgets/selected_day_card.dart';
import '../../../core/widgets/underline_tabs.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/feed_models.dart';
import '../providers/feed_provider.dart';
import '../providers/record_invalidation.dart';
import 'widgets/feed_items_editor.dart';
import '../../pet/providers/pet_provider.dart';
import '../../../core/theme/app_dimens.dart';

// ── 먹이 종류 → 색상 매핑 ──────────────────────────────────
const _foodColorKey = {
  '귀뚜라미': 'coral',
  '슈퍼웜':   'sage',
  '밀웜':     'butter',
  '버터웜':   'sky',
  '핑키마우스':'lilac',
};

const _foodDot = {
  'coral':  AppColors.petCoralInk,
  'sage':   AppColors.petSageInk,
  'butter': AppColors.petButterInk,
  'sky':    AppColors.petSkyInk,
  'lilac':  AppColors.petLilacInk,
};

const _foodChip = {
  'coral':  AppColors.petCoral,
  'sage':   AppColors.petSage,
  'butter': AppColors.petButter,
  'sky':    AppColors.petSky,
  'lilac':  AppColors.petLilac,
};

Color _dotColor(String food) =>
    _foodDot[_foodColorKey[food] ?? 'sage'] ?? AppColors.petSageInk;
Color _chipColor(String food) =>
    _foodChip[_foodColorKey[food] ?? 'sage'] ?? AppColors.petSage;

const _weekKo = ['일','월','화','수','목','금','토'];

// ── 메인 화면 ───────────────────────────────────────────────
class FeedDetailScreen extends ConsumerStatefulWidget {
  final int petId;
  const FeedDetailScreen({super.key, required this.petId});

  @override
  ConsumerState<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends ConsumerState<FeedDetailScreen> {
  int _tabIndex = 0; // 0: 캘린더, 1: 리스트
  FeedEditorState? _editor;

  void _openAdd(String? date) {
    final sorted = ref
        .read(sortedFeedSessionsProvider(widget.petId))
        .whenOrNull(data: (l) => l);
    final defaultDate = date ??
        (sorted != null && sorted.isNotEmpty
            ? _shiftDate(sorted.first.date, 1)
            : _todayIso());
    setState(() {
      _editor = FeedEditorState(
        isEdit: false, editId: null,
        date: defaultDate, time: '21:00',
        items: [], memo: '',
      );
    });
  }

  void _openEdit(FeedSession s) {
    setState(() {
      _editor = FeedEditorState(
        isEdit: true, editId: s.id,
        date: s.date, time: s.time,
        items: List.from(s.items), memo: s.memo,
      );
    });
  }

  Future<void> _save() async {
    final e = _editor;
    if (e == null) return;
    // 새로 추가할 때는 먹이가 있어야 한다. 수정은 비어도 보낸다 —
    // 먹이 없이 완료한 루틴 기록의 시각·메모만 고치는 경우가 있다.
    if (!e.isEdit && e.items.isEmpty) return;
    final notifier = ref.read(feedSessionsProvider(widget.petId).notifier);
    try {
      if (e.isEdit && e.editId != null) {
        await notifier.update(FeedSession(
          id: e.editId!, date: e.date, time: e.time,
          items: e.items, memo: e.memo,
        ));
      } else {
        await notifier.add(FeedSession(
          id: '', date: e.date, time: e.time,
          items: e.items, memo: e.memo,
        ));
      }
    } catch (err) {
      if (mounted) showToast(context, '저장 실패: $err', type: ToastType.error);
      return;
    }
    // 목록은 notifier 가 이미 반영 — 캘린더 탭·기록 탭 요약·홈만 갱신
    invalidatePetRecords(ref, widget.petId, keepFeedSessions: true);
    if (mounted) {
      setState(() => _editor = null);
      showToast(context,
          e.isEdit ? '수정되었습니다.' : '기록이 추가되었습니다.',
          type: ToastType.success);
    }
  }

  Future<void> _delete(String id) async {
    final ok = await ConfirmModal.show(
      context,
      title: '기록 삭제',
      message: '이 급여 기록을 삭제할까요?\n삭제하면 복구할 수 없습니다.',
      confirmLabel: '삭제',
      isDangerous: true,
    );
    if (!ok) return;
    try {
      await ref.read(feedSessionsProvider(widget.petId).notifier).delete(id);
      invalidatePetRecords(ref, widget.petId, keepFeedSessions: true);
      if (mounted) {
        setState(() => _editor = null);
        showToast(context, '기록이 삭제되었습니다.', type: ToastType.info);
      }
    } catch (e) {
      if (mounted) showToast(context, '삭제 실패: $e', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final petAsync     = ref.watch(petDetailProvider(widget.petId));
    final sessionsAsync = ref.watch(sortedFeedSessionsProvider(widget.petId));
    final petName = petAsync.whenOrNull(data: (p) => p.name) ?? '';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          Column(
            children: [
              // TopBar
              SafeArea(
                bottom: false,
                child: _TopBar(
                  onBack:  () => context.pop(),
                  petName: petName,
                  onAdd:   () => _openAdd(null),
                ),
              ),
              // 보고 있는 페이지는 밑줄 — 알약 세그먼트는 '설정'의 모양이다
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenH),
                child: AppUnderlineTabs(
                  labels: const ['캘린더', '리스트'],
                  index: _tabIndex,
                  onChanged: (i) => setState(() => _tabIndex = i),
                ),
              ),
              // 본문
              Expanded(
                child: sessionsAsync.when(
                  loading: () => const SkeletonCardList(),
                  error:   (e, _) => Center(child: Text(e.toString())),
                  data:    (sessions) => _tabIndex == 0
                      ? _CalendarView(
                          sessions: sessions,
                          onEdit:   _openEdit,
                          onAdd:    _openAdd,
                        )
                      : _ListView(
                          sessions: sessions,
                          onEdit:   _openEdit,
                        ),
                ),
              ),
            ],
          ),

          // 편집 시트 오버레이
          if (_editor != null)
            FeedEditorSheet(
              petId:     widget.petId,
              editor:    _editor!,
              onChanged: (e) => setState(() => _editor = e),
              onSave:    _save,
              onDelete:  _delete,
              onClose:   () => setState(() => _editor = null),
            ),
        ],
      ),
    );
  }

  static String _todayIso() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  static String _shiftDate(String iso, int days) {
    final parts = iso.split('-').map(int.parse).toList();
    final dt = DateTime(parts[0], parts[1], parts[2] + days);
    return '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
  }
}

// ── TopBar ──────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final String petName;
  final VoidCallback onAdd;

  const _TopBar({required this.onBack, required this.petName, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
          Column(children: [
            const Text('급여 기록',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.primary, letterSpacing: -0.2)),
            if (petName.isNotEmpty)
              Text(petName.toUpperCase(), style: AppTextStyles.monoXs),
          ]),
          const Spacer(),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              height: 36, padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.brMd,
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('기록',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.paleBg)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ── 세션 카드 (캘린더·리스트 공용) ──────────────────────────
//
// `bare` = 테두리·배경 없는 **맨 몸** 행. 카드 안에 들어갈 때 쓴다
// (카드 안의 카드는 깊이를 두 번 세는 셈이라 금지).
class SessionCard extends StatelessWidget {
  final FeedSession session;
  final VoidCallback onEdit;
  final bool showDate;
  final bool bare;

  /// 카드 머리말이 이미 날짜를 말하는 자리 — 시각만 남긴다
  final bool timeOnly;

  const SessionCard({
    super.key,
    required this.session,
    required this.onEdit,
    this.showDate = true,
    this.bare = false,
    this.timeOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 컬럼 — 일/시각을 **한 줄**로 둔다.
        // 세로로 쌓으면 글자 배율을 키운 기기에서 카드가 그만큼 길어지고,
        // 목록 전체에 빈 공간이 생긴다. 좁아지면 줄바꿈 대신 함께 줄어든다.
        // bare 일 때는 날짜를 카드 머리말이 이미 말해주므로 시각만 남긴다.
        if (showDate)
          SizedBox(
            width: timeOnly ? 46 : 76,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: timeOnly
                    ? Text(session.time,
                        maxLines: 1, softWrap: false,
                        style: AppTextStyles.monoSm)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(session.date.substring(8), // dd
                              maxLines: 1, softWrap: false,
                              style: AppTextStyles.monoBody),
                          const SizedBox(width: 6),
                          Text(session.time,
                              maxLines: 1, softWrap: false,
                              style: AppTextStyles.monoXxs),
                        ],
                      ),
              ),
            ),
          ),
        if (showDate) const SizedBox(width: 10),
        // 아이템 목록
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...session.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 7, height: 7,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        color: item.isRefused
                            ? Colors.transparent
                            : _dotColor(item.food),
                        shape: BoxShape.circle,
                        border: item.isRefused
                            ? Border.all(color: AppColors.ink3, width: 1.2)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.detail,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: item.isRefused
                                  ? AppColors.ink2
                                  : AppColors.ink)),
                    ),
                  ],
                ),
              )),
              // 먹이를 아직 안 적은 기록 — 무엇을 줬는지는 몰라도
              // '챙겼다'는 사실은 남는다. 카드가 비어 보이지 않게 한 줄 띄운다.
              if (session.isFoodless)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 7, height: 7,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: const BoxDecoration(
                        color: AppColors.ink3,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(session.foodlessLabel,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: AppColors.ink2)),
                    ),
                  ],
                ),
              if (session.memo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(session.memo,
                      style: AppTextStyles.caption),
                ),
            ],
          ),
        ),
        // 루틴으로 생긴 기록도 그냥 기록이다 — 전부 수정할 수 있다.
        GestureDetector(
          onTap: onEdit,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: bare ? Colors.transparent : AppColors.bgAlt,
              border: bare
                  ? null
                  : Border.all(color: AppColors.line),
              borderRadius: AppRadius.brMd,
            ),
            child: const Icon(Icons.edit_outlined,
                size: 16, color: AppColors.ink3),
          ),
        ),
      ],
    );

    if (bare) return body;

    return Container(
      decoration: AppDecor.card,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: body,
    );
  }
}

// ── 캘린더 뷰 ───────────────────────────────────────────────
class _CalendarView extends StatefulWidget {
  final List<FeedSession> sessions;
  final ValueChanged<FeedSession> onEdit;
  final ValueChanged<String?> onAdd;

  const _CalendarView({
    required this.sessions, required this.onEdit, required this.onAdd});

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  // 진입 시엔 항상 **이번 달 / 오늘**. 기록이 있는 마지막 달로 점프하지 않는다
  // — 대부분의 진입 목적이 "오늘 뭐 줬더라 / 오늘 기록 남기기" 이기 때문.
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late String _selDate = todayIso();

  List<FeedSession> get _monthSessions =>
      widget.sessions.where((s) => s.date.startsWith(_ymStr)).toList();

  Map<String, List<FeedSession>> get _byDate {
    final map = <String, List<FeedSession>>{};
    for (final s in _monthSessions) {
      map.putIfAbsent(s.date, () => []).add(s);
    }
    return map;
  }

  String get _ymStr =>
      '${_month.year}-${_month.month.toString().padLeft(2,'0')}';

  /// 요약은 **면 없는 캡션 한 줄**이다 — 개체 상세의 히어로 카드와 같은 모양을
  /// 하위 화면에서 또 쓰면 어느 화면인지가 흐려진다.
  List<MonthSummaryItem> get _summary {
    final sessions = _monthSessions;
    final days = sessions.map((s) => s.date).toSet().toList()..sort();
    final refused = sessions
        .where((s) => s.items.any((i) => i.isRefused))
        .length;

    String gap = '—';
    if (days.length >= 2) {
      final first = DateTime.parse(days.first);
      final last = DateTime.parse(days.last);
      final avg = last.difference(first).inDays / (days.length - 1);
      gap = '${avg.toStringAsFixed(avg >= 10 ? 0 : 1)}일';
    }

    return [
      MonthSummaryItem('급여', '${sessions.length}회'),
      MonthSummaryItem('평균 간격', gap),
      MonthSummaryItem('거식', '$refused회'),
    ];
  }

  /// 셀 안에 들어갈 급여 요약. 기록이 없으면 null.
  Widget? _cellContent(Map<String, List<FeedSession>> byDate, String date) {
    final recs = byDate[date];
    if (recs == null || recs.isEmpty) return null;
    final items = recs.expand((s) => s.items).toList();
    // 먹이를 안 적은 기록은 항목이 0개다. 그래도 **챙긴 날**이므로
    // 빈 셀로 두지 않는다 — 예전엔 여기서 null 을 돌려줘 캘린더에서 통째로 사라졌다.
    final foodless = recs.where((s) => s.isFoodless).toList();
    if (items.isEmpty && foodless.isEmpty) return null;
    const maxLines = 3;
    final lines = <Widget>[
      for (final it in items)
        CalendarCellLine(
          dotColor: it.isRefused ? AppColors.ink3 : _dotColor(it.food),
          label: it.isRefused
              ? '거식'
              : (it.amt > 1 ? '${it.food} ${it.amt}' : it.food),
          muted: it.isRefused,
          hollow: it.isRefused,
        ),
      for (final s in foodless)
        CalendarCellLine(
          dotColor: AppColors.ink3,
          label: s.foodlessLabel,
          muted: true,
        ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...lines.take(maxLines),
        if (lines.length > maxLines) CalendarCellMore(lines.length - maxLines),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final byDate = _byDate;
    final selected = widget.sessions.where((s) => s.date == _selDate).toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    // 먹이 범례는 두지 않는다 — 셀에 먹이 이름이 그대로 찍히고, 고정 5종만 나열돼
    // 직접입력·기타 먹이는 어차피 범례에 없었다.
    //
    // 고른 날 기록은 시트가 아니라 캘린더 **바로 아래**에 펼친다. 칸을 눌러
    // 시트를 열고 닫는 두 번의 조작이 그 날 내용을 보는 유일한 길이면 안 된다.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonthGridCalendar(
            month: _month,
            selectedDate: _selDate,
            summary: _summary,
            onMonthChanged: (m) => setState(() => _month = m),
            onDayTap: (ds) => setState(() => _selDate = ds),
            cellBuilder: (ds) => _cellContent(byDate, ds),
            onToday: () => setState(() {
              final now = DateTime.now();
              _month = DateTime(now.year, now.month);
              _selDate = todayIso();
            }),
          ),
          const SizedBox(height: AppSpacing.cardGap),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
            child: SelectedDayCard(
              date: _selDate,
              countLabel: '${selected.length}회',
              onAdd: () => widget.onAdd(_selDate),
              emptyLabel: '이 날의 급여 기록이 없어요',
              rows: [
                for (final s in selected)
                  SessionCard(
                    session: s,
                    onEdit: () => widget.onEdit(s),
                    bare: true,
                    timeOnly: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 리스트 뷰 (무한 스크롤) ──────────────────────────────────
class _ListView extends StatefulWidget {
  final List<FeedSession> sessions;
  final ValueChanged<FeedSession> onEdit;

  const _ListView({required this.sessions, required this.onEdit});

  @override
  State<_ListView> createState() => _ListViewState();
}

class _ListViewState extends State<_ListView> {
  static const _page = 8;
  int _count = _page;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 120) {
      setState(() => _count =
          (_count + _page).clamp(0, widget.sessions.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.sessions.take(_count).toList();

    // 월 단위로 묶는다. 행마다 카드를 주면 목록이 카드 더미가 되고 **덩어리가
    // 안 보인다** — 한 장 안에서 얇은 선으로만 나눈다 (선은 칸막이지 테두리가 아니다).
    final groups = <String, List<FeedSession>>{};
    for (final s in visible) {
      groups.putIfAbsent(s.date.substring(0, 7), () => []).add(s);
    }
    final monthKeys = groups.keys.toList();

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, 110),
      itemCount: monthKeys.length + 1, // 머리말 1
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('전체 급여 기록', style: AppTextStyles.subheading),
                Text('${widget.sessions.length}회',
                    style: AppTextStyles.monoSm),
              ],
            ),
          );
        }
        final mk = monthKeys[i - 1];
        final rows = groups[mk]!;
        final ym = mk.split('-');
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 2),
                child: Row(
                  children: [
                    Text('${ym[0]}. ${ym[1]}',
                        style: AppTextStyles.mono(14, FontWeight.w700)),
                    const SizedBox(width: AppSpacing.sm),
                    Text('${rows.length}회', style: AppTextStyles.monoXs),
                  ],
                ),
              ),
              Container(
                decoration: AppDecor.cardRaised,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var k = 0; k < rows.length; k++)
                      Container(
                        decoration: k == 0
                            ? null
                            : const BoxDecoration(
                                border: Border(
                                    top: BorderSide(color: AppColors.bgAlt)),
                              ),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: SessionCard(
                          session: rows[k],
                          onEdit: () => widget.onEdit(rows[k]),
                          bare: true,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 편집 바텀시트 ────────────────────────────────────────────
class FeedEditorSheet extends StatefulWidget {
  /// 최근 급여 칩은 개체별이라 시트도 어느 개체를 고치는 중인지 알아야 한다.
  final int petId;
  final FeedEditorState editor;
  final ValueChanged<FeedEditorState> onChanged;
  final VoidCallback onSave;
  final ValueChanged<String> onDelete;
  final VoidCallback onClose;

  const FeedEditorSheet({
    super.key,
    required this.petId,
    required this.editor,
    required this.onChanged,
    required this.onSave,
    required this.onDelete,
    required this.onClose,
  });

  @override
  State<FeedEditorSheet> createState() => _FeedEditorSheetState();
}

class _FeedEditorSheetState extends State<FeedEditorSheet> {
  final _memoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _memoCtrl.text = widget.editor.memo;
  }

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  void _shiftDate(int days) {
    final parts = widget.editor.date.split('-').map(int.parse).toList();
    final dt = DateTime(parts[0], parts[1], parts[2] + days);
    widget.onChanged(widget.editor.copyWith(
      date: '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final e   = widget.editor;
    final dt  = DateTime.parse(e.date);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.black.withValues(alpha: 0.45)),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            top: 70,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1, end: 0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) =>
                  FractionalTranslation(translation: Offset(0, t), child: child),
              child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
              decoration: const BoxDecoration(
                color: AppColors.paleBg,
                border: Border(top: BorderSide(color: AppColors.paleLine)),
              ),
              child: Column(
                children: [
                  // drag handle
                  Container(
                    width: 44, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.paleLine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 헤더 + 날짜 스테퍼
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              e.isEdit ? '급여 기록 수정' : '급여 기록 추가',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700,
                                  color: AppColors.primary, letterSpacing: -0.4),
                            ),
                            GestureDetector(
                              onTap: widget.onClose,
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  border: Border.all(color: AppColors.paleLine),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: AppColors.paleInk2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 날짜 스테퍼
                        Row(
                          children: [
                            AppNavButton(onTap: () => _shiftDate(-1)),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  border: Border.all(color: AppColors.paleLine),
                                  borderRadius: AppRadius.brMd,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      e.date.replaceAll('-', '.'),
                                      style: AppTextStyles.mono(14, FontWeight.w700),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${_weekKo[dt.weekday % 7]})',
                                      style: TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w600,
                                          color: AppColors.paleInk2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AppNavButton(forward: true, onTap: () => _shiftDate(1)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 스크롤 본문
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          20, 4, 20,
                          MediaQuery.of(context).viewInsets.bottom + 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 공용 리치 컴포저 (FAB·루틴 완료와 동일 폼)
                          FeedItemsEditor(
                            items: e.items.map((i) => i.toForm()).toList(),
                            petId: widget.petId,
                            bandColor: _chipColor('귀뚜라미'),
                            onChanged: (forms) => widget.onChanged(
                              e.copyWith(
                                items: forms.map(FeedItem.fromForm).toList(),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          // 메모
                          Row(
                            children: [
                              const Text('메모',
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                              const SizedBox(width: 8),
                              Text('OPTIONAL',
                                  style: AppTextStyles.monoXxs),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _memoCtrl,
                            onChanged: (v) => widget.onChanged(
                                e.copyWith(memo: v)),
                            maxLines: 2,
                            decoration: AppInputStyles.textarea(
                              hintText: '예: 1마리 남김 · 식욕 좋음 · 더스팅',
                            ),
                          ),

                          // 삭제 버튼 (수정 모드)
                          if (e.isEdit && e.editId != null) ...[
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => widget.onDelete(e.editId!),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.errorLine),
                                  borderRadius: AppRadius.brMd,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline,
                                        size: 16, color: AppColors.error),
                                    SizedBox(width: 8),
                                    Text('이 기록 삭제',
                                        style: TextStyle(
                                            fontSize: 13, fontWeight: FontWeight.w700,
                                            color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // 푸터
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        20, 12, 20,
                        MediaQuery.of(context).padding.bottom + 12),
                    decoration: const BoxDecoration(
                      color: AppColors.paleBg,
                      border: Border(
                          top: BorderSide(color: AppColors.paleLineSoft)),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              border: Border.all(color: AppColors.paleLine),
                              borderRadius: AppRadius.brLg,
                            ),
                            child: const Text('취소',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: e.items.isEmpty ? null : widget.onSave,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: e.items.isEmpty
                                    ? AppColors.paleLine
                                    : AppColors.primary,
                                borderRadius: AppRadius.brLg,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check,
                                      size: 16,
                                      color: e.items.isEmpty
                                          ? AppColors.paleInk3
                                          : AppColors.paleBg),
                                  const SizedBox(width: 8),
                                  Text(
                                    e.isEdit ? '수정 완료' : '저장',
                                    style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w700,
                                        color: e.items.isEmpty
                                            ? AppColors.paleInk3
                                            : AppColors.paleBg),
                                  ),
                                ],
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
            ),
            ),
          ),
        ],
      ),
    );
  }
}

